//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Dec 05  Brian Frank  Creation
//
package fan.sys;

import java.io.*;
import java.lang.reflect.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map.Entry;
import fanx.fcode.*;
import fanx.emit.*;
import fanx.serial.*;
import fanx.util.*;

/**
 * ClassType models a static type definition for an Obj class:
 *
 *  1) Hollow: in this state we know basic identity of the type, and
 *     it's inheritance hierarchy.  A type is setup to be hollow during
 *     Pod.load().
 *  2) Reflected: in this state we read all the slot definitions from the
 *     fcode to populate the slot tables used to for reflection.  At this
 *     point clients can discover the signatures of the Type.
 *  3) Emitted: the final state of loading a Type is to emit to a Java
 *     class called "fan.{pod}.{type}".  Once emitted we can instantiate
 *     the type or call it's methods.
 *  4) Finished: once we have reflected the slots into memory and emitted
 *     the Java class, the last stage is to bind the all the java.lang.reflect
 *     representations to the Slots for dynamic dispatch.  We delay this
 *     until needed by Method or Field for a reflection invocation
 */
public class ClassType
  extends Type
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ClassType(Pod pod, FType ftype)
  {
    this.pod      = pod;
    this.ftype    = ftype;
    this.name     = pod.fpod.typeRef(ftype.self).typeName;
    this.qname    = pod.name + "::" + name;
    this.nullable = new NullableType(this);
    this.flags    = ftype.flags;
    if (Debug) System.out.println("-- init:   " + qname);
  }

  // parameterized type constructor
  public ClassType(Pod pod, String name, int flags, Facets facets)
  {
    this.pod      = pod;
    this.name     = name;
    this.qname    = pod.name + "::" + name;
    this.nullable = new NullableType(this);
    this.flags    = flags;
  }

//////////////////////////////////////////////////////////////////////////
// Naming
//////////////////////////////////////////////////////////////////////////

  public final Pod pod()   { return pod; }
  public final String name()  { return name; }
  public final String qname() { return qname; }
  public String signature()   { return qname; }

  public final Type toNullable() { return nullable; }

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  int flags() { return flags; }

  public Object trap(String name, List args)
  {
    // private undocumented access
    if (name.equals("lineNumber")) { reflect(); return Long.valueOf(lineNum); }
    if (name.equals("sourceFile")) { reflect(); return sourceFile; }
    return super.trap(name, args);
  }

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

  public final List fields()  { return reflect().fields.ro(); }
  public final List methods() { return reflect().methods.ro(); }
  public final List slots()   { return reflect().slots.ro(); }

  public final Slot slot(String name, boolean checked)
  {
    Slot slot = (Slot)reflect().slotsByName.get(name);
    if (slot != null) return slot;
    if (checked) throw UnknownSlotErr.make(this.qname + "." + name);
    return null;
  }

  public final Object make(List args)
  {
    return super.make(args);
  }

//////////////////////////////////////////////////////////////////////////
// Inheritance
//////////////////////////////////////////////////////////////////////////

  public Type base() { return base; }

  public List mixins() { return mixins; }

  public List inheritance()
  {
    if (inheritance == null) inheritance = inheritance(this);
    return inheritance;
  }

  static List inheritance(Type self)
  {
    HashMap map = new HashMap();
    List acc = new List(Sys.TypeType);

    // handle Void as a special case
    if (self == Sys.VoidType)
    {
      acc.add(self);
      return acc.trim().ro();
    }

    // add myself
    map.put(self.qname(), self);
    acc.add(self);

    // add my direct inheritance inheritance
    addInheritance(self.base(), acc, map);
    List mixins = self.mixins();
    for (int i=0; i<mixins.sz(); ++i)
      addInheritance((Type)mixins.get(i), acc, map);

    return acc.trim().ro();
  }

  private static void addInheritance(Type t, List acc, HashMap map)
  {
    if (t == null) return;
    List ti = t.inheritance();
    for (int i=0; i<ti.sz(); ++i)
    {
      Type x = (Type)ti.get(i);
      if (map.get(x.qname()) == null)
      {
        map.put(x.qname(), x);
        acc.add(x);
      }
    }
  }

  public boolean is(Type type)
  {
    // we don't take nullable into account for fits
    if (type instanceof NullableType)
      type = ((NullableType)type).root;

    if (type == this || (type == Sys.ObjType && this != Sys.VoidType))
      return true;
    List inheritance = inheritance();
    for (int i=0; i<inheritance.sz(); ++i)
      if (inheritance.get(i) == type) return true;
    return false;
  }

  /**
   * Given a list of objects, compute the most specific type which they all
   * share,or at worst return sys::Obj.  This method does not take into
   * account interfaces, only extends class inheritance.
   */
  public static Type common(Object[] objs, int n)
  {
    if (objs.length == 0) return Sys.ObjType;
    Type best = typeof(objs[0]);
    for (int i=1; i<n; ++i)
    {
      Object obj = objs[i];
      if (obj == null) continue;
      Type t = typeof(obj);
      while (!t.is(best))
      {
        best = best.base();
        if (best == null) return Sys.ObjType;
      }
    }
    return best;
  }

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  public List facets()
  {
    if (inheritedFacets == null) loadFacets();
    return inheritedFacets .list();
  }

  public Facet facet(Type t, boolean c)
  {
    if (inheritedFacets == null) loadFacets();
    return inheritedFacets.get(t, c);
  }

  private void loadFacets()
  {
    reflect();
    Facets f = myFacets.dup();
    List inheritance = inheritance();
    for (int i=0; i<inheritance.sz(); ++i)
    {
      Object x = inheritance.get(i);
      if (x instanceof ClassType)
      {
        ClassType superType = (ClassType)x;
        f.inherit(superType.reflect().myFacets);
      }
    }
    inheritedFacets = f;
  }

//////////////////////////////////////////////////////////////////////////
// Documentation
//////////////////////////////////////////////////////////////////////////

  public String doc()
  {
    if (!docLoaded)
    {
      try
      {
        InputStream in = pod.fpod.store.read("doc/" + name + ".apidoc");
        if (in != null) { try { FDoc.read(in, this); } finally { in.close(); } }
      }
      catch (Exception e) { e.printStackTrace(); }
      docLoaded = true;
    }
    return doc;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public void encode(ObjEncoder out)
  {
    out.w(qname).w("#");
  }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  protected final synchronized ClassType reflect()
  {
    // short circuit if already reflected
    if (slotsByName != null) return this;

    if (Debug) System.out.println("-- reflect: " + qname + " " + slotsByName);

    // do it
    doReflect();

    // return this
    return this;
  }

  protected void doReflect()
  {
    // if the ftype is non-null, that means it was passed in non-hollow
    // ftype (in-memory compile), otherwise we need to read it from the pod
    if (ftype.hollow)
    {
      try
      {
        ftype.read();
      }
      catch (IOException e)
      {
        e.printStackTrace();
        throw IOErr.make("Cannot read " + qname + " from pod", e);
      }
    }

    // these are working accumulators used to build the
    // data structures of my defined and inherited slots
    List slots  = new List(Sys.SlotType, 64);
    HashMap nameToSlot  = new HashMap();   // String -> Slot
    HashMap nameToIndex = new HashMap();   // String -> Int

    // merge in base class and mixin classes
    for (int i=0; i<mixins().sz(); ++i) merge((Type)mixins.get(i), slots, nameToSlot, nameToIndex);
    merge(base, slots, nameToSlot, nameToIndex);

    // merge in all my slots
    FPod fpod   = this.pod.fpod;
    FType ftype = this.ftype;
    for (int i=0; i<ftype.fields.length; ++i)
    {
      Field f = map(fpod, ftype.fields[i]);
      merge(f, slots, nameToSlot, nameToIndex);
    }
    for (int i=0; i<ftype.methods.length; ++i)
    {
      Method m = map(fpod, ftype.methods[i]);
      merge(m, slots, nameToSlot, nameToIndex);
    }

    // break out into fields and methods
    List fields  = new List(Sys.FieldType,  slots.sz());
    List methods = new List(Sys.MethodType, slots.sz());
    for (int i=0; i<slots.sz(); ++i)
    {
      Slot slot = (Slot)slots.get(i);
      if (slot instanceof Field)
        fields.add(slot);
      else
        methods.add(slot);
    }
    this.slots       = slots.trim();
    this.fields      = fields.trim();
    this.methods     = methods.trim();
    this.slotsByName = nameToSlot;
    this.myFacets    = Facets.mapFacets(pod, ftype.attrs.facets);

    this.lineNum    = ftype.attrs.lineNum;
    this.sourceFile = ftype.attrs.sourceFile;
  }

  /**
   * Merge the inherit's slots into my slot maps.
   *  slots:       Slot[] by order
   *  nameToSlot:  String name -> Slot
   *  nameToIndex: String name -> Long index of slots
   */
  private void merge(Type inheritedType, List slots, HashMap nameToSlot, HashMap nameToIndex)
  {
    if (inheritedType == null) return;
    List inheritedSlots = inheritedType.reflect().slots();
     for (int i=0; i<inheritedSlots.sz(); ++i)
      merge((Slot)inheritedSlots.get(i), slots, nameToSlot, nameToIndex);
  }

  /**
   * Merge the inherited slot into my slot maps.  Assume this slot
   * trumps any previous definition (because we process inheritance
   * and my slots in the right order)
   *  slots:       Slot[] by order
   *  nameToSlot:  String name -> Slot
   *  nameToIndex: String name -> Long index of slots
   */
  private void merge(Slot slot, List slots, HashMap nameToSlot, HashMap nameToIndex)
  {
    // skip constructors which aren't mine
    if (slot.isCtor() && slot.parent != this) return;

    String name = slot.name;
    Long dup = (Long)nameToIndex.get(name);
    if (dup != null)
    {
      // if the slot is inherited from Obj, then we can
      // safely ignore it as an override - the dup is most
      // likely already the same Object method inherited from
      // a mixin; but the dup might actually be a more specific
      // override in which case we definitely don't want to
      // override with the sys::Object version
      if (slot.parent() == Sys.ObjType)
        return;

      // if given the choice between two *inherited* slots where
      // one is concrete and abstract, then choose the concrete one
      Slot dupSlot = (Slot)slots.get(dup);
      if (slot.parent() != this && slot.isAbstract() && !dupSlot.isAbstract())
        return;

      // check if this is a Getter or Setter, in which case the Field
      // trumps and we need to cache the method on the Field
      // Note: this works because we assume the compiler always generates
      // the field before the getter and setter in fcode
      if ((slot.flags & (FConst.Getter|FConst.Setter)) != 0)
      {
        Field field = (Field)slots.get(dup);
        if ((slot.flags & FConst.Getter) != 0)
          field.getter = (Method)slot;
        else
          field.setter = (Method)slot;
        return;
      }

      nameToSlot.put(name, slot);
      slots.set(dup, slot);
    }
    else
    {
      nameToSlot.put(name, slot);
      slots.add(slot);
      nameToIndex.put(name, Long.valueOf(slots.sz()-1));
    }
  }

  /**
   * Map fcode field to a sys::Field.
   */
  private Field map(FPod fpod, FField f)
  {
    String name = f.name.intern();
    Type fieldType = pod.type(f.type);
    Facets facets = Facets.mapFacets(pod, f.attrs.facets);
    return new Field(this, name, f.flags, facets, f.attrs.lineNum, fieldType);
  }

  /**
   * Map fcode method to a sys::Method.
   */
  private Method map(FPod fpod, FMethod m)
  {
    String name = m.name.intern();
    Type returns = pod.type(m.ret);
    Type inheritedReturns = pod.type(m.inheritedRet);
    List params = new List(Sys.ParamType, m.paramCount);
    for (int j=0; j<m.paramCount; ++j)
    {
      FMethodVar p = m.vars[j];
      int pflags = (p.def == null) ? 0 : Param.HAS_DEFAULT;
      params.add(new Param(p.name.intern(), pod.type(p.type), pflags));
    }
    Facets facets = Facets.mapFacets(pod, m.attrs.facets);
    return new Method(this, name, m.flags, facets, m.attrs.lineNum, returns, inheritedReturns, params);
  }

//////////////////////////////////////////////////////////////////////////
// Emit
//////////////////////////////////////////////////////////////////////////

  public Class toClass() { return emit(); }

  /**
   * Emit to a Java class.
   */
  public synchronized Class emit()
  {
    if (cls == null)
    {
      if (Debug) System.out.println("-- emit:   " + qname);

      // make sure we have reflected to setup slots
      reflect();

      // if sys class, just load it by name
      String podName = pod.name;
      if (podName.equals("sys"))
      {
        try
        {
          this.javaRepr = FanUtil.isJavaRepresentation(this);
          this.cls = Class.forName(FanUtil.toJavaImplClassName(podName, name));
        }
        catch (Exception e)
        {
          e.printStackTrace();
          throw Err.make("Cannot load precompiled class: " + qname, e);
        }
      }

      // otherwise we need to emit it
      else
      {
        try
        {
          Class[] classes = Env.cur().loadTypeClasses(this);
          this.cls = classes[0];
          if (classes.length > 1)
            this.auxCls = classes[1];
        }
        catch (Exception e)
        {
          e.printStackTrace();
          throw Err.make("Cannot emit: " + qname, e);
        }
      }

      // we are done with our ftype now, gc it
      this.ftype = null;
    }
    return cls;
  }

  /**
   * This is called to map a class if it has been precompiled
   */
  public void precompiled(Class cls)
  {
    this.cls = cls;
    try
    {
      if (isMixin())
        this.auxCls = cls.getClassLoader().loadClass(cls.getName()+"$");
    }
    catch (Exception e)
    {
      System.out.println("ERROR: Invalid precompiled class missing aux: " + qname);
      e.printStackTrace();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Finish
//////////////////////////////////////////////////////////////////////////

  /**
   * Finish ensures we have reflected and emitted, then does
   * the final binding between slots and Java members
   */
  public synchronized void finish()
  {
    if (finished) return;
    try
    {
      // ensure reflected and emitted
      reflect();
      emit();
      finished = true;

      // map Java members to my slots for reflection; if
      // mixin then we do this for both the interface and
      // the static methods only of the implementation class
      finishSlots(cls, false);
      if (isMixin()) finishSlots(auxCls, true);

/*
System.out.println("---- Finish " + qname() + " cls=" + cls);
try
{
for (int i=0; i<methods().sz(); ++i)
{
  Method m = (Method)methods().get(i);
  System.out.println("  " + m.name());
  for (int j=0; m.reflect != null && j<m.reflect.length; ++j)
    System.out.println("    [" + j + "] " + m.reflect[j]);
}
}
catch (Exception e) { e.printStackTrace(); }
*/

    }
    catch (Throwable e)
    {
      e.printStackTrace();
      throw Err.make("Cannot emitFinish: " + qname + "." + finishing, e);
    }
    finally
    {
      finishing = null;
    }
  }

  /**
   * Map the Java members of the specified
   * class to my slots for reflection.
   */
  private void finishSlots(Class cls, boolean staticOnly)
  {
    // map the class's fields to my slots
    java.lang.reflect.Field[] fields = cls.getDeclaredFields();
    for (int i=0; i<fields.length; ++i)
      finishField(fields[i]);

    // map the class's methods to my slots
    java.lang.reflect.Method[] methods = cls.getDeclaredMethods();
    for (int i=0; i<methods.length; ++i)
      finishMethod(methods[i], staticOnly);
  }

  private void finishField(java.lang.reflect.Field f)
  {
    this.finishing = f.getName();
    Slot slot = slot(f.getName(), false);
    if (slot == null || !(slot instanceof Field)) return;
    Field field = (Field)slot;
    if (field.reflect != null) return; // first one seems to give us most specific binding
    f.setAccessible(true);
    field.reflect = f;
  }

  private void finishMethod(java.lang.reflect.Method m, boolean staticOnly)
  {
    if (pod == Sys.sysPod && !Modifier.isPublic(m.getModifiers())) return;
    this.finishing = m.getName();
    String name = m.getName();
    Slot slot = slot(name, false);
    if (slot == null) return;
    if (slot.parent() != this) return;
    if (staticOnly && !slot.isStatic()) return;
    m.setAccessible(true);

    if (slot instanceof Method)
    {
      Method method = (Method)slot;

      // alloc java.lang.reflect.Method[] array big enough
      // to handle all the versions with default parameters
      if (method.reflect == null)
      {
        int n = 1;
        for (int j=method.params().sz()-1; j>=0; --j)
        {
          if (((Param)method.params().get(j)).hasDefault()) n++;
          else break;
        }
        method.reflect = new java.lang.reflect.Method[n];
      }

      // get parameters, if sys we need to skip the
      // methods that use non-Fantom signatures
      Class[] params = m.getParameterTypes();
      int numParams = params.length;
      if (pod == Sys.sysPod)
      {
        if (!checkAllFan(params)) return;
        if (javaRepr)
        {
          boolean javaStatic = Modifier.isStatic(m.getModifiers());
          if (!javaStatic) return;
          if (!method.isStatic() && !method.isCtor()) --numParams;
        }
      }

      // zero index is full signature up to using max defaults
      method.reflect[method.params().sz()-numParams] = m;
    }
    else
    {
      Field field = (Field)slot;
      if (m.getReturnType() == void.class)
        field.setter.reflect = new java.lang.reflect.Method[] { m };
      else
        field.getter.reflect = new java.lang.reflect.Method[] { m };
    }
  }

  // used by JStub only
  public FTypeEmit[] emitToClassFiles()
    throws Exception
  {
    reflect();
    return FTypeEmit.emit(this, ftype);
  }

  boolean checkAllFan(Class[] params)
  {
    for (int i=0; i<params.length; ++i)
    {
      Class p = params[i];

      // anything that starts with fan. is a clean fan type
      if (p.getName().startsWith("fan.")) continue;

      // try to map to non-FFI Fantom type - this handles
      // things like long, Long, String
      Type x = FanUtil.toFanType(p, false);
      if (x == null || x.isJava()) return false;
    }
    return true;
  }

  public boolean javaRepr() { return javaRepr; }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final boolean Debug = false;
  static Object noParams;

  // available when hollow
  final Pod pod;
  final String name;
  final String qname;
  final int flags;
  final Type nullable;
  int lineNum;
  String sourceFile = "";
  Type base;
  List mixins;
  List inheritance;
  FType ftype;      // we only keep this around for memory compiles
  boolean docLoaded;
  public String doc;

  // available when reflected
  List fields;
  List methods;
  List slots;
  HashMap slotsByName;  // String:Slot
  Facets myFacets;
  Facets inheritedFacets;  // handled in loadFacets

  // available when emitted
  Class cls;         // main Java class representation
  Class auxCls;      // implementation Java class if mixin/Err

  // flags to ensure we finish only once
  boolean finished;
  String finishing;

  // misc
  boolean javaRepr;   // if representation a Java type, such as java.lang.Long

}
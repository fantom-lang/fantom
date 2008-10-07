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
import fanx.typedb.*;
import fanx.util.*;

/**
 * Type models a static type definition for an Obj class.  A Type lifecycle:
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
public class Type
  extends FanObj
  implements Literal
{

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

  public static Type find(String sig) { return TypeParser.load(sig, true, null); }
  public static Type find(String sig, Boolean checked) { return TypeParser.load(sig, checked, null); }
  public static Type find(String sig, boolean checked) { return TypeParser.load(sig, checked, null); }
  public static Type find(String podName, String typeName, boolean checked)
  {
    Pod pod = Pod.find(podName, checked, null, null);
    if (pod == null) return null;
    return pod.findType(typeName, checked);
  }

  public static List findByFacet(String facetName, Object facetVal) { return findByFacet(facetName, facetVal, null); }
  public static List findByFacet(String facetName, Object facetVal, Object options)
  {
    return TypeDb.get().findByFacet(facetName, facetVal, options);
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  Type(Pod pod, FType ftype)
  {
    this.pod      = pod;
    this.ftype    = ftype;
    this.name     = pod.fpod.name(pod.fpod.typeRef(ftype.self).typeName);
    this.qname    = pod.name + "::" + name;
    this.flags    = ftype.flags;
    this.dynamic  = false;
    if (Debug) System.out.println("-- init:   " + qname);
  }

  // parameterized type constructor
  public Type(Pod pod, String name, int flags, Facets facets)
  {
    this.pod      = pod;
    this.name     = name;
    this.qname    = pod.name + "::" + name;
    this.flags    = flags;
    this.dynamic  = false;
    this.facets   = facets;
  }

//////////////////////////////////////////////////////////////////////////
// Naming
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.TypeType; }

  public final Pod pod()   { return pod; }
  public final String name()  { return name; }
  public final String qname() { return qname; }
  public String signature()   { return qname; }

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  public final Boolean isAbstract() { return (flags & FConst.Abstract) != 0; }
  public final Boolean isClass() { return (flags & (FConst.Enum|FConst.Mixin)) == 0; }
  public final Boolean isConst() { return (flags & FConst.Const) != 0; }
  public final Boolean isEnum() { return (flags & FConst.Enum) != 0; }
  public final Boolean isFinal() { return (flags & FConst.Final) != 0; }
  public final Boolean isInternal() { return (flags & FConst.Internal) != 0; }
  public final Boolean isMixin() { return (flags & FConst.Mixin) != 0; }
  public final Boolean isPublic() { return (flags & FConst.Public) != 0; }
  public final Boolean isSynthetic() { return (flags & FConst.Synthetic) != 0; }

  public Object trap(String name, List args)
  {
    // private undocumented access
    if (name.equals("flags"))      return Long.valueOf(flags);
    if (name.equals("lineNumber")) { reflect(); return Long.valueOf(lineNum); }
    if (name.equals("sourceFile")) { reflect(); return sourceFile; }
    return super.trap(name, args);
  }

//////////////////////////////////////////////////////////////////////////
// Dynamic
//////////////////////////////////////////////////////////////////////////

  public static Type makeDynamic(List supers) { return makeDynamic(supers, null); }
  public static Type makeDynamic(List supers, Map facets)
  {
    Type t = new Type();
    makeDynamic$(t, supers, facets);
    return t;
  }

  public static void makeDynamic$(Type t, List supers) { makeDynamic$(t, supers, null); }
  public static void makeDynamic$(Type t, List supers, Map facets)
  {
    if (supers == null || supers.sz() == 0)
      throw ArgErr.make("Must pass in a supers list with at least one type").val;

    // check that first is a class type
    t.base = (Type)supers.get(0);
    if (t.base.isMixin()) throw ArgErr.make("Not a class: " + t.base).val;
    t.base.checkOkForDynamic();

    // TODO: we don't support mixins yet
    if (supers.sz() > 1)
      throw ArgErr.make("Sorry - mixins not supported yet").val;

    // check that the rest are mixin types
    List mixins = new List(Sys.TypeType);
    for (int i=1; i<supers.sz(); ++i)
    {
      Type m = (Type)supers.get(i);
      if (!m.isMixin()) throw ArgErr.make("Not mixin: " + m).val;
      m.checkOkForDynamic();
      mixins.add(m);
    }
    t.mixins = mixins.ro();

    // facets
    t.facets = Facets.make(facets);
  }

  private void checkOkForDynamic()
  {
    if ((flags & (FConst.Abstract|FConst.Final|FConst.Const)) != 0)
      throw ArgErr.make("Cannot use abstract, final, or const in makeDynamic: " + this).val;
    if (dynamic)
      throw ArgErr.make("Cannot use dynamic in makeDynamic: " + this).val;
  }

  // dynamic constructor
  protected Type()
  {
    this.pod     = null;
    this.name    = "dynamic";
    this.qname   = name;
    this.flags   = 0;
    this.dynamic = true;
  }

  public Boolean isDynamic() { return dynamic; }

//////////////////////////////////////////////////////////////////////////
// Nullable
//////////////////////////////////////////////////////////////////////////

  public Boolean isNullable() { return false; }

  public Type toNullable()
  {
    if (nullable == null) nullable = new NullableType(this);
    return nullable;
  }

//////////////////////////////////////////////////////////////////////////
// Generics
//////////////////////////////////////////////////////////////////////////

  /**
   * A generic type means that one or more of my slots contain signatures
   * using a generic parameter (such as V or K).  Fan supports three built-in
   * generic types: List, Map, and Func.  A generic instance (such as Str[])
   * is NOT a generic type (all of its generic parameters have been filled in).
   * User defined generic types are not supported in Fan.
   */
  public boolean isGenericType()
  {
    return this == Sys.ListType || this == Sys.MapType || this == Sys.FuncType;
  }

  /**
   * A generic instance is a type which has "instantiated" a generic type
   * and replaced all the generic parameter types with generic argument
   * types.  The type Str[] is a generic instance of the generic type
   * List (V is replaced with Str).  A generic instance always has a signature
   * which different from the qname.
   */
  public boolean isGenericInstance()
  {
    return false;
  }

  /**
   * Return if this type is a generic parameter (such as V or K) in a
   * generic type (List, Map, or Method).  Generic parameters serve
   * as place holders for the parameterization of the generic type.
   * Fan has a predefined set of generic parameters which are always
   * defined in the sys pod with a one character name.
   */
  public boolean isGenericParameter()
  {
    return pod == Sys.SysPod && name.length() == 1;
  }

  /*
   * If this type is a generic parameter (V, L, etc), then return
   * the actual type used in the Java method.  For example V is Obj,
   * and L is List.  This is the type we actually use when constructing
   * a signature for the invoke opcode.
   */
  public Type getRawType()
  {
    if (!isGenericParameter()) return this;
    if (this == Sys.LType) return Sys.ListType;
    if (this == Sys.MType) return Sys.MapType;
    if (this instanceof ListType) return Sys.ListType;
    if (this instanceof MapType)  return Sys.MapType;
    if (this instanceof FuncType) return Sys.FuncType;
    return Sys.ObjType;
  }

  public final Boolean isGeneric()
  {
    return isGenericType();
  }

  public Map params()
  {
    if (noParams == null)
      noParams = new Map(Sys.StrType, Sys.TypeType).ro();
    return (Map)noParams;
  }

  public final Type parameterize(Map params)
  {
    if (this == Sys.ListType)
    {
      Type v = (Type)params.get("V");
      if (v == null) throw ArgErr.make("List.parameterize - V undefined").val;
      return v.toListOf();
    }

    if (this == Sys.MapType)
    {
      Type v = (Type)params.get("V");
      Type k = (Type)params.get("K");
      if (v == null) throw ArgErr.make("Map.parameterize - V undefined").val;
      if (k == null) throw ArgErr.make("Map.parameterize - K undefined").val;
      return new MapType(k, v);
    }

    if (this == Sys.FuncType)
    {
      Type r = (Type)params.get("R");
      if (r == null) throw ArgErr.make("Map.parameterize - R undefined").val;
      ArrayList p = new ArrayList();
      for (int i='A'; i<='H'; ++i)
      {
        Type x = (Type)params.get(FanStr.ascii[i]);
        if (x == null) break;
        p.add(x);
      }
      return new FuncType((Type[])p.toArray(new Type[p.size()]), r);
    }

    throw UnsupportedErr.make("not generic: " + this).val;
  }

  public final synchronized Type toListOf()
  {
    if (listOf == null) listOf = new ListType(this);
    return listOf;
  }

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

  public final List fields()  { return reflect().fields.ro(); }
  public final List methods() { return reflect().methods.ro(); }
  public final List slots()   { return reflect().slots.ro(); }

  public final Field field(String name) { return (Field)slot(name, true); }
  public final Field field(String name, Boolean checked) { return (Field)slot(name, checked.booleanValue()); }
  public final Field field(String name, boolean checked) { return (Field)slot(name, checked); }

  public final Method method(String name) { return (Method)slot(name, true); }
  public final Method method(String name, Boolean checked) { return (Method)slot(name, checked.booleanValue()); }
  public final Method method(String name, boolean checked) { return (Method)slot(name, checked); }

  public final Slot slot(String name) { return slot(name, true); }
  public final Slot slot(String name, Boolean checked) { return slot(name, checked.booleanValue()); }
  public final Slot slot(String name, boolean checked)
  {
    Slot slot = (Slot)reflect().slotsByName.get(name);
    if (slot != null) return slot;
    if (checked) throw UnknownSlotErr.make(this.qname + "." + name).val;
    return null;
  }

  public final void add(Slot slot)
  {
    if (!dynamic) throw Err.make("Type is not dynamic: " + qname).val;
    reflect();
    if (slotsByName.containsKey(slot.name)) throw Err.make("Duplicate slot name: " + qname).val;
    if (slot.parent != null) throw Err.make("Slot is already parented: " + slot).val;

    slot.parent = this;
    slotsByName.put(slot.name, slot);
    slots.add(slot);
    if (slot instanceof Field)
      fields.add(slot);
    else
      methods.add(slot);
  }

  public final void remove(Slot slot)
  {
    if (!dynamic) throw Err.make("Type is not dynamic: " + qname).val;
    if (slot.parent != this) throw Err.make("Slot.parent != this: " + slot).val;

    slot.parent = null;
    slotsByName.remove(slot.name);
    slots.remove(slot);
    if (slot instanceof Field)
      fields.remove(slot);
    else
      methods.remove(slot);
  }

  public final Object make() { return make(null); }
  public final Object make(List args)
  {
    if (dynamic) return makeDynamicInstance();
    return method("make", true).func.call(args);
  }

  private Object makeDynamicInstance()
  {
    // dynamic make requires generation of a special subclass which can
    // store the type per instance.  Once generated we keep a reference
    // to the constructor and use that to generate instances bound to this
    // specific dynamic type.  Because we are by-passing the normal ctor/default
    // param infastructure we make our lives simple by just requiring a no arg
    // make ctor (eventually it would be nice to enhance this to allow args).
    try
    {
      // lazy generation
      if (dynamicCtor == null)
      {
        // check for no-arg make on base class
        Method make = base.method("make", true);
        if (!make.isCtor() || make.params().sz() != 0)
          throw Err.make("Dynamic base type requires no arg make ctor: " + base).val;

        // generate the class and store the Java constructor
        Class cls = FDynamicEmit.emitAndLoad(base);
        dynamicCtor = cls.getConstructor(new Class[] { Type.class });
      }

      // use our special subclass which can store type per instance
      return dynamicCtor.newInstance(new Object[] { this });
    }
    catch (Err.Val e)
    {
      throw e;
    }
    catch (Exception e)
    {
      e.printStackTrace();
      throw Err.make("Cannot generate/call dynamic type ctor", e).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Inheritance
//////////////////////////////////////////////////////////////////////////

  public Type base() { return base; }

  public List mixins() { return mixins; }

  public List inheritance()
  {
    if (inheritance == null)
    {
      HashMap map = new HashMap();
      List acc = new List(Sys.TypeType);

      // handle Void as a special case
      if (this == Sys.VoidType)
      {
        acc.add(this);
        return inheritance = acc.trim();
      }

      // add myself
      map.put(qname, this);
      acc.add(this);

      // add my direct inheritance inheritance
      addInheritance(base(), acc, map);
      List mixins = mixins();
      for (int i=0; i<mixins.sz(); ++i)
        addInheritance((Type)mixins.get(i), acc, map);

      inheritance = acc.trim().ro();
    }
    return inheritance;
  }

  private void addInheritance(Type t, List acc, HashMap map)
  {
    if (t == null) return;
    List ti = t.inheritance();
    for (int i=0; i<ti.sz(); ++i)
    {
      Type x = (Type)ti.get(i);
      if (map.get(x.qname) == null)
      {
        map.put(x.qname, x);
        acc.add(x);
      }
    }
  }

  public final Boolean fits(Type type) { return is(type); }
  public boolean is(Type type)
  {
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
    Type best = type(objs[0]);
    for (int i=1; i<n; ++i)
    {
      Object obj = objs[i];
      if (obj == null) continue;
      Type t = type(obj);
      while (!t.is(best))
      {
        best = best.base;
        if (best == null) return Sys.ObjType;
      }
    }
    return best;
  }

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  public final Map facets() { return facets(false); }
  public final Map facets(Boolean inherited)
  {
    Map map = reflect().facets.map();
    if (inherited)
    {
      map = map.rw();
      List inheritance = inheritance();
      for (int i=0; i<inheritance.sz(); ++i)
      {
        Map x = ((Type)inheritance.get(i)).facets(false);
        if (x.isEmpty()) continue;
        Iterator it = x.pairsIterator();
        while (it.hasNext())
        {
          Entry e = (Entry)it.next();
          String key = (String)e.getKey();
          if (map.get(key) == null) map.add(key, e.getValue());
        }
      }
    }
    return map;
  }

  public final Object facet(String name) { return facet(name, null, false); }
  public final Object facet(String name, Object def) { return facet(name, def, false); }
  public final Object facet(String name, Object def, Boolean inherited)
  {
    Object val = reflect().facets.get(name, null);
    if (val != null) return val;
    if (!inherited) return def;
    List inheritance = inheritance();
    for (int i=0; i<inheritance.sz(); ++i)
    {
      val = ((Type)inheritance.get(i)).facet(name, null, false);
      if (val != null) return val;
    }
    return def;
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
        if (in != null)
        {
          try { FDoc.read(in); } finally { in.close(); }
        }
      }
      catch (Exception e)
      {
        e.printStackTrace();
      }
      docLoaded = true;
    }
    return doc;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public String toStr() { return signature(); }

  public Boolean isImmutable() { return !dynamic; }

  public final Type toImmutable()
  {
    if (!dynamic) return this;
    throw NotImmutableErr.make("Type is dynamic").val;
  }

  public void encode(ObjEncoder out)
  {
    out.w(qname).w("#");
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public final Log log() { return pod.log(); }

  public final String loc(String key) { return pod.loc(key); }

  public final String loc(String key, String def) { return pod.loc(key, def); }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  protected final synchronized Type reflect()
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
    if (!dynamic && ftype.hollow)
    {
      try
      {
        ftype.read();
      }
      catch (IOException e)
      {
        e.printStackTrace();
        throw IOErr.make("Cannot read " + qname + " from pod", e).val;
      }
    }

    // these are working accumulators used to build the
    // data structures of my defined and inherited slots
    List slots  = new List(Sys.SlotType, 64);
    HashMap nameToSlot  = new HashMap();   // String -> Slot
    HashMap nameToIndex = new HashMap();   // String -> Int

    // merge in base class and mixin classes
    merge(base, slots, nameToSlot, nameToIndex);
    for (int i=0; i<mixins().sz(); ++i) merge((Type)mixins.get(i), slots, nameToSlot, nameToIndex);

    // merge in all my slots
    if (!dynamic)
    {
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

    // facets
    if (!dynamic)
    {
      this.facets     = ftype.attrs.facets();
      this.lineNum    = ftype.attrs.lineNum;
      this.sourceFile = ftype.attrs.sourceFile;
    }
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
    List inheritedSlots = inheritedType.reflect().slots;
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
    Type fieldType = pod.findType(f.type);
    return new Field(this, name, f.flags, f.attrs.facets(), f.attrs.lineNum, fieldType);
  }

  /**
   * Map fcode method to a sys::Method.
   */
  private Method map(FPod fpod, FMethod m)
  {
    String name = m.name.intern();
    Type returns = pod.findType(m.ret);
    Type inheritedReturns = pod.findType(m.inheritedRet);
    List params = new List(Sys.ParamType, m.paramCount);
    for (int j=0; j<m.paramCount; ++j)
    {
      FMethodVar p = m.vars[j];
      int pflags = (p.def == null) ? 0 : Param.HAS_DEFAULT;
      params.add(new Param(p.name.intern(), pod.findType(p.type), pflags));
    }
    return new Method(this, name, m.flags, m.attrs.facets(), m.attrs.lineNum, returns, inheritedReturns, params);
  }

//////////////////////////////////////////////////////////////////////////
// Emit
//////////////////////////////////////////////////////////////////////////

  /**
   * Emit to a Java class.
   */
  public synchronized Class emit()
  {
    if (cls == null && !dynamic)
    {
      if (Debug) System.out.println("-- emit:   " + qname);

      // make sure we have reflected to setup slots
      reflect();

      // if sys class, just load it by name
      String podName = pod.name;
      if (podName.equals("sys") || Sys.usePrecompiledOnly)
      {
        try
        {
          this.javaRepr = FanUtil.isJavaRepresentation(this);
          this.cls = Class.forName(FanUtil.toJavaImplClassName(podName, name));
        }
        catch (Exception e)
        {
          e.printStackTrace();
          throw Err.make("Cannot load precompiled class: " + qname, e).val;
        }
      }

      // otherwise we need to emit it
      else
      {
        try
        {
          Class[] classes = FTypeEmit.emitAndLoad(this, ftype);
          this.cls = classes[0];
          if (classes.length > 1)
            this.auxCls = classes[1];
        }
        catch (Exception e)
        {
          e.printStackTrace();
          throw Err.make("Cannot emit: " + qname, e).val;
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
      else if (is(Sys.ErrType))
        this.auxCls = cls.getClassLoader().loadClass(cls.getName()+"$Val");
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
System.out.println("---- Finish " + qname());
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
      throw Err.make("Cannot emitFinish: " + qname + "." + finishing, e).val;
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
    if (dynamic) return;

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
    this.finishing = m.getName();
    String name = FanUtil.toFanMethodName(m.getName());
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
      // methods that use non-Fan signatures
      Class[] params = m.getParameterTypes();
      int numParams = params.length;
      if (pod == Sys.SysPod)
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
      method.reflect[method.params().sz()-numParams ] = m;
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
      if (!p.getName().startsWith("fan.") && FanUtil.toFanType(p, false) == null)
        return false;
    }
    return true;
  }

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
  final boolean dynamic;
  int lineNum;
  String sourceFile = "";
  Facets facets;
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

  // available when emitted
  Class cls;         // main Java class representation
  Class auxCls;      // implementation Java class if mixin/Err

  // flags to ensure we finish only once
  boolean finished;
  String finishing;

  // misc
  Type nullable;
  Type listOf;
  Constructor dynamicCtor;  // enabled to store a type per instance
  boolean javaRepr;         // if representation a Java type, such as java.lang.Long

}
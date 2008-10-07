//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Sep 06  Andy Frank  Creation
//

using System;
using System.Collections;
using System.IO;
using System.Reflection;
using System.Runtime.CompilerServices;
using Fanx.Emit;
using Fanx.Fcode;
using Fanx.Serial;
using Fanx.Typedb;
using Fanx.Util;

namespace Fan.Sys
{
  ///
  /// Type models a static type definition for an Obj class.  A Type lifecycle:
  ///
  ///  1) Hollow: in this state we know basic identity of the type, and
  ///     it's inheritance hierarchy.  A type is setup to be hollow during
  ///     Pod.load().
  ///  2) Reflected: in this state we read all the slot definitions from the
  ///     fcode to populate the slot tables used to for reflection.  At this
  ///     point clients can discover the signatures of the Type.
  ///  3) Emitted: the final state of loading a Type is to emit to a Java
  ///     class called "fan.{pod}.{type}".  Once emitted we can instantiate
  ///     the type or call it's methods.
  ///  4) Finished: once we have reflected the slots into memory and emitted
  ///     the Java class, the last stage is to bind the all the java.lang.reflect
  ///     representations to the Slots for dynamic dispatch.  We delay this
  ///     until needed by Method or Field for a reflection invocation
  ///
  ///  A special stub state is also used to bootstrap the compiler self tests
  ///  and to compile sys itself.  Stub types use java reflection to map their
  ///  Java API to their Fan API (rather crudely).
  ///
  public class Type : FanObj, Literal
  {

  //////////////////////////////////////////////////////////////////////////
  // Management
  //////////////////////////////////////////////////////////////////////////

    public static Type find(Str sig) { return TypeParser.load(sig.val, true, null); }
    public static Type find(String sig) { return TypeParser.load(sig, true, null); }
    public static Type find(Str sig, Bool check) { return TypeParser.load(sig.val, check.val, null); }
    public static Type find(String sig, bool check) { return TypeParser.load(sig, check, null); }
    public static Type find(String podName, String typeName, bool check)
    {
      Pod pod = Fan.Sys.Pod.find(podName, check, null);
      if (pod == null) return null;
      return pod.findType(typeName, check);
    }

    public static List findByFacet(Str facetName, object facetVal) { return findByFacet(facetName, facetVal, null); }
    public static List findByFacet(Str facetName, object facetVal, object options)
    {
      return TypeDb.get().findByFacet(facetName, facetVal, options);
    }

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    internal Type(Pod pod, FType ftype)
    {
      this.m_pod     = pod;
      this.m_ftype   = ftype;
      this.m_name    = Str.make(pod.fpod.name(pod.fpod.typeRef(ftype.m_self).typeName));
      this.m_qname   = Str.make(pod.m_name.val + "::" + m_name.val);
      this.m_flags   = ftype.m_flags;
      this.m_dynamic = false;
      if (Debug) Console.WriteLine("-- init:   " + m_qname);
    }

    // ShimType and parameterized type constructor
    public Type(Pod pod, string name, int flags, Facets facets)
    {
      this.m_pod    = pod;
      this.m_name   = Str.make(name);
      this.m_qname  = Str.make(pod.m_name.val + "::" + name);
      this.m_flags  = flags;
      this.m_facets = facets;
    }

  //////////////////////////////////////////////////////////////////////////
  // Naming
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.TypeType; }

    public Pod pod()   { return m_pod; }
    public Str name()  { return m_name; }
    public Str qname() { return m_qname; }
    public virtual Str signature() { return m_qname; }

  //////////////////////////////////////////////////////////////////////////
  // Flags
  //////////////////////////////////////////////////////////////////////////

    public Bool isAbstract() { return Bool.make(m_flags & FConst.Abstract); }
    public Bool isClass() { return Bool.make((m_flags & (FConst.Enum|FConst.Mixin)) == 0); }
    public Bool isConst() { return Bool.make(m_flags & FConst.Const); }
    public Bool isEnum() { return Bool.make(m_flags & FConst.Enum); }
    public Bool isFinal() { return Bool.make(m_flags & FConst.Final); }
    public Bool isInternal() { return Bool.make(m_flags & FConst.Internal); }
    public Bool isMixin() { return Bool.make(m_flags & FConst.Mixin); }
    public Bool isPublic() { return Bool.make(m_flags & FConst.Public); }
    public Bool isSynthetic() { return Bool.make(m_flags & FConst.Synthetic); }

    public override object trap(Str name, List args)
    {
      // private undocumented access
      string n = name.val;
      if (n == "flags")      return Int.make(m_flags);
      if (n == "lineNumber") { reflect(); return Int.make(m_lineNum); }
      if (n == "sourceFile") { reflect(); return Str.make(m_sourceFile); }
      return base.trap(name, args);
    }

  //////////////////////////////////////////////////////////////////////////
  // Dynamic
  //////////////////////////////////////////////////////////////////////////

    public static Type makeDynamic(List supers) { return makeDynamic(supers, null); }
    public static Type makeDynamic(List supers, Map facets)
    {
      Type t = new Type();
      makeDynamic_(t, supers, facets);
      return t;
    }

    public static void makeDynamic_(Type t, List supers) { makeDynamic_(t, supers, null); }
    public static void makeDynamic_(Type t, List supers, Map facets)
    {
      if (supers == null || supers.sz() == 0)
        throw ArgErr.make("Must pass in a supers list with at least one type").val;

      // check that first is a class type
      t.m_base = (Type)supers.get(0);
      if (t.m_base.isMixin().val) throw ArgErr.make("Not a class: " + t.m_base).val;
      t.m_base.checkOkForDynamic();

      // TODO: we don't support mixins yet
      if (supers.sz() > 1)
        throw ArgErr.make("Sorry - mixins not supported yet").val;

      // check that the rest are mixin types
      List mixins = new List(Sys.TypeType);
      for (int i=1; i<supers.sz(); ++i)
      {
        Type m = (Type)supers.get(i);
        if (!m.isMixin().val) throw ArgErr.make("Not mixin: " + m).val;
        m.checkOkForDynamic();
        mixins.add(m);
      }
      t.m_mixins = mixins.ro();

      // facets
      t.m_facets = Facets.make(facets);
    }

    private void checkOkForDynamic()
    {
      if ((m_flags & (FConst.Abstract|FConst.Final|FConst.Const)) != 0)
        throw ArgErr.make("Cannot use abstract, final, or const in makeDynamic: " + this).val;
      if (m_dynamic)
        throw ArgErr.make("Cannot use dynamic in makeDynamic: " + this).val;
    }

    // dynamic constructor
    protected Type()
    {
      this.m_pod     = null;
      this.m_name    = Str.make("dynamic");
      this.m_qname   = m_name;
      this.m_flags   = 0;
      this.m_dynamic = true;
    }

    public Bool isDynamic() { return Bool.make(m_dynamic); }

  //////////////////////////////////////////////////////////////////////////
  // Generics
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// A generic type means that one or more of my slots contain signatures
    /// using a generic parameter (such as V or K).  Fan supports three built-in
    /// generic types: List, Map, and Method.  A generic instance (such as Str[])
    /// is NOT a generic type (all of its generic parameters have been filled in).
    /// User defined generic types are not supported in Fan.
    /// </summary>
    public bool isGenericType()
    {
      return this == Sys.ListType || this == Sys.MapType || this == Sys.FuncType;
    }

    /// <summary>
    /// A generic instance is a type which has "instantiated" a generic type
    /// and replaced all the generic parameter types with generic argument
    /// types.  The type Str[] is a generic instance of the generic type
    /// List (V is replaced with Str).  A generic instance always has a signature
    /// which different from the qname.
    /// </summary>
    public virtual bool isGenericInstance()
    {
      return false;
    }

    /// <summary>
    /// Return if this type is a generic parameter (such as V or K) in a
    /// generic type (List, Map, or Method).  Generic parameters serve
    /// as place holders for the parameterization of the generic type.
    /// Fan has a predefined set of generic parameters which are always
    /// defined in the sys pod with a one character name.
    /// </summary>
    public virtual bool isGenericParameter()
    {
      return m_pod == Sys.SysPod && m_name.val.Length == 1;
    }

    /// <summary>
    /// If this type is a generic parameter (V, L, etc), then return
    /// the actual type used in the Java method.  For example V is Obj,
    /// and L is List.  This is the type we actually use when constructing
    /// a signature for the invoke opcode.
    /// </summary>
    public virtual Type getRawType()
    {
      if (!isGenericParameter()) return this;
      if (this == Sys.LType)  return Sys.ListType;
      if (this == Sys.MType)  return Sys.MapType;
      if (this is ListType)   return Sys.ListType;
      if (this is MapType)    return Sys.MapType;
      if (this is FuncType) return Sys.FuncType;
      return Sys.ObjType;
    }

    public Bool isGeneric()
    {
      return isGenericType() ? Bool.True : Bool.False;
    }

    public virtual Map @params()
    {
      if (noParams == null)
        noParams = new Map(Sys.StrType, Sys.TypeType).ro();
      return (Map)noParams;
    }

    public Type parameterize(Map pars)
    {
      if (this == Sys.ListType)
      {
        Type v = (Type)pars.get(Str.m_ascii['V']);
        if (v == null) throw ArgErr.make("List.parameterize - V undefined").val;
        return v.toListOf();
      }

      if (this == Sys.MapType)
      {
        Type v = (Type)pars.get(Str.m_ascii['V']);
        Type k = (Type)pars.get(Str.m_ascii['K']);
        if (v == null) throw ArgErr.make("Map.parameterize - V undefined").val;
        if (k == null) throw ArgErr.make("Map.parameterize - K undefined").val;
        return new MapType(k, v);
      }

      if (this == Sys.FuncType)
      {
        Type r = (Type)pars.get(Str.m_ascii['R']);
        if (r == null) throw ArgErr.make("Map.parameterize - R undefined").val;
        ArrayList p = new ArrayList();
        for (int i='A'; i<='H'; ++i)
        {
          Type x = (Type)pars.get(Str.m_ascii[i]);
          if (x == null) break;
          p.Add(x);
        }
        return new FuncType((Type[])p.ToArray(System.Type.GetType("Fan.Sys.Type")), r);
      }

      throw UnsupportedErr.make("not generic: " + this).val;
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public Type toListOf()
    {
      if (listOf == null) listOf = new ListType(this);
      return listOf;
    }

  //////////////////////////////////////////////////////////////////////////
  // Slots
  //////////////////////////////////////////////////////////////////////////

    public List fields()  { return reflect().m_fields.ro(); }
    public List methods() { return reflect().m_methods.ro(); }
    public List slots()   { return reflect().m_slots.ro(); }

    public Field field(Str name) { return (Field)slot(name.val, true); }
    public Field field(Str name, Bool check) { return (Field)slot(name.val, check.val); }
    public Field field(string name, bool check) { return (Field)slot(name, check); }

    public Method method(Str name) { return (Method)slot(name.val, true); }
    public Method method(Str name, Bool check) { return (Method)slot(name.val, check.val); }
    public Method method(string name, bool check) { return (Method)slot(name, check); }

    public Slot slot(Str name) { return slot(name.val, true); }
    public Slot slot(Str name, Bool check) { return slot(name.val, check.val); }
    public Slot slot(string name, bool check)
    {
      Slot slot = (Slot)reflect().m_slotsByName[name];
      if (slot != null) return slot;
      if (check) throw UnknownSlotErr.make(this.m_qname + "." + name).val;
      return null;
    }

    public void add(Slot slot)
    {
      if (!m_dynamic) throw Err.make("Type is not dynamic: " + m_qname).val;
      reflect();
      if (m_slotsByName.ContainsKey(slot.m_name.val)) throw Err.make("Duplicate slot name: " + m_qname).val;
      if (slot.m_parent != null) throw Err.make("Slot is already parented: " + slot).val;

      slot.m_parent = this;
      m_slotsByName[slot.m_name.val] = slot;
      m_slots.add(slot);
      if (slot is Field)
        m_fields.add(slot);
      else
        m_methods.add(slot);
    }

    public void remove(Slot slot)
    {
      if (!m_dynamic) throw Err.make("Type is not dynamic: " + m_qname).val;
      if (slot.m_parent != this) throw Err.make("Slot.parent != this: " + slot).val;

      slot.m_parent = null;
      m_slotsByName.Remove(slot.m_name.val);
      m_slots.remove(slot);
      if (slot is Field)
        m_fields.remove(slot);
      else
        m_methods.remove(slot);
    }

    public object make() { return make(null); }
    public object make(List args)
    {
      if (m_dynamic) return makeDynamicInstance();
      return method("make", true).call(args);
    }

    private object makeDynamicInstance()
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
          Method make = m_base.method("make", true);
          if (!make.isCtor().val || make.m_func.m_params.sz() != 0)
            throw Err.make("Dynamic base type requires no arg make ctor: " + m_base).val;

          // generate the class and store the .NET constructor
          System.Type type = FDynamicEmit.emitAndLoad(m_base);
          dynamicCtor = type.GetConstructor(
            new System.Type[] { System.Type.GetType("Fan.Sys.Type") });
        }

        // use our special subclass which can store type per instance
        return dynamicCtor.Invoke(new object[] { this });
      }
      catch (Err.Val e)
      {
        throw e;
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
        throw Err.make("Cannot generate/call dynamic type ctor", e).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Inheritance
  //////////////////////////////////////////////////////////////////////////

    public virtual Type @base() { return m_base; }

    public virtual List mixins() { return m_mixins; }

    public List inheritance()
    {
      if (m_inheritance == null)
      {
        Hashtable map = new Hashtable();
        List acc = new List(Sys.TypeType);

        // handle Void as a special case
        if (this == Sys.VoidType)
        {
          acc.add(this);
          return m_inheritance = acc.trim();
        }

        // add myself
        map[m_qname.val] = this;
        acc.add(this);

        // add my direct inheritance inheritance
        addInheritance(@base(), acc, map);
        List m = mixins();
        for (int i=0; i<m.sz(); i++)
          addInheritance((Type)m.get(i), acc, map);

        m_inheritance = acc.trim().ro();
      }
      return m_inheritance;
    }

    private void addInheritance(Type t, List acc, Hashtable map)
    {
      if (t == null) return;
      List ti = t.inheritance();
      for (int i=0; i<ti.sz(); i++)
      {
        Type x = (Type)ti.get(i);
        if (map[x.m_qname.val] == null)
        {
          map[x.m_qname.val] = x;
          acc.add(x);
        }
      }
    }

    public Bool fits(Type type) { return @is(type) ? Bool.True : Bool.False; }
    public virtual bool @is(Type type)
    {
      if (type == this || (type == Sys.ObjType && this != Sys.VoidType))
        return true;
      List inherit = inheritance();
      for (int i=0; i<inherit.sz(); ++i)
        if (inherit.get(i) == type) return true;
      return false;
    }

    /// <summary>
    /// Given a list of objects, compute the most specific type which they all
    /// share,or at worst return sys::Obj.  This method does not take into
    /// account interfaces, only extends class inheritance.
    /// </summary>
    public static Type common(object[] objs, int n)
    {
      if (objs.Length == 0) return Sys.ObjType;
      Type best = type(objs[0]);
      for (int i=1; i<n; ++i)
      {
        object obj = objs[i];
        if (obj == null) continue;
        Type t = type(obj);
        while (!t.@is(best))
        {
          best = best.m_base;
          if (best == null) return Sys.ObjType;
        }
      }
      return best;
    }

  //////////////////////////////////////////////////////////////////////////
  // Facets
  //////////////////////////////////////////////////////////////////////////

    public Map facets() { return facets(Bool.False); }
    public Map facets(Bool inherited)
    {
      Map map = reflect().m_facets.map();
      if (inherited.val)
      {
        map = map.rw();
        List inherit = inheritance();
        for (int i=0; i<inherit.sz(); ++i)
        {
          Map x = ((Type)inherit.get(i)).facets(Bool.False);
          if (x.isEmpty().val) continue;
          IDictionaryEnumerator en = x.pairsIterator();
          while (en.MoveNext())
          {
            Str key = (Str)en.Key;
            if (map.get(key) == null) map.add(key, en.Value);
          }
        }
      }
      return map;
    }

    public object facet(Str name) { return facet(name, null, Bool.False); }
    public object facet(Str name, object def) { return facet(name, def, Bool.False); }
    public object facet(Str name, object def, Bool inherited)
    {
      object val = reflect().m_facets.get(name, null);
      if (val != null) return val;
      if (!inherited.val) return def;
      List inherit = inheritance();
      for (int i=0; i<inherit.sz(); ++i)
      {
        val = ((Type)inherit.get(i)).facet(name, null, Bool.False);
        if (val != null) return val;
      }
      return def;
    }

  //////////////////////////////////////////////////////////////////////////
  // Documentation
  //////////////////////////////////////////////////////////////////////////

    public Str doc()
    {
      if (!m_docLoaded)
      {
        try
        {
          BinaryReader input = m_pod.fpod.m_store.read("doc/" + m_name + ".apidoc");
          if (input != null)
          {
            try { FDoc.read(input); } finally { input.Close(); }
          }
        }
        catch (Exception e)
        {
          Err.dumpStack(e);
        }
        m_docLoaded = true;
      }
      return m_doc;
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public override Str toStr() { return signature(); }

    public override Bool isImmutable() { return m_dynamic ? Bool.False : Bool.True; }

    public Type toImmutable()
    {
      if (!m_dynamic) return this;
      throw NotImmutableErr.make("Type is dynamic").val;
    }

    public void encode(ObjEncoder @out)
    {
      @out.w(m_qname.val).w("#");
    }

  //////////////////////////////////////////////////////////////////////////
  // Util
  //////////////////////////////////////////////////////////////////////////

    public Log log() { return m_pod.log(); }

    public Str loc(Str key) { return m_pod.loc(key); }

    public Str loc(Str key, Str def) { return m_pod.loc(key, def); }

  //////////////////////////////////////////////////////////////////////////
  // Reflection
  //////////////////////////////////////////////////////////////////////////

    [MethodImpl(MethodImplOptions.Synchronized)]
    public Type reflect() // TODO - need to call this from FTypeEmit for now
    {
      // short circuit if already reflected
      if (m_slotsByName != null) return this;

      // if this is a sys stub, use System.Reflection
      //if (isStub) { StubReflect(); return this; }

      if (Debug) Console.WriteLine("-- reflect: " + m_qname + " " + m_slotsByName);

      // do it
      doReflect();

      // return this
      return this;
    }

    protected virtual void doReflect()
    {
      // if the ftype is non-null, that means it was passed in non-hollow
      // ftype (in-memory compile), otherwise we need to read it from the pod
      if (!m_dynamic && m_ftype.m_hollow)
      {
        try
        {
          m_ftype.read();
        }
        catch (IOException e)
        {
          Err.dumpStack(e);
          throw IOErr.make("Cannot read " + m_qname + " from pod", e).val;
        }
      }

      // these are working accumulators used to build the
      // data structures of my defined and inherited slots
      List slots  = new List(Sys.SlotType, 64);
      Hashtable nameToSlot  = new Hashtable();   // String -> Slot
      Hashtable nameToIndex = new Hashtable();   // String -> Int

      // merge in base class and mixin classes
      merge(m_base, slots, nameToSlot, nameToIndex);
      for (int i=0; i<m_mixins.sz(); i++) merge((Type)m_mixins.get(i), slots, nameToSlot, nameToIndex);

      // merge in all my slots
      if (!m_dynamic)
      {
        FPod fpod   = this.m_pod.fpod;
        FType ftype = this.m_ftype;
        for (int i=0; i<ftype.m_fields.Length; i++)
        {
          Field f = map(fpod, ftype.m_fields[i]);
          merge(f, slots, nameToSlot, nameToIndex);
        }
        for (int i=0; i<ftype.m_methods.Length; i++)
        {
          Method m = map(fpod, ftype.m_methods[i]);
          merge(m, slots, nameToSlot, nameToIndex);
        }
      }

      // break out into fields and methods
      List fields  = new List(Sys.FieldType,  slots.sz());
      List methods = new List(Sys.MethodType, slots.sz());
      for (int i=0; i<slots.sz(); i++)
      {
        Slot slot = (Slot)slots.get(i);
        if (slot is Field)
          fields.add(slot);
        else
          methods.add(slot);
      }
      this.m_slots       = slots.trim();
      this.m_fields      = fields.trim();
      this.m_methods     = methods.trim();
      this.m_slotsByName = nameToSlot;

      // facets
      if (!m_dynamic)
      {
        this.m_facets     = m_ftype.m_attrs.facets();
        this.m_lineNum    = m_ftype.m_attrs.m_lineNum;
        this.m_sourceFile = m_ftype.m_attrs.m_sourceFile;
      }
    }

    /// <summary>
    /// Merge the inherit's slots into my slot maps.
    ///   slots:       Slot[] by order
    ///   nameToSlot:  String name -> Slot
    ///   nameToIndex: String name -> Int index of slots
    /// </summary>
    private void merge(Type inheritedType, List slots, Hashtable nameToSlot, Hashtable nameToIndex)
    {
      if (inheritedType == null) return;
      List inheritedSlots = inheritedType.reflect().m_slots;
      for (int i=0; i<inheritedSlots.sz(); i++)
        merge((Slot)inheritedSlots.get(i), slots, nameToSlot, nameToIndex);
    }

    /// <summary>
    /// Merge the inherited slot into my slot maps.  Assume this slot
    /// trumps any previous definition (because we process inheritance
    /// and my slots in the right order)
    ///   slots:       Slot[] by order
    ///   nameToSlot:  String name -> Slot
    ///   nameToIndex: String name -> Int index of slots
    /// </summary>
    private void merge(Slot slot, List slots, Hashtable nameToSlot, Hashtable nameToIndex)
    {
      // skip constructors which aren't mine
      if (slot.isCtor().val && slot.m_parent != this) return;

      string name = slot.m_name.val;
      Int dup = (Int)nameToIndex[name];
      if (dup != null)
      {
        // if the slot is inherited from Obj, then we can
        // safely ignore it as an override - the dup is most
        // likely already the same Obj method inherited from
        // a mixin; but the dup might actually be a more specific
        // override in which case we definitely don't want to
        // override with the sys::Obj version
        if (slot.parent() == Sys.ObjType)
          return;

        // check if this is a Getter or Setter, in which case the Field
        // trumps and we need to cache the method on the Field
        // Note: this works because we assume the compiler always generates
        // the field before the getter and setter in fcode
        if ((slot.m_flags & (FConst.Getter|FConst.Setter)) != 0)
        {
          Field field = (Field)slots.get(dup);
          if ((slot.m_flags & FConst.Getter) != 0)
            field.m_getter = (Method)slot;
          else
            field.m_setter = (Method)slot;
          return;
        }

        nameToSlot[name] = slot;
        slots.set(dup, slot);
      }
      else
      {
        nameToSlot[name] = slot;
        slots.add(slot);
        nameToIndex[name] = Int.make(slots.sz()-1);
      }
    }

    /// <summary>
    /// Map fcode field to a sys::Field.
    /// </summary>
    private Field map(FPod fpod, FField f)
    {
      Str name = Str.make(f.m_name).intern();
      Type fieldType = m_pod.findType(f.m_type);
      return new Field(this, name, f.m_flags, f.m_attrs.facets(), f.m_attrs.m_lineNum, fieldType);
    }

    /// <summary>
    /// Map fcode method to a sys::Method.
    /// </summary>
    private Method map(FPod fpod, FMethod m)
    {
      Str name = Str.make(m.m_name).intern();
      Type returnType = m_pod.findType(m.m_ret);
      Type inheritedReturnType = m_pod.findType(m.m_inheritedRet);
      List pars = new List(Sys.ParamType, m.m_paramCount);
      for (int j=0; j<m.m_paramCount; j++)
      {
        FMethodVar p = m.m_vars[j];
        int pflags = (p.def == null) ? 0 : Param.HAS_DEFAULT;
        pars.add(new Param(Str.make(p.name).intern(), m_pod.findType(p.type), pflags));
      }
      return new Method(this, name, m.m_flags, m.m_attrs.facets(), m.m_attrs.m_lineNum, returnType, inheritedReturnType, pars);
    }

  //////////////////////////////////////////////////////////////////////////
  // Emit
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Emit to a .NET Type.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    public System.Type emit()
    {
      if (m_type == null && !m_dynamic)
      {
        if (Debug) Console.WriteLine("-- emit:   " + m_qname);

        // make sure we have reflected to setup slots
        reflect();

        // if sys class, just load it by name
        string podName = m_pod.m_name.val;
        if (podName == "sys" || Sys.usePrecompiledOnly)
        {
          try
          {
            string name = (this == Sys.ObjType) ? "FanObj" : m_name.val;
            m_type = System.Type.GetType(NameUtil.toNetTypeName(podName, name));
          }
          catch (Exception e)
          {
            Err.dumpStack(e);
            throw Err.make("Cannot load precompiled class: " + m_qname, e).val;
          }
        }

        // otherwise we need to emit it
        else
        {
          try
          {
            System.Type[] types = FTypeEmit.emitAndLoad(m_ftype);
            this.m_type = types[0];
            if (types.Length > 1)
              this.m_auxType = types[1];
          }
          catch (Exception e)
          {
            Err.dumpStack(e);
            throw Err.make("Cannot emit: " + m_qname, e).val;
          }
        }

        // we are done with our ftype now, gc it
        this.m_ftype = null;
      }
      return m_type;
    }

  //////////////////////////////////////////////////////////////////////////
  // Finish
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Finish ensures we have reflected and emitted, then does
    /// the final binding between slots and .NET members.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    public void finish()
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
        finishSlots(m_type, false);
        if (isMixin().val) finishSlots(m_auxType, true);
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
        throw Err.make("Cannot emitFinish: " + m_qname, e).val;
      }
    }

    /// <summary>
    /// Map the Java members of the specified
    /// class to my slots for reflection.
    /// </summary>
    private void finishSlots(System.Type type, bool staticOnly)
    {
      if (m_dynamic) return;

      // map the class's fields to my slots
      FieldInfo[] fields = type.GetFields();
      for (int i=0; i<fields.Length; i++)
        finishField(fields[i]);

      // map the class's methods to my slots
      MethodInfo[] methods = type.GetMethods();
      for (int i=0; i<methods.Length; i++)
        finishMethod(methods[i], staticOnly);
    }

    private void finishField(FieldInfo f)
    {
      Slot s = slot(f.Name.Substring(2), false); // remove 'm_'
      if (s == null || !(s is Field)) return;
      Field field = (Field)s;
      if (field.m_reflect != null) return; // first one seems to give us most specific binding
      //f.setAccessible(true); // TODO - equiv in C# ???
      field.m_reflect = f;
    }

    private void finishMethod(MethodInfo m, bool staticOnly)
    {
      string name = m.Name;
      if (name == "_equals") name = "equals";
      Slot s = slot(name, false);
      if (s == null) return;
      if (s.parent() != this) return;
      if (staticOnly && !s.isStatic().val) return;
      if (s is Method)
      {
        Method method = (Method)s;

        // alloc System.Reflection.MethodInfo[] array big enough
        // to handle all the versions with default parameters
        if (method.m_reflect == null)
        {
          int n = 1;
          for (int j=method.@params().sz()-1; j>=0; j--)
          {
            if (((Param)method.@params().get(j)).hasDefault().val) n++;
            else break;
          }
          method.m_reflect = new MethodInfo[n];
        }

        // get parameters, if sys we need to skip the
        // methods that use non-Fan signatures
        ParameterInfo[] pars = m.GetParameters();
        if (m_pod == Sys.SysPod)
        {
          if (!checkAllFan(pars)) return;
          if (this == Sys.ObjType && m.IsStatic && name != "echo") return;
        }

        // zero index is full signature up to using max defaults
        method.m_reflect[method.@params().sz()-pars.Length] = m;
      }
      else
      {
        Field field = (Field)s;
        if (m.ReturnType.ToString() == "System.Void")
          field.m_setter.m_reflect = new MethodInfo[] { m };
        else
          field.m_getter.m_reflect = new MethodInfo[] { m };
      }
    }

    bool checkAllFan(ParameterInfo[] pars)
    {
      for (int i=0; i<pars.Length; i++)
      {
        string p = pars[i].ParameterType.ToString();
        if (!p.StartsWith("Fan.") && p != "System.Object")
          return false;
      }
      return true;
    }

  //////////////////////////////////////////////////////////////////////////
  // Compiler Support
  //////////////////////////////////////////////////////////////////////////

    public bool isObj()   { return this == Sys.ObjType;  }
    public bool isBool()  { return this == Sys.BoolType; }
    public bool isInt()   { return this == Sys.IntType;  }
    public bool isFloat() { return this == Sys.FloatType; }
    public bool isStr()   { return this == Sys.StrType;  }
    public bool isVoid()  { return this == Sys.VoidType; }

    public Field[] fieldArr()   { return (Field[])fields().toArray(new Field[m_fields.sz()]); }
    public Method[] methodArr() { return (Method[])methods().toArray(new Method[m_methods.sz()]); }
    public Slot[] slotArr()     { return (Slot[])slots().toArray(new Slot[m_slots.sz()]); }

    public void dump()
    {
      System.Console.WriteLine("Type " + qname() + " extends " + @base());
      for (int i=0; i<slots().sz(); i++)
        System.Console.WriteLine("  " + ((Slot)slots().get(i)).signature());
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static readonly bool Debug = false;
    internal static object noParams;

    // available when hollow
    internal readonly Pod m_pod;
    internal readonly Str m_name;
    internal readonly Str m_qname;
    internal readonly int m_flags;
    internal readonly bool m_dynamic;
    internal int m_lineNum;
    internal string m_sourceFile = "";
    internal Facets m_facets;
    internal Type m_base = null;
    internal List m_mixins;
    internal List m_inheritance;
    internal FType m_ftype;   // we only keep this around for memory compiles
    //internal bool isStub;   // sys stub type used to bootstrap compiling of sys itself
    internal bool m_docLoaded;
    public Str m_doc;

    // available when reflected
    internal List m_fields;
    internal List m_methods;
    internal List m_slots;
    internal Hashtable m_slotsByName;  // String:Slot

    // available when emitted
    internal System.Type m_type;     // main .NET type representation
    internal System.Type m_auxType;  // implementation .NET type if mixin/Err

    // flags to ensure we finish only once
    bool finished;

    // misc
    Type listOf;
    ConstructorInfo dynamicCtor;  // enabled to store a type per instance
  }
}
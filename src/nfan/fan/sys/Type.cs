//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Sep 06  Andy Frank  Creation
//

using System.Collections;
using System.Runtime.CompilerServices;
using Fanx.Emit;
using Fanx.Fcode;
using Fanx.Serial;
using Fanx.Typedb;
using Fanx.Util;

namespace Fan.Sys
{
  /// <summary>
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
  ///  Type models sys::Type.  Implementation classes are:
  ///   - ClassType
  ///   - GenericType (ListType, MapType, FuncType)
  ///   - NullableType
  /// </summary>
  public abstract class Type : FanObj, Literal
  {

  //////////////////////////////////////////////////////////////////////////
  // Management
  //////////////////////////////////////////////////////////////////////////

    public static Type find(string sig) { return TypeParser.load(sig, true, null); }
    public static Type find(string sig, Boolean check) { return TypeParser.load(sig, check.booleanValue(), null); }
    public static Type find(string sig, bool check) { return TypeParser.load(sig, check, null); }
    public static Type find(string podName, string typeName, bool check)
    {
      Pod pod = Fan.Sys.Pod.find(podName, check, null);
      if (pod == null) return null;
      return pod.findType(typeName, check);
    }

    public static List findByFacet(string facetName, object facetVal) { return findByFacet(facetName, facetVal, null); }
    public static List findByFacet(string facetName, object facetVal, object options)
    {
      return TypeDb.get().findByFacet(facetName, facetVal, options);
    }

  //////////////////////////////////////////////////////////////////////////
  // Naming
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.TypeType; }

    public abstract Pod pod();
    public abstract string name();
    public abstract string qname();
    public abstract string signature();

  //////////////////////////////////////////////////////////////////////////
  // Flags
  //////////////////////////////////////////////////////////////////////////

    public Boolean isAbstract()  { return Boolean.valueOf(flags() & FConst.Abstract); }
    public Boolean isClass()     { return Boolean.valueOf((flags() & (FConst.Enum|FConst.Mixin)) == 0); }
    public Boolean isConst()     { return Boolean.valueOf(flags() & FConst.Const); }
    public Boolean isEnum()      { return Boolean.valueOf(flags() & FConst.Enum); }
    public Boolean isFinal()     { return Boolean.valueOf(flags() & FConst.Final); }
    public Boolean isInternal()  { return Boolean.valueOf(flags() & FConst.Internal); }
    public Boolean isMixin()     { return Boolean.valueOf(flags() & FConst.Mixin); }
    public Boolean isPublic()    { return Boolean.valueOf(flags() & FConst.Public); }
    public Boolean isSynthetic() { return Boolean.valueOf(flags() & FConst.Synthetic); }
    internal abstract int flags();

  //////////////////////////////////////////////////////////////////////////
  // Dynamic
  //////////////////////////////////////////////////////////////////////////

    public static Type makeDynamic(List supers) { return makeDynamic(supers, null); }
    public static Type makeDynamic(List supers, Map facets)
    {
      ClassType t = new ClassType();
      makeDynamic_(t, supers, facets);
      return t;
    }

    public static void makeDynamic_(Type self, List supers) { makeDynamic_(self, supers, null); }
    public static void makeDynamic_(Type self, List supers, Map facets)
    {
      ClassType t = (ClassType)self;
      if (supers == null || supers.sz() == 0)
        throw ArgErr.make("Must pass in a supers list with at least one type").val;

      // check that first is a class type
      t.m_base = (Type)supers.get(0);
      if (t.m_base.isMixin().booleanValue()) throw ArgErr.make("Not a class: " + t.m_base).val;
      t.m_base.checkOkForDynamic();

      // TODO: we don't support mixins yet
      if (supers.sz() > 1)
        throw ArgErr.make("Sorry - mixins not supported yet").val;

      // check that the rest are mixin types
      List mixins = new List(Sys.TypeType);
      for (int i=1; i<supers.sz(); ++i)
      {
        Type m = (Type)supers.get(i);
        if (!m.isMixin().booleanValue()) throw ArgErr.make("Not mixin: " + m).val;
        m.checkOkForDynamic();
        mixins.add(m);
      }
      t.m_mixins = mixins.ro();

      // facets
      t.m_facets = Facets.make(facets);
    }

    private void checkOkForDynamic()
    {
      if ((flags() & (FConst.Abstract|FConst.Final|FConst.Const)) != 0)
        throw ArgErr.make("Cannot use abstract, final, or const in makeDynamic: " + this).val;
      if (isDynamic().booleanValue())
        throw ArgErr.make("Cannot use dynamic in makeDynamic: " + this).val;
    }

    public virtual Boolean isDynamic() { return Boolean.False; }

  //////////////////////////////////////////////////////////////////////////
  // Nullable
  //////////////////////////////////////////////////////////////////////////

    public virtual Boolean isNullable() { return Boolean.False; }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public virtual Type toNullable()
    {
      if (m_nullable == null) m_nullable = makeToNullable();
      return m_nullable;
    }

    protected virtual Type makeToNullable() { return new NullableType(this); }

  //////////////////////////////////////////////////////////////////////////
  // Generics
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// A generic type means that one or more of my slots contain signatures
    /// using a generic parameter (such as V or K).  Fan supports three built-in
    /// generic types: List, Map, and Method.  A generic instance (such as string[])
    /// is NOT a generic type (all of its generic parameters have been filled in).
    /// User defined generic types are not supported in Fan.
    /// </summary>
    public virtual bool isGenericType()
    {
      return this == Sys.ListType || this == Sys.MapType || this == Sys.FuncType;
    }

    /// <summary>
    /// A generic instance is a type which has "instantiated" a generic type
    /// and replaced all the generic parameter types with generic argument
    /// types.  The type string[] is a generic instance of the generic type
    /// List (V is replaced with string).  A generic instance always has a signature
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
      return pod() == Sys.SysPod && name().Length == 1;
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

    public Boolean isGeneric()
    {
      return isGenericType() ? Boolean.True : Boolean.False;
    }

    public virtual Map @params()
    {
      if (noParams == null)
        noParams = new Map(Sys.StrType, Sys.TypeType).ro();
      return (Map)noParams;
    }

    public virtual Type parameterize(Map pars)
    {
      if (this == Sys.ListType)
      {
        Type v = (Type)pars.get(FanStr.m_ascii['V']);
        if (v == null) throw ArgErr.make("List.parameterize - V undefined").val;
        return v.toListOf();
      }

      if (this == Sys.MapType)
      {
        Type v = (Type)pars.get(FanStr.m_ascii['V']);
        Type k = (Type)pars.get(FanStr.m_ascii['K']);
        if (v == null) throw ArgErr.make("Map.parameterize - V undefined").val;
        if (k == null) throw ArgErr.make("Map.parameterize - K undefined").val;
        return new MapType(k, v);
      }

      if (this == Sys.FuncType)
      {
        Type r = (Type)pars.get(FanStr.m_ascii['R']);
        if (r == null) throw ArgErr.make("Map.parameterize - R undefined").val;
        ArrayList p = new ArrayList();
        for (int i='A'; i<='H'; ++i)
        {
          Type x = (Type)pars.get(FanStr.m_ascii[i]);
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
      if (m_listOf == null) m_listOf = makeToListOf();
      return m_listOf;
    }

    protected virtual Type makeToListOf() { return new ListType(this); }

  //////////////////////////////////////////////////////////////////////////
  // Slots
  //////////////////////////////////////////////////////////////////////////

    public abstract List fields();
    public abstract List methods();
    public abstract List slots();

    public Field field(string name) { return (Field)slot(name, true); }
    public Field field(string name, Boolean check) { return (Field)slot(name, check.booleanValue()); }
    public Field field(string name, bool check) { return (Field)slot(name, check); }

    public Method method(string name) { return (Method)slot(name, true); }
    public Method method(string name, Boolean check) { return (Method)slot(name, check.booleanValue()); }
    public Method method(string name, bool check) { return (Method)slot(name, check); }

    public Slot slot(string name) { return slot(name, true); }
    public Slot slot(string name, Boolean check) { return slot(name, check.booleanValue()); }
    public abstract Slot slot(string name, bool check);

    public virtual void add(Slot slot)
    {
      throw Err.make("Type is not dynamic: " + signature()).val;
    }

    public virtual void remove(Slot slot)
    {
      throw Err.make("Type is not dynamic: " + signature()).val;
    }

    public object make() { return make(null); }
    public virtual object make(List args)
    {
      return method("make", true).call(args);
    }

  //////////////////////////////////////////////////////////////////////////
  // Inheritance
  //////////////////////////////////////////////////////////////////////////

    public abstract Type @base();

    public abstract List mixins();

    public abstract List inheritance();

    public Boolean fits(Type type) { return @is(type) ? Boolean.True : Boolean.False; }
    public abstract bool @is(Type type);

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
          best = best.@base();
          if (best == null) return Sys.ObjType;
        }
      }
      return best;
    }

  //////////////////////////////////////////////////////////////////////////
  // Facets
  //////////////////////////////////////////////////////////////////////////

    public Map facets() { return facets(Boolean.False); }
    public abstract Map facets(Boolean inherited);

    public object facet(string name) { return facet(name, null, Boolean.False); }
    public object facet(string name, object def) { return facet(name, def, Boolean.False); }
    public abstract object facet(string name, object def, Boolean inherited);

  //////////////////////////////////////////////////////////////////////////
  // Documentation
  //////////////////////////////////////////////////////////////////////////

    public abstract string doc();

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public override string toStr() { return signature(); }

    public override Boolean isImmutable() { return Boolean.True; }

    public virtual Type toImmutable() { return this; }

    public void encode(ObjEncoder @out)
    {
      @out.w(signature()).w("#");
    }

  //////////////////////////////////////////////////////////////////////////
  // Util
  //////////////////////////////////////////////////////////////////////////

    public Log log() { return pod().log(); }

    public string loc(string key) { return pod().loc(key); }

    public string loc(string key, string def) { return pod().loc(key, def); }

  //////////////////////////////////////////////////////////////////////////
  // Reflection
  //////////////////////////////////////////////////////////////////////////

    // TODO - needs to be public, since we need to
    // call this from FTypeEmit for now
    public /*protected*/ virtual Type reflect() { return this; }

    public virtual void finish() {}

    public abstract bool netRepr();

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static readonly bool Debug = false;
    internal static object noParams;

    Type m_nullable;   // cached value of toNullable()
    Type m_listOf;     // cached value of toListOf()

  }
}
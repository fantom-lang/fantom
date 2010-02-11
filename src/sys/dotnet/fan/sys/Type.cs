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

    public static Type of(object obj)
    {
      if (obj is FanObj)
        return ((FanObj)obj).@typeof();
      else
        return FanUtil.toFanType(obj.GetType(), true);
    }

    public static Type find(string sig) { return TypeParser.load(sig, true, null); }
    public static Type find(string sig, bool check) { return TypeParser.load(sig, check, null); }

  //////////////////////////////////////////////////////////////////////////
  // Naming
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.TypeType; }

    public abstract Pod pod();
    public abstract string name();
    public abstract string qname();
    public abstract string signature();

  //////////////////////////////////////////////////////////////////////////
  // Flags
  //////////////////////////////////////////////////////////////////////////

    public bool isAbstract()  { return (flags() & FConst.Abstract)  != 0; }
    public bool isClass()     { return (flags() & (FConst.Enum|FConst.Mixin)) == 0; }
    public bool isConst()     { return (flags() & FConst.Const)     != 0; }
    public bool isEnum()      { return (flags() & FConst.Enum)      != 0; }
    public bool isFacet()     { return (flags() & FConst.Facet)     != 0; }
    public bool isFinal()     { return (flags() & FConst.Final)     != 0; }
    public bool isInternal()  { return (flags() & FConst.Internal)  != 0; }
    public bool isMixin()     { return (flags() & FConst.Mixin)     != 0; }
    public bool isPublic()    { return (flags() & FConst.Public)    != 0; }
    public bool isSynthetic() { return (flags() & FConst.Synthetic) != 0; }
    internal abstract int flags();

    public override object trap(string name, List args)
    {
      // private undocumented access
      if (name == "flags") return Long.valueOf(flags());
      return base.trap(name, args);
    }

  //////////////////////////////////////////////////////////////////////////
  // Value Types
  //////////////////////////////////////////////////////////////////////////

    public virtual bool isVal()
    {
      return this == Sys.BoolType || this == Sys.IntType || this == Sys.FloatType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Nullable
  //////////////////////////////////////////////////////////////////////////

    public virtual bool isNullable() { return false; }

    public virtual Type toNonNullable() { return this; }

    public abstract Type toNullable();

  //////////////////////////////////////////////////////////////////////////
  // Generics
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// A generic type means that one or more of my slots contain signatures
    /// using a generic parameter (such as V or K).  Fantom supports three built-in
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
    /// Fantom has a predefined set of generic parameters which are always
    /// defined in the sys pod with a one character name.
    /// </summary>
    public virtual bool isGenericParameter()
    {
      return pod() == Sys.m_sysPod && name().Length == 1;
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

    public bool isGeneric()
    {
      return isGenericType();
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
      if (m_listOf == null) m_listOf = new ListType(this);
      return m_listOf;
    }

    public List emptyList()
    {
      if (m_emptyList == null) m_emptyList = (List)new List(this, 0).toImmutable();
      return m_emptyList;
    }

  //////////////////////////////////////////////////////////////////////////
  // Slots
  //////////////////////////////////////////////////////////////////////////

    public abstract List fields();
    public abstract List methods();
    public abstract List slots();

    public Field field(string name) { return (Field)slot(name, true); }
    public Field field(string name, bool check) { return (Field)slot(name, check); }

    public Method method(string name) { return (Method)slot(name, true); }
    public Method method(string name, bool check) { return (Method)slot(name, check); }

    public Slot slot(string name) { return slot(name, true); }
    public abstract Slot slot(string name, bool check);

    public object make() { return make(null); }
    public virtual object make(List args)
    {
      Method make = method("make", false);
      if (make != null && make.isPublic())
      {
        int numArgs = args == null ? 0 : args.sz();
        List p = make.@params();
        if ((numArgs == p.sz()) ||
            (numArgs < p.sz() && ((Param)p.get(numArgs)).hasDefault()))
          return make.m_func.callList(args);
      }

      Slot defVal = slot("defVal", false);
      if (defVal is Field) return ((Field)defVal).get(null);
      if (defVal is Method) return ((Method)defVal).m_func.callList(null);

      throw Err.make("Type missing 'make' or 'defVal' slots: " + this).val;
   }

  //////////////////////////////////////////////////////////////////////////
  // Inheritance
  //////////////////////////////////////////////////////////////////////////

    public abstract Type @base();

    public abstract List mixins();

    public abstract List inheritance();

    public bool fits(Type type) { return @is(type); }
    public abstract bool @is(Type type);

    /// <summary>
    /// Given a list of objects, compute the most specific type which they all
    /// share,or at worst return sys::Obj.  This method does not take into
    /// account interfaces, only extends class inheritance.
    /// </summary>
    public static Type common(object[] objs, int n)
    {
      if (objs.Length == 0) return Sys.ObjType.toNullable();
      bool nullable = false;
      Type best = null;
      for (int i=0; i<n; ++i)
      {
        object obj = objs[i];
        if (obj == null) { nullable = true; continue; }
        Type t = @typeof(obj);
        if (best == null) { best = t; continue; }
        while (!t.@is(best))
        {
          best = best.@base();
          if (best == null) return nullable ? Sys.ObjType.toNullable() : Sys.ObjType;
        }
      }
      if (best == null) best = Sys.ObjType;
      return nullable ? best.toNullable() : best;
    }

  //////////////////////////////////////////////////////////////////////////
  // Facets
  //////////////////////////////////////////////////////////////////////////

    public abstract List facets();

    public Facet facet(Type t) { return facet(t, true); }
    public abstract Facet facet(Type t, bool c);

    public bool hasFacet(Type t) { return facet(t, false) != null; }

  //////////////////////////////////////////////////////////////////////////
  // Documentation
  //////////////////////////////////////////////////////////////////////////

    public abstract string doc();

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public override string toStr() { return signature(); }

    public string toLocale() { return signature(); }

    public void encode(ObjEncoder @out)
    {
      @out.w(signature()).w("#");
    }

  //////////////////////////////////////////////////////////////////////////
  // Reflection
  //////////////////////////////////////////////////////////////////////////

    // TODO - needs to be public, since we need to
    // call this from FTypeEmit for now
    public /*protected*/ virtual Type reflect() { return this; }

    public virtual void finish() {}

    public abstract bool dotnetRepr();

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static readonly bool Debug = false;
    internal static object noParams;

    Type m_listOf;     // cached value of toListOf()
    List m_emptyList;  // cached value of emptyList()

  }
}
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
 * Type models sys::Type.  Implementation classes are:
 *   - ClassType
 *   - GenericType (ListType, MapType, FuncType)
 *   - NullableType
 */
public abstract class Type
  extends FanObj
  implements Literal
{

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

  public static Type of(Object obj)
  {
    if (obj instanceof FanObj)
      return ((FanObj)obj).typeof();
    else
      return FanUtil.toFanType(obj.getClass(), true);
  }

  public static Type find(String sig) { return TypeParser.load(sig, true, null); }
  public static Type find(String sig, boolean checked) { return TypeParser.load(sig, checked, null); }

//////////////////////////////////////////////////////////////////////////
// Naming
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.TypeType; }

  public String podName() { return pod().name(); }
  public abstract Pod pod();
  public abstract String name();
  public abstract String qname();
  public abstract String signature();

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  public final boolean isAbstract()  { return (flags() & FConst.Abstract) != 0; }
  public final boolean isClass()     { return (flags() & (FConst.Enum|FConst.Mixin)) == 0; }
  public final boolean isConst()     { return (flags() & FConst.Const) != 0; }
  public final boolean isEnum()      { return (flags() & FConst.Enum) != 0; }
  public final boolean isFacet()     { return (flags() & FConst.Facet) != 0; }
  public final boolean isFinal()     { return (flags() & FConst.Final) != 0; }
  public final boolean isInternal()  { return (flags() & FConst.Internal) != 0; }
  public final boolean isMixin()     { return (flags() & FConst.Mixin) != 0; }
  public final boolean isNative()    { return (flags() & FConst.Native) != 0; }
  public final boolean isPublic()    { return (flags() & FConst.Public) != 0; }
  public final boolean isSynthetic() { return (flags() & FConst.Synthetic) != 0; }
  abstract int flags();

  public Object trap(String name, List args)
  {
    // private undocumented access
    if (name.equals("flags")) return Long.valueOf(flags());
    if (name.equals("toClass")) return toClass();
    if (name.equals("finish")) { finish(); return this; }
    return super.trap(name, args);
  }

//////////////////////////////////////////////////////////////////////////
// Value Types
//////////////////////////////////////////////////////////////////////////

  public boolean isVal()
  {
    return this == Sys.BoolType || this == Sys.IntType || this == Sys.FloatType;
  }

//////////////////////////////////////////////////////////////////////////
// Nullable
//////////////////////////////////////////////////////////////////////////

  public boolean isNullable() { return false; }

  public Type toNonNullable() { return this; }

  public abstract Type toNullable();

//////////////////////////////////////////////////////////////////////////
// Generics
//////////////////////////////////////////////////////////////////////////

  /**
   * A generic type means that one or more of my slots contain signatures
   * using a generic parameter (such as V or K).  Fantom supports three built-in
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
   * Fantom has a predefined set of generic parameters which are always
   * defined in the sys pod with a one character name.
   */
  public boolean isGenericParameter()
  {
    return pod() == Sys.sysPod && name().length() == 1;
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

  public final boolean isGeneric()
  {
    return isGenericType();
  }

  public Map params()
  {
    if (noParams == null) noParams = Sys.emptyStrTypeMap;
    return (Map)noParams;
  }

  public Type parameterize(Map params)
  {
    if (this == Sys.ListType)
    {
      Type v = (Type)params.get("V");
      if (v == null) throw ArgErr.make("List.parameterize - V undefined");
      return v.toListOf();
    }

    if (this == Sys.MapType)
    {
      Type v = (Type)params.get("V");
      Type k = (Type)params.get("K");
      if (v == null) throw ArgErr.make("Map.parameterize - V undefined");
      if (k == null) throw ArgErr.make("Map.parameterize - K undefined");
      return new MapType(k, v);
    }

    if (this == Sys.FuncType)
    {
      Type r = (Type)params.get("R");
      if (r == null) throw ArgErr.make("Map.parameterize - R undefined");
      ArrayList p = new ArrayList();
      for (int i='A'; i<='H'; ++i)
      {
        Type x = (Type)params.get(FanStr.ascii[i]);
        if (x == null) break;
        p.add(x);
      }
      return new FuncType((Type[])p.toArray(new Type[p.size()]), r);
    }

    throw UnsupportedErr.make("not generic: " + this);
  }

  public final synchronized Type toListOf()
  {
    if (listOf == null) listOf = new ListType(this);
    return listOf;
  }

  public final List emptyList()
  {
    if (emptyList == null) emptyList = (List)new List(this, 0).toImmutable();
    return emptyList;
  }

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

  public abstract List fields();
  public abstract List methods();
  public abstract List slots();

  public final Field field(String name) { return field(name, true); }
  public Field field(String name, boolean checked) { return (Field)slot(name, checked); }

  public final Method method(String name) { return method(name, true); }
  public Method method(String name, boolean checked) { return (Method)slot(name, checked); }

  public final Slot slot(String name) { return slot(name, true); }
  public abstract Slot slot(String name, boolean checked);

  public final Object make() { return make(null); }
  public Object make(List args)
  {
    Method make = method("make", false);
    if (make != null && make.isPublic())
    {
      int numArgs = args == null ? 0 : args.sz();
      List params = make.params();
      if ((numArgs == params.sz()) ||
          (numArgs < params.sz() && ((Param)params.get(numArgs)).hasDefault()))
        return make.func.callList(args);
    }

    Slot defVal = slot("defVal", false);
    if (defVal != null && defVal.isPublic())
    {
      if (defVal instanceof Field) return ((Field)defVal).get(null);
      if (defVal instanceof Method) return ((Method)defVal).func.callList(null);
    }

    throw Err.make("Type missing 'make' or 'defVal' slots: " + this);
  }

//////////////////////////////////////////////////////////////////////////
// Inheritance
//////////////////////////////////////////////////////////////////////////

  public abstract Type base();

  public abstract List mixins();

  public abstract List inheritance();

  public final boolean fits(Type type) { return toNonNullable().is(type.toNonNullable()); }
  public abstract boolean is(Type type);

  /**
   * Given a list of objects, compute the most specific type which they all
   * share,or at worst return sys::Obj?.  This method does not take into
   * account interfaces, only extends class inheritance.
   */
  public static Type common(Object[] objs, int n)
  {
    if (objs.length == 0) return Sys.ObjType.toNullable();
    boolean nullable = false;
    Type best = null;
    for (int i=0; i<n; ++i)
    {
      Object obj = objs[i];
      if (obj == null) { nullable = true; continue; }
      Type t = typeof(obj);
      if (best == null) { best = t; continue; }
      while (!t.is(best))
      {
        best = best.base();
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

  public final Facet facet(Type t) { return facet(t, true); }
  public abstract Facet facet(Type t, boolean c);

  public final boolean hasFacet(Type t) { return facet(t, false) != null; }

//////////////////////////////////////////////////////////////////////////
// Documentation
//////////////////////////////////////////////////////////////////////////

  public abstract String doc();

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public String toStr() { return signature(); }

  public String toLocale() { return signature(); }

  public void encode(ObjEncoder out)
  {
    out.w(signature()).w("#");
  }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  protected Type reflect() { return this; }

  public void finish() {}

  /**
   * Return if this is a JavaType which represents a Java
   * class imported into the Fantom type system via the Java FFI.
   */
  public final boolean isJava() { return this instanceof JavaType; }

  /**
   * Return if the Fantom Type is represented as a Java class
   * such as sys::Int as java.lang.Long.
   */
  public abstract boolean javaRepr();

  /**
   * Get the Java class which represents this type.
   */
  public abstract Class toClass();

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final boolean Debug = false;
  static Object noParams;

  Type listOf;     // cached value of toListOf()
  List emptyList;  // cached value of emptyList()

}
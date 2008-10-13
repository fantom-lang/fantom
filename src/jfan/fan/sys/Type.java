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
// Naming
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.TypeType; }

  public abstract Pod pod();
  public abstract String name();
  public abstract String qname();
  public abstract String signature();

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  public final Boolean isAbstract() { return (flags() & FConst.Abstract) != 0; }
  public final Boolean isClass() { return (flags() & (FConst.Enum|FConst.Mixin)) == 0; }
  public final Boolean isConst() { return (flags() & FConst.Const) != 0; }
  public final Boolean isEnum() { return (flags() & FConst.Enum) != 0; }
  public final Boolean isFinal() { return (flags() & FConst.Final) != 0; }
  public final Boolean isInternal() { return (flags() & FConst.Internal) != 0; }
  public final Boolean isMixin() { return (flags() & FConst.Mixin) != 0; }
  public final Boolean isPublic() { return (flags() & FConst.Public) != 0; }
  public final Boolean isSynthetic() { return (flags() & FConst.Synthetic) != 0; }
  abstract int flags();

  public Object trap(String name, List args)
  {
    // private undocumented access
    if (name.equals("flags")) return Long.valueOf(flags());
    return super.trap(name, args);
  }

//////////////////////////////////////////////////////////////////////////
// Dynamic
//////////////////////////////////////////////////////////////////////////

  public static Type makeDynamic(List supers) { return makeDynamic(supers, null); }
  public static Type makeDynamic(List supers, Map facets)
  {
    ClassType t = new ClassType();
    makeDynamic$(t, supers, facets);
    return t;
  }

  public static void makeDynamic$(Type self, List supers) { makeDynamic$(self, supers, null); }
  public static void makeDynamic$(Type self, List supers, Map facets)
  {
    ClassType t = (ClassType)self;
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
    if ((flags() & (FConst.Abstract|FConst.Final|FConst.Const)) != 0)
      throw ArgErr.make("Cannot use abstract, final, or const in makeDynamic: " + this).val;
    if (isDynamic())
      throw ArgErr.make("Cannot use dynamic in makeDynamic: " + this).val;
  }

  public Boolean isDynamic() { return false; }

//////////////////////////////////////////////////////////////////////////
// Nullable
//////////////////////////////////////////////////////////////////////////

  public Boolean isNullable() { return false; }

  public Type toNonNullable() { return this; }

  public final synchronized Type toNullable()
  {
    if (nullable == null) nullable = makeToNullable();
    return nullable;
  }

  protected Type makeToNullable() { return new NullableType(this); }

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
    return pod() == Sys.SysPod && name().length() == 1;
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

  public Type parameterize(Map params)
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
    if (listOf == null) listOf = makeToListOf();
    return listOf;
  }

  protected Type makeToListOf() { return new ListType(this); }

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

  public abstract List fields();
  public abstract List methods();
  public abstract List slots();

  public final Field field(String name) { return (Field)slot(name, true); }
  public final Field field(String name, Boolean checked) { return (Field)slot(name, checked.booleanValue()); }
  public final Field field(String name, boolean checked) { return (Field)slot(name, checked); }

  public final Method method(String name) { return (Method)slot(name, true); }
  public final Method method(String name, Boolean checked) { return (Method)slot(name, checked.booleanValue()); }
  public final Method method(String name, boolean checked) { return (Method)slot(name, checked); }

  public final Slot slot(String name) { return slot(name, true); }
  public final Slot slot(String name, Boolean checked) { return slot(name, checked.booleanValue()); }
  public abstract Slot slot(String name, boolean checked);

  public void add(Slot slot)
  {
    throw Err.make("Type is not dynamic: " + signature()).val;
  }

  public void remove(Slot slot)
  {
    throw Err.make("Type is not dynamic: " + signature()).val;
  }

  public final Object make() { return make(null); }
  public Object make(List args)
  {
    return method("make", true).func.call(args);
  }

//////////////////////////////////////////////////////////////////////////
// Inheritance
//////////////////////////////////////////////////////////////////////////

  public abstract Type base();

  public abstract List mixins();

  public abstract List inheritance();

  public final Boolean fits(Type type) { return is(type); }
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
      Type t = type(obj);
      if (best == null) { best = t; continue; }
      while (!t.is(best))
      {
        best = best.base();
        if (best == null) return Sys.ObjType;
      }
    }
    if (best == null) best = Sys.ObjType;
    return nullable ? best.toNullable() : best;
  }

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  public final Map facets() { return facets(false); }
  public abstract Map facets(Boolean inherited);

  public final Object facet(String name) { return facet(name, null, false); }
  public final Object facet(String name, Object def) { return facet(name, def, false); }
  public abstract Object facet(String name, Object def, Boolean inherited);

//////////////////////////////////////////////////////////////////////////
// Documentation
//////////////////////////////////////////////////////////////////////////

  public abstract String doc();

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public String toStr() { return signature(); }

  public Boolean isImmutable() { return true; }

  public Type toImmutable() { return this; }

  public void encode(ObjEncoder out)
  {
    out.w(signature()).w("#");
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public final Log log() { return pod().log(); }

  public final String loc(String key) { return pod().loc(key); }

  public final String loc(String key, String def) { return pod().loc(key, def); }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  protected Type reflect() { return this; }

  public void finish() {}

  public abstract boolean javaRepr();

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final boolean Debug = false;
  static Object noParams;

  Type nullable;   // cached value of toNullable()
  Type listOf;     // cached value of toListOf()

}
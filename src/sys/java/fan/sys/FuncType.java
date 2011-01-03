//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Jan 06  Brian Frank  Creation
//    9 Jul 07  Brian Frank  Rename from MethodFunc
//
package fan.sys;

import java.io.*;
import java.lang.reflect.*;
import java.util.ArrayList;
import java.util.HashMap;
import fanx.fcode.*;
import fanx.emit.*;

/**
 * FuncType is a parameterized type for Funcs
 */
public class FuncType
  extends GenericType
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public FuncType(Type[] params, Type ret)
  {
    super(Sys.FuncType);
    this.params = params;
    this.ret    = ret;

    // I am a generic parameter type if any my args or
    // return type are generic parameter types.
    this.genericParameterType |= ret.isGenericParameter();
    for (int i=0; i<params.length; ++i)
      this.genericParameterType |= params[i].isGenericParameter();
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public long hash()
  {
    return FanStr.hash(signature());
  }

  public boolean equals(Object obj)
  {
    if (obj instanceof FuncType)
    {
      FuncType x = (FuncType)obj;
      if (params.length != x.params.length) return false;
      for (int i=0; i<params.length; ++i)
        if (!params[i].equals(x.params[i])) return false;
      return ret.equals(x.ret);
    }
    return false;
  }

  public final String signature()
  {
    if (sig == null)
    {
      StringBuilder s = new StringBuilder();
      s.append('|');
      for (int i=0; i<params.length; ++i)
      {
        if (i > 0) s.append(',');
        s.append(params[i].signature());
      }
      s.append('-').append('>');
      s.append(ret.signature());
      s.append('|');
      sig = s.toString();
    }
    return sig;
  }

  public boolean is(Type type)
  {
    if (this == type) return true;
    if (type instanceof FuncType)
    {
      FuncType t = (FuncType)type;

      // match return type (if void is needed, anything matches)
      if (t.ret != Sys.VoidType && !ret.is(t.ret)) return false;

      // match params - it is ok for me to have less than
      // the type params (if I want to ignore them), but I
      // must have no more
      if (params.length > t.params.length) return false;
      for (int i=0; i<params.length; ++i)
        if (!t.params[i].is(params[i])) return false;

      // this method works for the specified method type
      return true;
    }
    return base().is(type);
  }


  Map makeParams()
  {
    Map map = new Map(Sys.StrType, Sys.TypeType);
    for (int i=0; i<params.length; ++i)
      map.set(FanStr.ascii['A'+i], params[i]);
    return map.set("R", ret).ro();
  }

  public Class toClass() { return Func.class; }

//////////////////////////////////////////////////////////////////////////
// GenericType
//////////////////////////////////////////////////////////////////////////

  public Type getRawType()
  {
    return Sys.FuncType;
  }

  public boolean isGenericParameter()
  {
    return genericParameterType;
  }

  protected Type doParameterize(Type t)
  {
    // return
    if (t == Sys.RType) return ret;

    // if A-H maps to avail params
    int name = t.name().charAt(0) - 'A';
    if (name < params.length) return params[name];

    // otherwise let anything be used
    return Sys.ObjType;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public final Type[] params;
  public final Type ret;
  private String sig;
  private boolean genericParameterType;
}
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 06  Brian Frank  Creation
//
package fan.sys;

import java.io.*;
import java.lang.reflect.*;
import java.util.ArrayList;
import java.util.HashMap;
import fanx.fcode.*;
import fanx.emit.*;

/**
 * MapType is the GenericType for Maps: Foo:Bar -> K = Foo, V = Bar
 */
public class MapType
  extends GenericType
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public MapType(Type k, Type v)
  {
    super(Sys.MapType);
    this.k = k;
    this.v = v;
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public Int hash()
  {
    return signature().hash();
  }

  public Bool _equals(Object obj)
  {
    if (obj instanceof MapType)
    {
      MapType x = (MapType)obj;
      return Bool.make(k.equals(x.k) && v.equals(x.v));
    }
    return Bool.False;
  }

  public final Type base()
  {
    return Sys.MapType;
  }

  public final Str signature()
  {
    if (sig == null)
    {
      sig = Str.make('[' + k.signature().val + ':' + v.signature().val + ']');
    }
    return sig;
  }

  public boolean is(Type type)
  {
    if (type instanceof MapType)
    {
      MapType t = (MapType)type;
      return k.is(t.k) && v.is(t.v);
    }
    return super.is(type);
  }

  Map makeParams()
  {
    return new Map(Sys.StrType, Sys.TypeType)
      .set(Str.ascii['K'], k)
      .set(Str.ascii['V'], v)
      .set(Str.ascii['M'], this).ro();
  }

//////////////////////////////////////////////////////////////////////////
// GenericType
//////////////////////////////////////////////////////////////////////////

  public Type getRawType()
  {
    return Sys.MapType;
  }

  public boolean isGenericParameter()
  {
    return v.isGenericParameter() && k.isGenericParameter();
  }

  protected Type doParameterize(Type t)
  {
    if (t == Sys.KType) return k;
    if (t == Sys.VType) return v;
    if (t == Sys.MType) return this;
    throw new IllegalStateException(t.toString());
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public final Type k;
  public final Type v;
  private Str sig;

}
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jan 06 (Fri 13th)  Brian Frank  Creation
//
package fan.sys;

import java.io.*;
import java.lang.reflect.*;
import java.util.ArrayList;
import java.util.HashMap;
import fanx.fcode.*;
import fanx.emit.*;

/**
 * ListType is the GenericType for Lists: Foo[] -> V = Foo
 */
public class ListType
  extends GenericType
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ListType(Type v)
  {
    super(Sys.ListType);
    this.v = v;
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public final Int hash()
  {
    return signature().hash();
  }

  public final Bool _equals(Object obj)
  {
    if (obj instanceof ListType)
    {
      return v._equals(((ListType)obj).v);
    }
    return Bool.False;
  }

  public final Type base()
  {
    return Sys.ListType;
  }

  public final Str signature()
  {
    if (sig == null)
    {
      sig = Str.make(v.signature().val + "[]");
    }
    return sig;
  }

  public boolean is(Type type)
  {
    if (type instanceof ListType)
    {
      ListType t = (ListType)type;
      return v.is(t.v);
    }
    return super.is(type);
  }

  Map makeParams()
  {
    return new Map(Sys.StrType, Sys.TypeType)
      .set(Str.ascii['V'], v)
      .set(Str.ascii['L'], this).ro();
  }

//////////////////////////////////////////////////////////////////////////
// GenericType
//////////////////////////////////////////////////////////////////////////

  public Type getRawType()
  {
    return Sys.ListType;
  }

  public boolean isGenericParameter()
  {
    return v.isGenericParameter();
  }

  protected Type doParameterize(Type t)
  {
    if (t == Sys.VType) return v;
    if (t == Sys.LType) return this;
    throw new IllegalStateException(t.toString());
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public final Type v;
  private Str sig;

}
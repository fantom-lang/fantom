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
 * ListType is the GenericType for Lists: Foo[] -&gt; V = Foo
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

  public final long hash()
  {
    return FanStr.hash(signature());
  }

  public final boolean equals(Object obj)
  {
    if (obj instanceof ListType)
    {
      return v.equals(((ListType)obj).v);
    }
    return false;
  }

  public final String signature()
  {
    if (sig == null) sig = v.signature() + "[]";
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
      .set("V", v)
      .set("L", this).ro();
  }

  public Class toClass() { return List.class; }

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
  private String sig;

}
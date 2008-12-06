//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 05  Brian Frank  Creation
//   06 Dec 07  Brian Frank  Rename from FTuple
//
package fanx.fcode;

import java.io.*;
import java.util.*;

/**
 * FFieldRef is used to reference methods for a field access operation.
 * We use FFieldRef to cache and model the mapping from a Fan field to
 * Java field.
 */
public class FFieldRef
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  /**
   * Construct from read.
   */
  private FFieldRef(FTypeRef parent, String name, FTypeRef type)
  {
    this.parent = parent;
    this.name   = name;
    this.type   = type;
  }

//////////////////////////////////////////////////////////////////////////
// Method
//////////////////////////////////////////////////////////////////////////

  /**
   * Return qname
   */
  public String toString()
  {
    return parent + "." + name;
  }

  /**
   * Java assembler signature for this field:
   *   Lfan/foo/Bar.baz:Lfan/sys/Duration;
   */
  public String jsig(boolean mixin)
  {
    if (jsig == null)
    {
      StringBuilder s = new StringBuilder();
      s.append(parent.jimpl());
      if (mixin) s.append('$');
      s.append('.').append(name).append(':');
      type.jsig(s);
      jsig = s.toString();
    }
    return jsig;
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  /**
   * Parse from fcode constant pool format:
   *   fieldRef
   *   {
   *     u2 parent (typeRefs.def)
   *     u2 name   (names.def)
   *     u2 type   (typeRefs.def)
   *   }
   */
  public static FFieldRef read(FStore.Input in) throws IOException
  {
    FPod fpod = in.fpod;
    FTypeRef parent = fpod.typeRef(in.u2());
    String name     = fpod.name(in.u2());
    FTypeRef type   = fpod.typeRef(in.u2());
    return new FFieldRef(parent, name, type);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public final FTypeRef parent;
  public String name;
  public final FTypeRef type;
  private String jsig;

}
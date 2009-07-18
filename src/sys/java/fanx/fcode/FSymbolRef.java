//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 06  Brian Frank  Creation
//
package fanx.fcode;

import java.io.*;
import fan.sys.*;
import fanx.util.*;

/**
 * FSymbolRef stores a symbolRef structure used to reference symbol.
 */
public final class FSymbolRef
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  FSymbolRef(String podName, String symbolName)
  {
    this.podName = podName;
    this.symbolName = symbolName;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public String qname() { return podName + "::" + symbolName; }

  /** Attempt to resolve, if not print error and return null */
  public Symbol resolve()
  {
    try
    {
      return Pod.find(podName).symbol(symbolName);
    }
    catch (Exception e) { e.printStackTrace(); }
    return null;
  }

  public String toString() { return "@" + podName + "::" + symbolName; }

  public static FSymbolRef read(FStore.Input in) throws IOException
  {
    return new FSymbolRef(in.fpod.name(in.u2()), in.fpod.name(in.u2()));
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public final String podName;     // pod name "sys"
  public final String symbolName;  // simple type name "serializable"

}
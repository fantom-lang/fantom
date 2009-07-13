//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 09  Brian Frank  Creation
//
package fanx.fcode;

import java.io.*;

/**
 * FSymbol is the fcode representation of sys::Symbol.
 */
public class FSymbol
  implements FConst
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public FSymbol(FPod pod)
  {
    this.pod = pod;
  }

//////////////////////////////////////////////////////////////////////////
// Meta IO
//////////////////////////////////////////////////////////////////////////

  public FSymbol read(FStore.Input in) throws IOException
  {
    name   = in.u2();
    flags  = in.u4();
    of     = in.u2();
    val    = in.utf();
    attrs  = FAttrs.read(in);
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public FPod pod;        // parent pod
  public int name;        // name index
  public int flags;       // bitmask
  public int of;          // typeRef index
  public String val;      // serialized value
  public FAttrs attrs;    // meta-data attributes

}
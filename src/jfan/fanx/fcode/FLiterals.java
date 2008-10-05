//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Dec 07  Brian Frank  Creation
//
package fanx.fcode;

import java.io.*;
import java.util.*;
import java.util.zip.*;
import fan.sys.*;
import fanx.util.*;

/**
 * FLiterals manages the Int, Float, Duration, Str,
 * and Uri literal constants.
 */
public final class FLiterals
  implements FConst
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public FLiterals(FPod fpod)
  {
    this.fpod = fpod;
    this.ints       = new FTable.Ints(fpod);
    this.floats     = new FTable.Floats(fpod);
    this.decimals   = new FTable.Decimals(fpod);
    this.strs       = new FTable.Strs(fpod);
    this.durations  = new FTable.Durations(fpod);
    this.uris       = new FTable.Uris(fpod);
  }

//////////////////////////////////////////////////////////////////////////
// Read
//////////////////////////////////////////////////////////////////////////

  public FLiterals read() throws IOException
  {
    ints.read(fpod.store.read("ints.def"));
    floats.read(fpod.store.read("floats.def"));
    decimals.read(fpod.store.read("decimals.def"));
    strs.read(fpod.store.read("strs.def"));
    durations.read(fpod.store.read("durations.def"));
    uris.read(fpod.store.read("uris.def"));
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Tables
//////////////////////////////////////////////////////////////////////////

  public final Int integer(int index)       { return (Int)ints.get(index); }
  public final Double floats(int index)     { return (Double)floats.get(index); }
  public final Decimal decimals(int index)  { return (Decimal)decimals.get(index); }
  public final Str str(int index)           { return (Str)strs.get(index); }
  public final Duration duration(int index) { return (Duration)durations.get(index); }
  public final Uri uri(int index)           { return (Uri)uris.get(index); }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public FPod fpod;         // parent pod
  public FTable ints;       // Int literals
  public FTable floats;     // Float literals
  public FTable decimals;   // Decimal literals
  public FTable strs;       // Str literals
  public FTable durations;  // Duration literals
  public FTable uris;       // Uri literals

}

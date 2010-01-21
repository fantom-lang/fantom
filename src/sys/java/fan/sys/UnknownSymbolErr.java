//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 06  Brian Frank  Creation
//
package fan.sys;

/**
 * UnknownSymbolErr
 */
public class UnknownSymbolErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static UnknownSymbolErr make() { return make("", (Err)null); }
  public static UnknownSymbolErr make(String msg) { return make(msg, (Err)null); }
  public static UnknownSymbolErr make(String msg, Err cause)
  {
    UnknownSymbolErr err = new UnknownSymbolErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(UnknownSymbolErr self) { make$(self, null);  }
  public static void make$(UnknownSymbolErr self, String msg) { make$(self, msg, null); }
  public static void make$(UnknownSymbolErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public UnknownSymbolErr(Err.Val val) { super(val); }
  public UnknownSymbolErr() { super(new UnknownSymbolErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.UnknownSymbolErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jun 06  Brian Frank  Creation
//
package fan.sys;

/**
 * CastErr
 */
public class CastErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static CastErr make() { return make("", (Err)null); }
  public static CastErr make(String msg) { return make(msg, (Err)null); }
  public static CastErr make(String msg, Err cause)
  {
    CastErr err = new CastErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(CastErr self) { make$(self, null);  }
  public static void make$(CastErr self, String msg) { make$(self, msg, null); }
  public static void make$(CastErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public CastErr() {}
  public CastErr(Throwable actual) { super(actual); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.CastErrType; }

}
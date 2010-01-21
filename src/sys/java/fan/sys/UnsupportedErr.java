//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//
package fan.sys;

/**
 * UnsupportedErr
 */
public class UnsupportedErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static UnsupportedErr make() { return make("", (Err)null); }
  public static UnsupportedErr make(String msg) { return make(msg, (Err)null); }
  public static UnsupportedErr make(String msg, Err cause)
  {
    UnsupportedErr err = new UnsupportedErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(UnsupportedErr self) { make$(self, null);  }
  public static void make$(UnsupportedErr self, String msg) { make$(self, msg, null); }
  public static void make$(UnsupportedErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public UnsupportedErr(Err.Val val) { super(val); }
  public UnsupportedErr() { super(new UnsupportedErr.Val()); }
  public UnsupportedErr(Throwable actual) { super(new UnsupportedErr.Val(), actual); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof()
  {
    return Sys.UnsupportedErrType;
  }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
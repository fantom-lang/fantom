//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 07  Brian Frank  Creation
//   26 Mar 09  Brian Frank  Renamed from UnknownThreadErr
//
package fan.sys;

/**
 * Cancelled
 */
public class CancelledErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static CancelledErr make() { return make("", (Err)null); }
  public static CancelledErr make(String msg) { return make(msg, (Err)null); }
  public static CancelledErr make(String msg, Err cause)
  {
    CancelledErr err = new CancelledErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(CancelledErr self) { make$(self, null);  }
  public static void make$(CancelledErr self, String msg) { make$(self, msg, null); }
  public static void make$(CancelledErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public CancelledErr(Err.Val val) { super(val); }
  public CancelledErr() { super(new CancelledErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.CancelledErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
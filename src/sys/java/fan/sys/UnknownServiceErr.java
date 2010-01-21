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
 * UnknownServiceErr
 */
public class UnknownServiceErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static UnknownServiceErr make() { return make("", (Err)null); }
  public static UnknownServiceErr make(String msg) { return make(msg, (Err)null); }
  public static UnknownServiceErr make(String msg, Err cause)
  {
    UnknownServiceErr err = new UnknownServiceErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(UnknownServiceErr self) { make$(self, null);  }
  public static void make$(UnknownServiceErr self, String msg) { make$(self, msg, null); }
  public static void make$(UnknownServiceErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public UnknownServiceErr(Err.Val val) { super(val); }
  public UnknownServiceErr() { super(new UnknownServiceErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.UnknownServiceErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
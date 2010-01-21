//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Mar 09  Brian Frank  Creation
//
package fan.sys;

/**
 * TimeoutErr
 */
public class TimeoutErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static TimeoutErr make() { return make("", (Err)null); }
  public static TimeoutErr make(String msg) { return make(msg, (Err)null); }
  public static TimeoutErr make(String msg, Err cause)
  {
    TimeoutErr err = new TimeoutErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(TimeoutErr self) { make$(self, null);  }
  public static void make$(TimeoutErr self, String msg) { make$(self, msg, null); }
  public static void make$(TimeoutErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public TimeoutErr(Err.Val val) { super(val); }
  public TimeoutErr() { super(new TimeoutErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.TimeoutErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
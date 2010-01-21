//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Apr 09  Brian Frank  Creation
//
package fan.sys;

/**
 * ConstErr
 */
public class ConstErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static ConstErr make() { return make("", (Err)null); }
  public static ConstErr make(String msg) { return make(msg, (Err)null); }
  public static ConstErr make(String msg, Err cause)
  {
    ConstErr err = new ConstErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(ConstErr self) { make$(self, null);  }
  public static void make$(ConstErr self, String msg) { make$(self, msg, null); }
  public static void make$(ConstErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public ConstErr(Err.Val val) { super(val); }
  public ConstErr() { super(new ConstErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.ConstErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
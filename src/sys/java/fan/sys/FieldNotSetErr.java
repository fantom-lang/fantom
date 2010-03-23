//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Mar 10  Brian Frank  Creation
//
package fan.sys;

/**
 * FieldNotSetErr
 */
public class FieldNotSetErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static FieldNotSetErr make() { return make("", (Err)null); }
  public static FieldNotSetErr make(String msg) { return make(msg, (Err)null); }
  public static FieldNotSetErr make(String msg, Err cause)
  {
    FieldNotSetErr err = new FieldNotSetErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(FieldNotSetErr self) { make$(self, null);  }
  public static void make$(FieldNotSetErr self, String msg) { make$(self, msg, null); }
  public static void make$(FieldNotSetErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public FieldNotSetErr(Err.Val val) { super(val); }
  public FieldNotSetErr() { super(new FieldNotSetErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.FieldNotSetErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
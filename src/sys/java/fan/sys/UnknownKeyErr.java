//
// Copyright (c) 2012, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Mar 12  Brian Frank  Creation
//
package fan.sys;

/**
 * UnknownKeyErr
 */
public class UnknownKeyErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static UnknownKeyErr make() { return make("", (Err)null); }
  public static UnknownKeyErr make(String msg) { return make(msg, (Err)null); }
  public static UnknownKeyErr make(String msg, Err cause)
  {
    UnknownKeyErr err = new UnknownKeyErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(UnknownKeyErr self) { make$(self, null);  }
  public static void make$(UnknownKeyErr self, String msg) { make$(self, msg, null); }
  public static void make$(UnknownKeyErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public UnknownKeyErr() {}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.UnknownKeyErrType; }

}
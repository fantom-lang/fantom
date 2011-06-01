//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//
package fan.sys;

/**
 * UnknownTypeErr
 */
public class UnknownTypeErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static UnknownTypeErr make() { return make("", (Err)null); }
  public static UnknownTypeErr make(String msg) { return make(msg, (Err)null); }
  public static UnknownTypeErr make(String msg, Err cause)
  {
    UnknownTypeErr err = new UnknownTypeErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(UnknownTypeErr self) { make$(self, null);  }
  public static void make$(UnknownTypeErr self, String msg) { make$(self, msg, null); }
  public static void make$(UnknownTypeErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public UnknownTypeErr() {}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.UnknownTypeErrType; }

}
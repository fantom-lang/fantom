//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//
package fan.sys;

/**
 * UnknownSlotErr
 */
public class UnknownSlotErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static UnknownSlotErr make() { return make("", (Err)null); }
  public static UnknownSlotErr make(String msg) { return make(msg, (Err)null); }
  public static UnknownSlotErr make(String msg, Err cause)
  {
    UnknownSlotErr err = new UnknownSlotErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(UnknownSlotErr self) { make$(self, null);  }
  public static void make$(UnknownSlotErr self, String msg) { make$(self, msg, null); }
  public static void make$(UnknownSlotErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public UnknownSlotErr() {}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.UnknownSlotErrType; }

}
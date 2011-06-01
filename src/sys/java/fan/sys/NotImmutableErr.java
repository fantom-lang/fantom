//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Feb 07  Brian Frank  Creation
//
package fan.sys;

/**
 * NotImmutableErr
 */
public class NotImmutableErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static NotImmutableErr make() { return make("", (Err)null); }
  public static NotImmutableErr make(String msg) { return make(msg, (Err)null); }
  public static NotImmutableErr make(String msg, Err cause)
  {
    NotImmutableErr err = new NotImmutableErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(NotImmutableErr self) { make$(self, null);  }
  public static void make$(NotImmutableErr self, String msg) { make$(self, msg, null); }
  public static void make$(NotImmutableErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public NotImmutableErr() {}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.NotImmutableErrType; }

}
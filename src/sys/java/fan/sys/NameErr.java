//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 07  Brian Frank  Creation
//
package fan.sys;

/**
 * NameErr
 */
public class NameErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static NameErr make() { return make("", (Err)null); }
  public static NameErr make(String msg) { return make(msg, (Err)null); }
  public static NameErr make(String msg, Err cause)
  {
    NameErr err = new NameErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(NameErr self) { make$(self, null);  }
  public static void make$(NameErr self, String msg) { make$(self, msg, null); }
  public static void make$(NameErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public NameErr() {}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.NameErrType; }

}
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//
package fan.sys;

/**
 * NullErr
 */
public class NullErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static NullErr make() { return make("", (Err)null); }
  public static NullErr make(String msg) { return make(msg, (Err)null); }
  public static NullErr make(String msg, Err cause)
  {
    NullErr err = new NullErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(NullErr self) { make$(self, null);  }
  public static void make$(NullErr self, String msg) { make$(self, msg, null); }
  public static void make$(NullErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public static NullErr makeCoerce() { return make("Coerce to non-null", (Err)null); }

  public NullErr() {}
  public NullErr(Throwable actual) { super(actual); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.NullErrType; }

}
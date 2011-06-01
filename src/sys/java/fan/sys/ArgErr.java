//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jun 06  Brian Frank  Creation
//
package fan.sys;

/**
 * ArgErr
 */
public class ArgErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static ArgErr make(long index)   { return make(String.valueOf(index)); }
  public static ArgErr make(Range index) { return make(String.valueOf(index)); }

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static ArgErr make() { return make("", (Err)null); }
  public static ArgErr make(String msg) { return make(msg, (Err)null); }
  public static ArgErr make(String msg, Err cause)
  {
    ArgErr err = new ArgErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(ArgErr self) { make$(self, null);  }
  public static void make$(ArgErr self, String msg) { make$(self, msg, null); }
  public static void make$(ArgErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public ArgErr() {}
  public ArgErr(Throwable actual) { super(actual); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.ArgErrType; }

}
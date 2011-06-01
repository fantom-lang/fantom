//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Jan 06  Brian Frank  Creation
//
package fan.sys;

/**
 * IOErr
 */
public class IOErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static IOErr make(String msg, Throwable cause)  { return make(msg, Err.make(cause)); }

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static IOErr make() { return make("", (Err)null); }
  public static IOErr make(String msg) { return make(msg, (Err)null); }
  public static IOErr make(String msg, Err cause)
  {
    IOErr err = new IOErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(IOErr self) { make$(self, null);  }
  public static void make$(IOErr self, String msg) { make$(self, msg, null); }
  public static void make$(IOErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public IOErr() {}
  public IOErr(Throwable actual) { super(actual); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.IOErrType; }

}
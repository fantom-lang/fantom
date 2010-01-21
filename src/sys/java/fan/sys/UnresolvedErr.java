//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//
package fan.sys;

/**
 * UnresolvedErr
 */
public class UnresolvedErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static UnresolvedErr make(String msg, Throwable cause)  { return make(msg, Err.make(cause)); }
  public static UnresolvedErr make(Uri uri)  { return make(uri.str); }

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static UnresolvedErr make() { return make("", (Err)null); }
  public static UnresolvedErr make(String msg) { return make(msg, (Err)null); }
  public static UnresolvedErr make(String msg, Err cause)
  {
    UnresolvedErr err = new UnresolvedErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(UnresolvedErr self) { make$(self, null);  }
  public static void make$(UnresolvedErr self, String msg) { make$(self, msg, null); }
  public static void make$(UnresolvedErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public UnresolvedErr(Err.Val val) { super(val); }
  public UnresolvedErr() { super(new UnresolvedErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.UnresolvedErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
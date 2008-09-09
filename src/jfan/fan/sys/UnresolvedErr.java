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

  public static UnresolvedErr make(String msg)  { return make(Str.make(msg)); }
  public static UnresolvedErr make(String msg, Throwable cause)  { return make(Str.make(msg), Err.make(cause)); }
  public static UnresolvedErr make(String msg, Err cause)  { return make(Str.make(msg), cause); }
  public static UnresolvedErr make(Uri uri)  { return make(uri.str); }

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static UnresolvedErr make() { return make((Str)null, (Err)null); }
  public static UnresolvedErr make(Str msg) { return make(msg, null); }
  public static UnresolvedErr make(Str msg, Err cause)
  {
    UnresolvedErr err = new UnresolvedErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(UnresolvedErr self) { make$(self, null);  }
  public static void make$(UnresolvedErr self, Str msg) { make$(self, msg, null); }
  public static void make$(UnresolvedErr self, Str msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public UnresolvedErr(Err.Val val) { super(val); }
  public UnresolvedErr() { super(new UnresolvedErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.UnresolvedErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
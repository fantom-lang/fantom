//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//
package fan.sys;

/**
 * UnsupportedErr
 */
public class UnsupportedErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static UnsupportedErr make(String msg)  { return make(Str.make(msg)); }

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static UnsupportedErr make() { return make((Str)null, (Err)null); }
  public static UnsupportedErr make(Str msg) { return make(msg, null); }
  public static UnsupportedErr make(Str msg, Err cause)
  {
    UnsupportedErr err = new UnsupportedErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(UnsupportedErr self) { make$(self, null);  }
  public static void make$(UnsupportedErr self, Str msg) { make$(self, msg, null); }
  public static void make$(UnsupportedErr self, Str msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public UnsupportedErr(Err.Val val) { super(val); }
  public UnsupportedErr() { super(new UnsupportedErr.Val()); }
  public UnsupportedErr(Throwable actual) { super(new UnsupportedErr.Val(), actual); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type()
  {
    return Sys.UnsupportedErrType;
  }

}
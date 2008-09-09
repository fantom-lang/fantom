//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jun 06  Brian Frank  Creation
//
package fan.sys;

/**
 * CastErr
 */
public class CastErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static CastErr make(String msg)  { return make(Str.make(msg)); }

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static CastErr make() { return make((Str)null, (Err)null); }
  public static CastErr make(Str msg) { return make(msg, null); }
  public static CastErr make(Str msg, Err cause)
  {
    CastErr err = new CastErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(CastErr self) { make$(self, null);  }
  public static void make$(CastErr self, Str msg) { make$(self, msg, null); }
  public static void make$(CastErr self, Str msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public CastErr(Err.Val val) { super(val); }
  public CastErr() { super(new CastErr.Val()); }
  public CastErr(Throwable actual) { super(new CastErr.Val(), actual); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.CastErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
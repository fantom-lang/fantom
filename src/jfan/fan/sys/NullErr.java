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
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static NullErr make(String msg)  { return make(Str.make(msg)); }

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static NullErr make() { return make((Str)null, (Err)null); }
  public static NullErr make(Str msg) { return make(msg, null); }
  public static NullErr make(Str msg, Err cause)
  {
    NullErr err = new NullErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(NullErr self) { make$(self, null);  }
  public static void make$(NullErr self, Str msg) { make$(self, msg, null); }
  public static void make$(NullErr self, Str msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public NullErr(Err.Val val) { super(val); }
  public NullErr() { super(new NullErr.Val()); }
  public NullErr(Throwable actual) { super(new NullErr.Val(), actual); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.NullErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
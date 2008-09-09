//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jan 07  Brian Frank  Creation
//
package fan.sys;

/**
 * InterruptedErr
 */
public class InterruptedErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static InterruptedErr make(String msg)  { return make(Str.make(msg)); }

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static InterruptedErr make() { return make((Str)null, (Err)null); }
  public static InterruptedErr make(Str msg) { return make(msg, null); }
  public static InterruptedErr make(Str msg, Err cause)
  {
    InterruptedErr err = new InterruptedErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(InterruptedErr self) { make$(self, null);  }
  public static void make$(InterruptedErr self, Str msg) { make$(self, msg, null); }
  public static void make$(InterruptedErr self, Str msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public InterruptedErr(Err.Val val) { super(val); }
  public InterruptedErr() { super(new InterruptedErr.Val()); }
  public InterruptedErr(Throwable actual) { super(new InterruptedErr.Val(), actual); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.InterruptedErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
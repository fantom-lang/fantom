//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 07  Brian Frank  Creation
//
package fan.sys;

/**
 * UnknownThreadErr
 */
public class UnknownThreadErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static UnknownThreadErr make(String msg)  { return make(Str.make(msg)); }

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static UnknownThreadErr make() { return make((Str)null, (Err)null); }
  public static UnknownThreadErr make(Str msg) { return make(msg, null); }
  public static UnknownThreadErr make(Str msg, Err cause)
  {
    UnknownThreadErr err = new UnknownThreadErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(UnknownThreadErr self) { make$(self, null);  }
  public static void make$(UnknownThreadErr self, Str msg) { make$(self, msg, null); }
  public static void make$(UnknownThreadErr self, Str msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public UnknownThreadErr(Err.Val val) { super(val); }
  public UnknownThreadErr() { super(new UnknownThreadErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.UnknownThreadErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
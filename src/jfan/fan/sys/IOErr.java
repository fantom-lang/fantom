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

  public static IOErr make(String msg)  { return make(Str.make(msg)); }
  public static IOErr make(String msg, Throwable cause)  { return make(Str.make(msg), Err.make(cause)); }

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static IOErr make() { return make((Str)null, (Err)null); }
  public static IOErr make(Str msg) { return make(msg, null); }
  public static IOErr make(Str msg, Err cause)
  {
    IOErr err = new IOErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(IOErr self) { make$(self, null);  }
  public static void make$(IOErr self, Str msg) { make$(self, msg, null); }
  public static void make$(IOErr self, Str msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public IOErr(Err.Val val) { super(val); }
  public IOErr() { super(new IOErr.Val()); }
  public IOErr(Throwable actual) { super(new IOErr.Val(), actual); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.IOErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
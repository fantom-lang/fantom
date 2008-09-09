//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//
package fan.sys;

/**
 * UnknownTypeErr
 */
public class UnknownTypeErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static UnknownTypeErr make(String msg)  { return make(Str.make(msg)); }

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static UnknownTypeErr make() { return make((Str)null, (Err)null); }
  public static UnknownTypeErr make(Str msg) { return make(msg, null); }
  public static UnknownTypeErr make(Str msg, Err cause)
  {
    UnknownTypeErr err = new UnknownTypeErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(UnknownTypeErr self) { make$(self, null);  }
  public static void make$(UnknownTypeErr self, Str msg) { make$(self, msg, null); }
  public static void make$(UnknownTypeErr self, Str msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public UnknownTypeErr(Err.Val val) { super(val); }
  public UnknownTypeErr() { super(new UnknownTypeErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.UnknownTypeErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
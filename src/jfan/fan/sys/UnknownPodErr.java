//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//
package fan.sys;

/**
 * UnknownPodErr
 */
public class UnknownPodErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static UnknownPodErr make(String msg)  { return make(Str.make(msg)); }

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static UnknownPodErr make() { return make((Str)null, (Err)null); }
  public static UnknownPodErr make(Str msg) { return make(msg, null); }
  public static UnknownPodErr make(Str msg, Err cause)
  {
    UnknownPodErr err = new UnknownPodErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(UnknownPodErr self) { make$(self, null);  }
  public static void make$(UnknownPodErr self, Str msg) { make$(self, msg, null); }
  public static void make$(UnknownPodErr self, Str msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public UnknownPodErr(Err.Val val) { super(val); }
  public UnknownPodErr() { super(new UnknownPodErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.UnknownPodErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
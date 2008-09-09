//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Feb 07  Brian Frank  Creation
//
package fan.sys;

/**
 * NotImmutableErr
 */
public class NotImmutableErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static NotImmutableErr make(String msg)  { return make(Str.make(msg)); }

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static NotImmutableErr make() { return make((Str)null, (Err)null); }
  public static NotImmutableErr make(Str msg) { return make(msg, null); }
  public static NotImmutableErr make(Str msg, Err cause)
  {
    NotImmutableErr err = new NotImmutableErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(NotImmutableErr self) { make$(self, null);  }
  public static void make$(NotImmutableErr self, Str msg) { make$(self, msg, null); }
  public static void make$(NotImmutableErr self, Str msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public NotImmutableErr(Err.Val val) { super(val); }
  public NotImmutableErr() { super(new NotImmutableErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.NotImmutableErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
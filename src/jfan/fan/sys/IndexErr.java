//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jan 06  Brian Frank  Creation
//
package fan.sys;

/**
 * IndexErr
 */
public class IndexErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static IndexErr make(String msg)  { return make(Str.make(msg)); }
  public static IndexErr make(Long index)   { return make(Str.make(String.valueOf(index))); }
  public static IndexErr make(Range index) { return make(Str.make(String.valueOf(index))); }

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static IndexErr make() { return make((Str)null, (Err)null); }
  public static IndexErr make(Str msg) { return make(msg, null); }
  public static IndexErr make(Str msg, Err cause)
  {
    IndexErr err = new IndexErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(IndexErr self) { make$(self, null);  }
  public static void make$(IndexErr self, Str msg) { make$(self, msg, null); }
  public static void make$(IndexErr self, Str msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public IndexErr(Err.Val val) { super(val); }
  public IndexErr() { super(new IndexErr.Val()); }
  public IndexErr(Throwable actual) { super(new IndexErr.Val(), actual); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.IndexErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}

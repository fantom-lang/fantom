//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   7 Apr 06  Brian Frank  Creation
//
package fan.sys;

/**
 * ReadonlyErr
 */
public class ReadonlyErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static ReadonlyErr make(String msg)  { return make(Str.make(msg)); }

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static ReadonlyErr make() { return make((Str)null, (Err)null); }
  public static ReadonlyErr make(Str msg) { return make(msg, null); }
  public static ReadonlyErr make(Str msg, Err cause)
  {
    ReadonlyErr err = new ReadonlyErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(ReadonlyErr self) { make$(self, null);  }
  public static void make$(ReadonlyErr self, Str msg) { make$(self, msg, null); }
  public static void make$(ReadonlyErr self, Str msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public ReadonlyErr(Err.Val val) { super(val); }
  public ReadonlyErr() { super(new ReadonlyErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.ReadonlyErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
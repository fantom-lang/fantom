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
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static ReadonlyErr make() { return make((String)null, (Err)null); }
  public static ReadonlyErr make(String msg) { return make(msg, (Err)null); }
  public static ReadonlyErr make(String msg, Err cause)
  {
    ReadonlyErr err = new ReadonlyErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(ReadonlyErr self) { make$(self, null);  }
  public static void make$(ReadonlyErr self, String msg) { make$(self, msg, null); }
  public static void make$(ReadonlyErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

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

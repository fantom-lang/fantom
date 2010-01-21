//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Aug 07  Brian Frank  Creation
//
package fan.sys;

/**
 * ParseErr
 */
public class ParseErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static ParseErr make(String type, String val)
  {
    return make("Invalid " + type + ": '" + val + "'");
  }

  public static ParseErr make(String type, String val, Object more)
  {
    return make("Invalid " + type + ": '" + val + "': " + more);
  }

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static ParseErr make() { return make("", (Err)null); }
  public static ParseErr make(String msg) { return make(msg, (Err)null); }
  public static ParseErr make(String msg, Err cause)
  {
    ParseErr err = new ParseErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(ParseErr self) { make$(self, null);  }
  public static void make$(ParseErr self, String msg) { make$(self, msg, null); }
  public static void make$(ParseErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public ParseErr(Err.Val val) { super(val); }
  public ParseErr() { super(new ParseErr.Val()); }
  public ParseErr(Throwable actual) { super(new ParseErr.Val(), actual); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.ParseErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}
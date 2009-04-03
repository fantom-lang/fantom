//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Mar 08  Brian Frank  Creation
//
package fan.sys;

/**
 * TestErr
 */
public class TestErr
  extends Err
{

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static TestErr make() { return make((String)null, (Err)null); }
  public static TestErr make(String msg) { return make(msg, (Err)null); }
  public static TestErr make(String msg, Err cause)
  {
    TestErr err = new TestErr();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(TestErr self) { make$(self, null);  }
  public static void make$(TestErr self, String msg) { make$(self, msg, null); }
  public static void make$(TestErr self, String msg, Err cause) { Err.make$(self, msg, cause); }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  public TestErr(Err.Val val) { super(val); }
  public TestErr() { super(new TestErr.Val()); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.TestErrType; }

//////////////////////////////////////////////////////////////////////////
// Val - Java Exception Type
//////////////////////////////////////////////////////////////////////////

  public static class Val extends Err.Val {}

}

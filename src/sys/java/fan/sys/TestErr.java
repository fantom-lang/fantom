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
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static TestErr make() { return make("", (Err)null); }
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

  public TestErr() {}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.TestErrType; }

}
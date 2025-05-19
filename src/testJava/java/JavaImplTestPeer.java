//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 May 25  Brian Frank  Creation
//
package fan.testJava;

public class JavaImplTestPeer
{
  public static JavaImplTestPeer make(JavaImplTest self)
  {
    return new JavaImplTestPeer();
  }

  public void test(JavaImplTest self)
  {
    Test.test("");
  }
}


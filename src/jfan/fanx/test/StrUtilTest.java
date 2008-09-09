//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//
package fanx.test;

import fanx.util.*;

/**
 * StrUtilTest
 */
public class StrUtilTest
  extends Test
{

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  public void run()
    throws Exception
  {
    verifyGetSpaces();
    verifyPad();
  }

//////////////////////////////////////////////////////////////////////////
// getSpaces
//////////////////////////////////////////////////////////////////////////

  public void verifyGetSpaces()
  {
    String x = "";
    for (int i=0; i<100; ++i)
    {
      verify(StrUtil.getSpaces(i).equals(x));
      x += " ";
    }
    verify(StrUtil.getSpaces(0)    == StrUtil.getSpaces(0));
    verify(StrUtil.getSpaces(4)    == StrUtil.getSpaces(4));
    verify(StrUtil.getSpaces(10)   == StrUtil.getSpaces(10));
    verify(StrUtil.getSpaces(1000) != StrUtil.getSpaces(1000));
  }


//////////////////////////////////////////////////////////////////////////
// pad
//////////////////////////////////////////////////////////////////////////

  public void verifyPad()
  {
    verify(StrUtil.padl("x", 0).equals("x"));
    verify(StrUtil.padl("x", 1).equals("x"));
    verify(StrUtil.padl("x", 2).equals(" x"));
    verify(StrUtil.padl("x", 3).equals("  x"));
    verify(StrUtil.padl("x", 4).equals("   x"));

    verify(StrUtil.padr("x", 0).equals("x"));
    verify(StrUtil.padr("x", 1).equals("x"));
    verify(StrUtil.padr("x", 2).equals("x "));
    verify(StrUtil.padr("x", 3).equals("x  "));
    verify(StrUtil.padr("x", 4).equals("x   "));
  }

}
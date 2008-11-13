//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using Fan.Sys;
using Fanx.Util;

namespace Fanx.Test
{
  /// <summary>
  /// UtilTest.
  /// </summary>
  public class UtilTest : Test
  {
    public override void Run()
    {
      verifyUpper();
      verifyGetPodName();
      verifySplitQName();
    }

    public void verifyUpper()
    {
      verify(FanUtil.upper("foo"), "Foo");
      verify(FanUtil.upper("Foo"), "Foo");
      verify(FanUtil.upper("fooBar"), "FooBar");
      verify(FanUtil.upper("FooBar"), "FooBar");
      verify(FanUtil.upper("alpha.beta.gamma"), "Alpha.Beta.Gamma");
      verify(FanUtil.upper("Alpha.Beta.gamma"), "Alpha.Beta.Gamma");
      verify(FanUtil.upper("Alpha.beta.Gamma"), "Alpha.Beta.Gamma");
      verify(FanUtil.upper("alpha.Beta.Gamma"), "Alpha.Beta.Gamma");
    }

    public void verifyGetPodName()
    {
      verify(FanUtil.getPodName("Fan.Sys.Foo"),         "sys");
      verify(FanUtil.getPodName("Fan.Sys.Foo.Bar"),     "sys");
      verify(FanUtil.getPodName("Fan.Sys.Foo.Bar.Car"), "sys");
      verify(FanUtil.getPodName("Fan.Sys.Foo/Val"),     "sys");
      verify(FanUtil.getPodName("Fan.SysTest.Foo"),     "sysTest");

      verifyFail(FanUtil.getPodName("Fan.Sys"),     "sys");
      verifyFail(FanUtil.getPodName("Fan.Sys.Foo"), "Sys");
      verifyFail(FanUtil.getPodName("Fan.Sys.Foo"), "andy");
    }

    private void verifyFail(string a, string b)
    {
      if (a == b) Fail();
    }

    public void verifySplitQName()
    {
      verifyQName(FanUtil.splitQName("Fan"), null, "Fan");
      verifyQName(FanUtil.splitQName("Fan.Sys"), "Fan", "Sys");
      verifyQName(FanUtil.splitQName("Fan.Sys.Boolean"), "Fan.Sys", "Boolean");
      verifyQName(FanUtil.splitQName("Fan.Sys.Boolean.Foo"), "Fan.Sys.Boolean", "Foo");
      verifyQName(FanUtil.splitQName("Fan.Sys.Foo/Val"),  "Fan.Sys.Foo", "Val");
      verifyQName(FanUtil.splitQName("Fan.Sys.Foo<Bar>"), "Fan.Sys.Foo", "Bar");
    }

    private void verifyQName(string[] a, string b, string c)
    {
      verify(a.Length == 2);
      verify(a[0] == b);
      verify(a[1] == c);
    }
  }
}
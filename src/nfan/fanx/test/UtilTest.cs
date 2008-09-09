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
      verify(NameUtil.upper("foo"), "Foo");
      verify(NameUtil.upper("Foo"), "Foo");
      verify(NameUtil.upper("fooBar"), "FooBar");
      verify(NameUtil.upper("FooBar"), "FooBar");
      verify(NameUtil.upper("alpha.beta.gamma"), "Alpha.Beta.Gamma");
      verify(NameUtil.upper("Alpha.Beta.gamma"), "Alpha.Beta.Gamma");
      verify(NameUtil.upper("Alpha.beta.Gamma"), "Alpha.Beta.Gamma");
      verify(NameUtil.upper("alpha.Beta.Gamma"), "Alpha.Beta.Gamma");
    }

    public void verifyGetPodName()
    {
      verify(NameUtil.getPodName("Fan.Sys.Foo"),         "sys");
      verify(NameUtil.getPodName("Fan.Sys.Foo.Bar"),     "sys");
      verify(NameUtil.getPodName("Fan.Sys.Foo.Bar.Car"), "sys");
      verify(NameUtil.getPodName("Fan.Sys.Foo/Val"),     "sys");
      verify(NameUtil.getPodName("Fan.SysTest.Foo"),     "sysTest");

      verifyFail(NameUtil.getPodName("Fan.Sys"),     "sys");
      verifyFail(NameUtil.getPodName("Fan.Sys.Foo"), "Sys");
      verifyFail(NameUtil.getPodName("Fan.Sys.Foo"), "andy");
    }

    private void verifyFail(string a, string b)
    {
      if (a == b) Fail();
    }

    public void verifySplitQName()
    {
      verifyQName(NameUtil.splitQName("Fan"), null, "Fan");
      verifyQName(NameUtil.splitQName("Fan.Sys"), "Fan", "Sys");
      verifyQName(NameUtil.splitQName("Fan.Sys.Bool"), "Fan.Sys", "Bool");
      verifyQName(NameUtil.splitQName("Fan.Sys.Bool.Foo"), "Fan.Sys.Bool", "Foo");
      verifyQName(NameUtil.splitQName("Fan.Sys.Bool.Foo/Val"), "Fan.Sys.Bool.Foo", "Val");
    }

    private void verifyQName(string[] a, string b, string c)
    {
      verify(a.Length == 2);
      verify(a[0] == b);
      verify(a[1] == c);
    }
  }
}
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Dec 06  Andy Frank  Creation
//

using System.Reflection;
using Fan.Sys;

namespace Fanx.Test
{
  /// <summary>
  /// ParamTeset.
  /// </summary>
  public class ParamTest : CompileTest
  {

  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    public override void Run()
    {
      verifyStatic();
      verifyInstance();
      verifyCtor();
      verifyStaticCall();
      verifyInstanceCall();
      verifyCtorCall();
    }

  //////////////////////////////////////////////////////////////////////////
  // Static
  //////////////////////////////////////////////////////////////////////////

    string _static  =
      "class Foo\n" +
      "{\n" +
      "  static Long f(Long a := 3) { return a }\n" +
      "  static Long g(Long a := 1, Long b := 2) { return a+b }\n" +
      "  static Long h(Long a,Long b:= 2,Long c:=3, Long d:=4, Long e:=5, Long f:=6) { return a+b+c+d+e+f }\n" +
      "}\n";

    public void verifyStatic()
    {
      System.Type type = CompileToType(_static);
      object o;

      o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] {});
        verify(o, Long.valueOf(3));
      o = type.InvokeMember("F", GetStaticFlags(), null, null, MakeInts(-2));
        verify(o, Long.valueOf(-2));

      o = type.InvokeMember("G", GetStaticFlags(), null, null, new object[] {});
        verify(o, Long.valueOf(3));
      o = type.InvokeMember("G", GetStaticFlags(), null, null, MakeInts(5));
        verify(o, Long.valueOf(7));
      o = type.InvokeMember("G", GetStaticFlags(), null, null, MakeInts(-1, -2));
        verify(o, Long.valueOf(-3));

      o = type.InvokeMember("H", GetStaticFlags(), null, null, MakeInts(0));
        verify(o, Long.valueOf(20));
      o = type.InvokeMember("H", GetStaticFlags(), null, null, MakeInts(0, 0));
        verify(o, Long.valueOf(18));
      o = type.InvokeMember("H", GetStaticFlags(), null, null, MakeInts(0, 0, 0));
        verify(o, Long.valueOf(15));
      o = type.InvokeMember("H", GetStaticFlags(), null, null, MakeInts(0, 0, 0, 0));
        verify(o, Long.valueOf(11));
      o = type.InvokeMember("H", GetStaticFlags(), null, null, MakeInts(0, 0, 0, 0, 0));
        verify(o, Long.valueOf(6));
      o = type.InvokeMember("H", GetStaticFlags(), null, null, MakeInts(0, 0, 0, 0, 0, 0));
        verify(o, Long.valueOf(0));
    }

  //////////////////////////////////////////////////////////////////////////
  // Instance
  //////////////////////////////////////////////////////////////////////////

    string instance =
      "class Foo\n" +
      "{\n" +
      "  Long f(Long a := 3) { return a }\n" +
      "  Long g(Long a := 1, Long b := 2) { return a+b }\n" +
      "  Long h(Long a,Long b:= 2,Long c:=3, Long d:=4, Long e:=5, Long f:=6) { return a+b+c+d+e+f }\n" +
      "}\n";

    public void verifyInstance()
    {
      System.Type type = CompileToType(instance);
      object x = type.InvokeMember("Make", GetStaticFlags(), null, null, new object[0]);
      object o;

      verify(InvokeInstance(type, x, "F"), Long.valueOf(3));
      verify(InvokeInstance(type, x, "F", MakeInts(-2)), Long.valueOf(-2));

      verify(InvokeInstance(type, x, "G"), Long.valueOf(3));
      verify(InvokeInstance(type, x, "G", MakeInts(5)), Long.valueOf(7));
      verify(InvokeInstance(type, x, "G", MakeInts(-1,-2)), Long.valueOf(-3));

      o = type.InvokeMember("H", GetInstanceFlags(), null, x, MakeInts(0));
        verify(o, Long.valueOf(20));
      o = type.InvokeMember("H", GetInstanceFlags(), null, x, MakeInts(0,0));
        verify(o, Long.valueOf(18));
      o = type.InvokeMember("H", GetInstanceFlags(), null, x, MakeInts(0,0,0));
        verify(o, Long.valueOf(15));
      o = type.InvokeMember("H", GetInstanceFlags(), null, x, MakeInts(0,0,0,0));
        verify(o, Long.valueOf(11));
      o = type.InvokeMember("H", GetInstanceFlags(), null, x, MakeInts(0,0,0,0,0));
        verify(o, Long.valueOf(6));
      o = type.InvokeMember("H", GetInstanceFlags(), null, x, MakeInts(0,0,0,0,0,0));
        verify(o, Long.valueOf(0));
    }

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    string ctor =
      "class Foo\n" +
      "{\n" +
      "  new f(Long a := 3) { x = a }\n" +
      "  new g(Long a := 1, Long b := 2) { x = a+b }\n" +
      "  new h(Long a,Long b:= 2,Long c:=3, Long d:=4, Long e:=5, Long f:=6) { x = a+b+c+d+e+f }\n" +
      "  Long x\n" +
      "}\n";

    public void verifyCtor()
    {
      System.Type type = CompileToType(ctor);
      object o;

      o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] {});
        verify(Get(o, "x"), Long.valueOf(3));
      o = type.InvokeMember("F", GetStaticFlags(), null, null, MakeInts(-2));
        verify(Get(o, "x"), Long.valueOf(-2));

      o = type.InvokeMember("G", GetStaticFlags(), null, null, new object[] {});
        verify(Get(o, "x"), Long.valueOf(3));
      o = type.InvokeMember("G", GetStaticFlags(), null, null, MakeInts(5));
        verify(Get(o, "x"), Long.valueOf(7));
      o = type.InvokeMember("G", GetStaticFlags(), null, null, MakeInts(-1, -2));
        verify(Get(o, "x"), Long.valueOf(-3));

      o = type.InvokeMember("H", GetStaticFlags(), null, null, MakeInts(0));
        verify(Get(o, "x"), Long.valueOf(20));
      o = type.InvokeMember("H", GetStaticFlags(), null, null, MakeInts(0,0));
        verify(Get(o, "x"), Long.valueOf(18));
      o = type.InvokeMember("H", GetStaticFlags(), null, null, MakeInts(0,0,0));
        verify(Get(o, "x"), Long.valueOf(15));
      o = type.InvokeMember("H", GetStaticFlags(), null, null, MakeInts(0,0,0,0));
        verify(Get(o, "x"), Long.valueOf(11));
      o = type.InvokeMember("H", GetStaticFlags(), null, null, MakeInts(0,0,0,0,0));
        verify(Get(o, "x"), Long.valueOf(6));
      o = type.InvokeMember("H", GetStaticFlags(), null, null, MakeInts(0,0,0,0,0,0));
        verify(Get(o, "x"), Long.valueOf(0));
    }

  //////////////////////////////////////////////////////////////////////////
  // Static Call
  //////////////////////////////////////////////////////////////////////////

    string staticCall  =
      "class Foo\n" +
      "{\n" +
      "  static Long f(Long a := 3) { return a }\n" +
      "  static Long c0() { return f() }\n" +
      "  static Long c1(Long a) { return f(a) }\n" +
      "}\n";

    public void verifyStaticCall()
    {
      System.Type type = CompileToType(staticCall);
      object o;

      o = type.InvokeMember("C0", GetStaticFlags(), null, null, new object[] {});
        verify(o, Long.valueOf(3));
      o = type.InvokeMember("C1", GetStaticFlags(), null, null, MakeInts(-2));
        verify(o, Long.valueOf(-2));
    }

  //////////////////////////////////////////////////////////////////////////
  // Instance Call
  //////////////////////////////////////////////////////////////////////////

    string instanceCall  =
      "class Foo\n" +
      "{\n" +
      "  Long f(Long a, Long b := 3) { return a+b }\n" +
      "  Long c0(Long a) { return f(a) }\n" +
      "  Long c1(Long a, Long b) { return f(a, b) }\n" +
      "}\n";

    public void verifyInstanceCall()
    {
      System.Type type = CompileToType(instanceCall);
      object x = type.InvokeMember("Make", GetStaticFlags(), null, null, new object[0]);
      object o;

      o = type.InvokeMember("C0", GetInstanceFlags(), null, x, MakeInts(-1));
        verify(o, Long.valueOf(2));
      o = type.InvokeMember("C1", GetInstanceFlags(), null, x, MakeInts(6, 7));
        verify(o, Long.valueOf(13));
    }

  //////////////////////////////////////////////////////////////////////////
  // Ctor Call
  //////////////////////////////////////////////////////////////////////////

    string ctorCall  =
      "class Foo\n" +
      "{\n" +
// TODO - Fix for case when make() comes after c0 and c1 in the code
      "  private new make(Long x := 0) { this.x = x }\n" +
      "  static Foo c0() { return make() }\n" +
      "  static Foo c1(Long x) { return make(x) }\n" +
      "  Long x\n" +
      "}\n";

    public void verifyCtorCall()
    {
      System.Type type = CompileToType(ctorCall);
      object o;

      o = type.InvokeMember("C0", GetStaticFlags(), null, null, new object[] {});
        verify(Get(o, "x"), Long.valueOf(0));
      o = type.InvokeMember("C1", GetStaticFlags(), null, null, MakeInts(77));
        verify(Get(o, "x"), Long.valueOf(77));
    }

  //////////////////////////////////////////////////////////////////////////
  // TODO
  //////////////////////////////////////////////////////////////////////////

    // TODO - error checking such as: static Void f(Foo a := this)

  }
}

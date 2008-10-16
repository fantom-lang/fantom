//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Nov 06  Andy Frank  Creation
//

using Fan.Sys;

namespace Fanx.Test
{
  /// <summary>
  /// TryTest
  /// </summary>
  public class TryTest : CompileTest
  {

  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    public override void Run()
    {
      verifyFinally();
      verifyPeerFinally();
      verifyCatch();
      verifyCatchAll();
      verifyCatchAndCatchAll();
      verifyNested();
      verifyTryFinally1();
      verifyTryFinally2();
      verifyTryFinally3();
      verifyTryFinally4();
      verifyTryFinally5();
      verifyTryFinally6();
      verifyTryFinally7();
      verifyTryFinally8();
      verifyTryCatchFinally1();
      verifyTryCatchFinally2();
      verifyTryCatchFinally3();
      verifyTryCatchFinally4();
      //verifyTryCatchFinally5();
      //FuckMe();
    }

  //////////////////////////////////////////////////////////////////////////
  // Finally
  //////////////////////////////////////////////////////////////////////////

    private void verifyFinally()
    {
      string src =
        "class Foo\n" +
        "{\n" +
        "  static Int[] f(Int[] r, Int a)\n" +
        "  {\n" +
        "    r.add(0)\n" +
        "    try\n" +
        "    {\n" +
        "      r.add(a+1)\n" +
        "    }\n" +
        "    finally\n" +
        "    {\n" +
        "      r.add(99)\n" +
        "    }\n" +
        "    return r\n" +
        "  }\n" +
        "}";

      List r = new List(Sys.IntType, new object[] { Int.make(0), Int.make(3), Int.make(99) });
      System.Type type = CompileToType(src);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, Int.make(2) });

      List c = (List)o;
      verify(c.get(0) == Int.make(0));
      verify(c.get(1) == Int.make(3));
      verify(c.get(2) == Int.make(99));
    }

  //////////////////////////////////////////////////////////////////////////
  // PeerFinally
  //////////////////////////////////////////////////////////////////////////

    private void verifyPeerFinally()
    {
      string src =
        "class Foo\n" +
        "{\n" +
        "  static Int[] f(Int[] r, Int a)\n" +
        "  {\n" +
        "    r.add(0)\n" +
        "    try\n" +
        "    {\n" +
        "      r.add(a+1)\n" +
        "    }\n" +
        "    finally\n" +
        "    {\n" +
        "      r.add(99)\n" +
        "    }\n" +
        "    try\n" +
        "    {\n" +
        "      r.add(a+2)\n" +
        "    }\n" +
        "    finally\n" +
        "    {\n" +
        "      r.add(100)\n" +
        "    }\n" +
        "    return r\n" +
        "  }\n" +
        "}";

      List r = new List(Sys.IntType, new object[] {});
      System.Type type = CompileToType(src);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, Int.make(2) });

      verify(r == o);
      verify(r.get(0).Equals(Int.make(0)));
      verify(r.get(1).Equals(Int.make(3)));
      verify(r.get(2).Equals(Int.make(99)));
      verify(r.get(3).Equals(Int.make(4)));
      verify(r.get(4).Equals(Int.make(100)));
    }

  //////////////////////////////////////////////////////////////////////////
  // Catch
  //////////////////////////////////////////////////////////////////////////

    void verifyCatch()
    {
      string src =
        "class Foo\n" +
        "{\n" +
        "  static Int f(Int a)\n" +
        "  {\n" +
        "    try\n" +
        "    {\n" +
        "      a += 1\n" +
        "      throw Err.make()\n" +
        "    }\n" +
        "    catch (Err err)\n" +
        "    {\n" +
        "      a += 2\n" +
        "    }\n" +
        "    return a\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { Int.make(5) });
      verify(o.Equals(Int.make(8)));
    }

  //////////////////////////////////////////////////////////////////////////
  // CatchAll
  //////////////////////////////////////////////////////////////////////////

    void verifyCatchAll()
    {
      string src =
        "class Foo\n" +
        "{\n" +
        "  static Int f(Int a)\n" +
        "  {\n" +
        "    try\n" +
        "    {\n" +
        "      a += 2\n" +
        "      throw Err.make()\n" +
        "    }\n" +
        "    catch\n" +
        "    {\n" +
        "      a += 1\n" +
        "    }\n" +
        "    return a\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { Int.make(3) });
      verify(o.Equals(Int.make(6)));
    }

  //////////////////////////////////////////////////////////////////////////
  // CatchAndCatchAll
  //////////////////////////////////////////////////////////////////////////

    void verifyCatchAndCatchAll()
    {
      string src =
        "class Foo\n" +
        "{\n" +
        "  static Int f(Int a, Err err)\n" +
        "  {\n" +
        "    try\n" +
        "    {\n" +
        "      a += 2\n" +
        "      throw err\n" +
        "    }\n" +
        "    catch (IOErr e)\n" +
        "    {\n" +
        "      a += 2\n" +
        "    }\n" +
        "    catch\n" +
        "    {\n" +
        "      a += 1\n" +
        "    }\n" +
        "    return a\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { Int.make(3), IndexErr.make() });
      verify(o.Equals(Int.make(6)));

      o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { Int.make(3), IOErr.make() });
      verify(o.Equals(Int.make(7)));
    }

  //////////////////////////////////////////////////////////////////////////
  // Nested
  //////////////////////////////////////////////////////////////////////////

    void verifyNested()
    {
      string src =
        "class Foo\n" +
        "{\n" +
        "  static Int f(Int a)\n" +
        "  {\n" +
        "    try\n" +
        "    {\n" +
        "      a = 1\n" +
        "      try\n" +
        "      {\n" +
        "        a = 2\n" +
        "      }\n" +
        "      catch\n" +
        "      {\n" +
        "        a = 3\n" +
        "      }\n" +
        "      a = 4\n" +
        "    }\n" +
        "    catch\n" +
        "    {\n" +
        "      a = 5\n" +
        "    }\n" +
        "    return a\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { Int.make(3) });
      verify(o.Equals(Int.make(4)));
    }

  //////////////////////////////////////////////////////////////////////////
  // Try/Finally
  //////////////////////////////////////////////////////////////////////////

    void verifyTryFinally1()
    {
      string src = "class Foo\n"+
        "{\n"+
        "  static Int[] f(Int[] r, Int a)\n"+
        "  {\n"+
        "    r.add(0)\n"+
        "    try\n"+
        "    {\n"+
        "      r.add(a+1)\n"+
        "    }\n"+
        "    finally\n"+
        "    {\n"+
        "      r.add(99)\n"+
        "    }\n"+
        "    return r\n"+
        "  }\n"+
        "}";

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, Int.make(2) });

      List c = (List)o;
      verify(c.get(0).Equals(Int.make(0)));
      verify(c.get(1).Equals(Int.make(3)));
      verify(c.get(2).Equals(Int.make(99)));

      r.clear();
      try
      {
        o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, null });
      }
      catch (System.Reflection.TargetInvocationException ex)
      {
        verify(ex.InnerException is System.NullReferenceException);
        c = (List)o;
        verify(c.get(0).Equals(Int.make(0)));
        verify(c.get(1).Equals(Int.make(99)));
      }
    }

    void verifyTryFinally2()
    {
      string src = "class Foo\n" +
        "{\n" +
        "  static Int[] f(Int[] r, Boolean b)\n" +
        "  {\n" +
        "    r.add(0)\n" +
        "    try\n" +
        "    {\n" +
        "      r.add(1)\n" +
        "      if (b) throw ArgErr.make\n" +
        "      r.add(2)\n" +
        "    }\n" +
        "    finally\n" +
        "    {\n" +
        "      r.add(3)\n" +
        "    }\n" +
        "    r.add(4)\n" +
        "    return r\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, Boolean.False });

      List c = (List)o;
      verify(c.get(0).Equals(Int.make(0)));
      verify(c.get(1).Equals(Int.make(1)));
      verify(c.get(2).Equals(Int.make(2)));
      verify(c.get(3).Equals(Int.make(3)));
      verify(c.get(4).Equals(Int.make(4)));

      r.clear();
      try
      {
        o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, Boolean.True});
      }
      catch (System.Reflection.TargetInvocationException ex)
      {
        Err err = (ex.InnerException as Err.Val).err();
        verify(err.GetType() == System.Type.GetType("Fan.Sys.ArgErr"));

        c = (List)o;
        verify(c.get(0).Equals(Int.make(0)));
        verify(c.get(1).Equals(Int.make(1)));
        verify(c.get(2).Equals(Int.make(3)));
      }
    }

    void verifyTryFinally3()
    {
      string src = "class Foo\n" +
        "{\n" +
        "  static Int[] f(Int[] r)\n" +
        "  {\n" +
        "    r.add(0)\n" +
        "    try\n" +
        "    {\n" +
        "      r.add(1)\n" +
        "      return r\n" +
        "    }\n" +
        "    finally\n" +
        "    {\n" +
        "      r.add(2)\n" +
        "    }\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r });

      verify(r == o);

      List c = (List)o;
      verify(c.get(0).Equals(Int.make(0)));
      verify(c.get(1).Equals(Int.make(1)));
      verify(c.get(2).Equals(Int.make(2)));
    }

    void verifyTryFinally4()
    {
      string src = "class Foo\n" +
        "{\n" +
        "  static Int[] f(Int[] r)\n" +
        "  {\n" +
        "    r.add(0)\n" +
        "    try\n" +
        "    {\n" +
        "      r.add(1)\n" +
        "      try\n" +
        "      {\n" +
        "        return r.add(2)\n" +
        "      }\n" +
        "      finally\n" +
        "      {\n" +
        "        r.add(3)\n" +
        "      }\n" +
        "      return r.add(4)\n" +
        "    }\n" +
        "    finally\n" +
        "    {\n" +
        "      r.add(5)\n" +
        "    }\n" +
        "    return r.add(6)\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r });

      verify(r == o);

      List c = (List)o;
      verify(c.get(0).Equals(Int.make(0)));
      verify(c.get(1).Equals(Int.make(1)));
      verify(c.get(2).Equals(Int.make(2)));
      verify(c.get(3).Equals(Int.make(3)));
      verify(c.get(4).Equals(Int.make(5)));
    }

    void verifyTryFinally5()  // same as testTryFinally4 but Void
    {
      string src = "class Foo\n" +
        "{\n" +
        "  static Void f(Int[] r)\n" +
        "  {\n" +
        "    r.add(0)\n" +
        "    try\n" +
        "    {\n" +
        "      r.add(1)\n" +
        "      try\n" +
        "      {\n" +
        "        r.add(2)\n" +
        "        return\n" +
        "      }\n" +
        "      finally\n" +
        "      {\n" +
        "        r.add(3)\n" +
        "      }\n" +
        "      r.add(4)\n" +
        "      return\n" +
        "    }\n" +
        "    finally\n" +
        "    {\n" +
        "      r.add(5)\n" +
        "    }\n" +
        "    return\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r });

      verify(o == null);

      verify(r.get(0).Equals(Int.make(0)));
      verify(r.get(1).Equals(Int.make(1)));
      verify(r.get(2).Equals(Int.make(2)));
      verify(r.get(3).Equals(Int.make(3)));
      verify(r.get(4).Equals(Int.make(5)));
    }

    void verifyTryFinally6()
    {
      string src = "class Foo\n" +
        "{\n" +
        "  static Int[] f(Int[] r)\n" +
        "  {\n" +
        "    r.add(0)\n" +
        "    for (i:=1; i<=3; ++i)\n" +
        "    {\n" +
        "      try\n" +
        "      {\n" +
        "        if (i == 3) throw ArgErr.make\n" +
        "        r.add(10+i)\n" +
        "      }\n" +
        "      finally\n" +
        "      {\n" +
        "        r.add(100+i)\n" +
        "      }\n" +
        "    }\n" +
        "    return r.add(1)\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      try
      {
        type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r });
      }
      catch (System.Reflection.TargetInvocationException ex)
      {
        Err err = (ex.InnerException as Err.Val).err();
        verify(err.GetType() == System.Type.GetType("Fan.Sys.ArgErr"));

        verify(r.get(0).Equals(Int.make(0)));
        verify(r.get(1).Equals(Int.make(11)));
        verify(r.get(2).Equals(Int.make(101)));
        verify(r.get(3).Equals(Int.make(12)));
        verify(r.get(4).Equals(Int.make(102)));
        verify(r.get(5).Equals(Int.make(103)));
      }
    }

    void verifyTryFinally7()
    {
      string src = "class Foo\n" +
        "{\n" +
        "  static Int[] f(Int[] r)\n" +
        "  {\n" +
        "    r.add(0)\n" +
        "    for (i:=1; true; ++i)\n" +
        "    {\n" +
        "      try\n" +
        "      {\n" +
        "        if (i % 2 == 0) continue\n" +
        "        if (i == 5) break\n" +
        "        r.add(i)\n" +
        "      }\n" +
        "      finally\n" +
        "      {\n" +
        "        r.add(100+i)\n" +
        "      }\n" +
        "    }\n" +
        "    return r.add(99)\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r });

      verify(r == o);

      verify(r.get(0).Equals(Int.make(0)));
      verify(r.get(1).Equals(Int.make(1)));
      verify(r.get(2).Equals(Int.make(101)));
      verify(r.get(3).Equals(Int.make(102)));
      verify(r.get(4).Equals(Int.make(3)));
      verify(r.get(5).Equals(Int.make(103)));
      verify(r.get(6).Equals(Int.make(104)));
      verify(r.get(7).Equals(Int.make(105)));
      verify(r.get(8).Equals(Int.make(99)));
    }

    void verifyTryFinally8()
    {
      string src = "class Foo\n" +
        "{\n" +
        "  static Void f(Int[] r)\n" +
        "  {\n" +
        "    try\n" +
        "    {\n" +
        "      try\n" +
        "      {\n" +
        "        r.add(0)\n" +
        "        for (i:=1; true; ++i)\n" +
        "        {\n" +
        "          try\n" +
        "          {\n" +
        "            try\n" +
        "            {\n" +
        "              if (i % 2 == 0) continue\n" +
        "              if (i == 5) break\n" +
        "              r.add(i)\n" +
        "            }\n" +
        "            finally\n" +
        "            {\n" +
        "              r.add(100+i)\n" +
        "            }\n" +
        "          }\n" +
        "          finally\n" +
        "          {\n" +
        "            r.add(99)\n" +
        "          }\n" +
        "        }\n" +
        "        r.add(999)\n" +
        "      }\n" +
        "      finally\n" +
        "      {\n" +
        "        r.add(9999)\n" +
        "      }\n" +
        "    }\n" +
        "    finally\n" +
        "    {\n" +
        "      r.add(99999)\n" +
        "    }\n" +
        "  }\n" +
        "}";

      //r := Int[,]
      //verifySame(t.method("f").call1(r), null)
      //verifyEq(r, [0, 1, 101, 99, 102, 99, 3, 103, 99, 104, 99, 105, 99, 999, 9999, 99999])

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r });

      verify(o == null);

      verify(r.get(0).Equals(Int.make(0)));
      verify(r.get(1).Equals(Int.make(1)));
      verify(r.get(2).Equals(Int.make(101)));
      verify(r.get(3).Equals(Int.make(99)));
      verify(r.get(4).Equals(Int.make(102)));
      verify(r.get(5).Equals(Int.make(99)));
      verify(r.get(6).Equals(Int.make(3)));
      verify(r.get(7).Equals(Int.make(103)));
      verify(r.get(8).Equals(Int.make(99)));
      verify(r.get(9).Equals(Int.make(104)));
      verify(r.get(10).Equals(Int.make(99)));
      verify(r.get(11).Equals(Int.make(105)));
      verify(r.get(12).Equals(Int.make(99)));
      verify(r.get(13).Equals(Int.make(999)));
      verify(r.get(14).Equals(Int.make(9999)));
      verify(r.get(15).Equals(Int.make(99999)));
    }

  //////////////////////////////////////////////////////////////////////////
  // Try/Catch/Finally
  //////////////////////////////////////////////////////////////////////////

    void verifyTryCatchFinally1()
    {
      string src = "class Foo\n" +
        "{\n" +
        "  static Int f(Int[] r, Boolean raise)\n" +
        "  {\n" +
        "    r.add(0)\n" +
        "    try\n" +
        "    {\n" +
        "      r.add(1)\n" +
        "      if (raise) throw ArgErr.make\n" +
        "      r.add(2)\n" +
        "      return 2\n" +
        "    }\n" +
        "    catch\n" +
        "    {\n" +
        "      r.add(3)\n" +
        "      return 3\n" +
        "    }\n" +
        "    finally\n" +
        "    {\n" +
        "      r.add(4)\n" +
        "    }\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, Boolean.False });

      verify(o == Int.make(2));
      verify(r.get(0).Equals(Int.make(0)));
      verify(r.get(1).Equals(Int.make(1)));
      verify(r.get(2).Equals(Int.make(2)));
      verify(r.get(3).Equals(Int.make(4)));

      r.clear();
      o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, Boolean.True});
      verify(o == Int.make(3));
      verify(r.get(0).Equals(Int.make(0)));
      verify(r.get(1).Equals(Int.make(1)));
      verify(r.get(2).Equals(Int.make(3)));
      verify(r.get(3).Equals(Int.make(4)));
    }

    void verifyTryCatchFinally2() // same as testTryCatchFinally2 but Void
    {
      string src = "class Foo\n" +
        "{\n" +
        "  static Void f(Int[] r, Boolean raise)\n" +
        "  {\n" +
        "    r.add(0)\n" +
        "    try\n" +
        "    {\n" +
        "      r.add(1)\n" +
        "      if (raise) throw ArgErr.make\n" +
        "      r.add(2)\n" +
        "    }\n" +
        "    catch\n" +
        "    {\n" +
        "      r.add(3)\n" +
        "    }\n" +
        "    finally\n" +
        "    {\n" +
        "      r.add(4)\n" +
        "    }\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, Boolean.False });

      verify(o == null);
      verify(r.get(0).Equals(Int.make(0)));
      verify(r.get(1).Equals(Int.make(1)));
      verify(r.get(2).Equals(Int.make(2)));
      verify(r.get(3).Equals(Int.make(4)));

      r.clear();
      o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, Boolean.True});
      verify(o == null);
      verify(r.get(0).Equals(Int.make(0)));
      verify(r.get(1).Equals(Int.make(1)));
      verify(r.get(2).Equals(Int.make(3)));
      verify(r.get(3).Equals(Int.make(4)));
    }

    void verifyTryCatchFinally3()
    {
      string src = "class Foo\n" +
        "{\n" +
        "  static Void f(Int[] r, Err err)\n" +
        "  {\n" +
        "    r.add(0)\n" +
        "    try\n" +
        "    {\n" +
        "      r.add(1)\n" +
        "      if (err != null) throw err\n" +
        "      r.add(2)\n" +
        "    }\n" +
        "    catch\n" +
        "    {\n" +
        "      r.add(3)\n" +
        "      throw err\n" +
        "      r.add(4)\n" +
        "    }\n" +
        "    finally\n" +
        "    {\n" +
        "      r.add(99)\n" +
        "    }\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, null });

      verify(o == null);
      verify(r.get(0).Equals(Int.make(0)));
      verify(r.get(1).Equals(Int.make(1)));
      verify(r.get(2).Equals(Int.make(2)));
      verify(r.get(3).Equals(Int.make(99)));

      r.clear();
      try
      {
        o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, IndexErr.make() });
      }
      catch (System.Reflection.TargetInvocationException ex)
      {
        Err err = (ex.InnerException as Err.Val).err();
        verify(err.GetType() == System.Type.GetType("Fan.Sys.IndexErr"));

        verify(r.get(0).Equals(Int.make(0)));
        verify(r.get(1).Equals(Int.make(1)));
        verify(r.get(2).Equals(Int.make(3)));
        verify(r.get(3).Equals(Int.make(99)));
      }

      r.clear();
      try
      {
        o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, IOErr.make() });
      }
      catch (System.Reflection.TargetInvocationException ex)
      {
        Err err = (ex.InnerException as Err.Val).err();
        verify(err.GetType() == System.Type.GetType("Fan.Sys.IOErr"));

        verify(r.get(0).Equals(Int.make(0)));
        verify(r.get(1).Equals(Int.make(1)));
        verify(r.get(2).Equals(Int.make(3)));
        verify(r.get(3).Equals(Int.make(99)));
      }
    }

    void verifyTryCatchFinally4()
    {
      string src = "class Foo\n" +
        "{\n" +
        "  static Void f(Int[] r, Err err)\n" +
        "  {\n" +
        "    r.add(0)\n" +
        "    try\n" +
        "    {\n" +
        "      r.add(1)\n" +
        "      if (err != null) throw err\n" +
        "      r.add(2)\n" +
        "    }\n" +
        "    catch (IOErr e)\n" +
        "    {\n" +
        "      r.add(3)\n" +
        "      throw e\n" +
        "      r.add(4)\n" +
        "    }\n" +
        "    catch\n" +
        "    {\n" +
        "      r.add(5)\n" +
        "      throw err\n" +
        "      r.add(6)\n" +
        "    }\n" +
        "    finally\n" +
        "    {\n" +
        "      r.add(99)\n" +
        "    }\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, null });

      verify(o == null);
      verify(r.get(0).Equals(Int.make(0)));
      verify(r.get(1).Equals(Int.make(1)));
      verify(r.get(2).Equals(Int.make(2)));
      verify(r.get(3).Equals(Int.make(99)));

      r.clear();
      try
      {
        o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, IOErr.make() });
      }
      catch (System.Reflection.TargetInvocationException ex)
      {
        Err err = (ex.InnerException as Err.Val).err();
        verify(err.GetType() == System.Type.GetType("Fan.Sys.IOErr"));

        verify(r.get(0).Equals(Int.make(0)));
        verify(r.get(1).Equals(Int.make(1)));
        verify(r.get(2).Equals(Int.make(3)));
        verify(r.get(3).Equals(Int.make(99)));
      }

      r.clear();
      try
      {
        o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r, IndexErr.make() });
      }
      catch (System.Reflection.TargetInvocationException ex)
      {
        Err err = (ex.InnerException as Err.Val).err();
        verify(err.GetType() == System.Type.GetType("Fan.Sys.IndexErr"));

        verify(r.get(0).Equals(Int.make(0)));
        verify(r.get(1).Equals(Int.make(1)));
        verify(r.get(2).Equals(Int.make(5)));
        verify(r.get(3).Equals(Int.make(99)));
      }
    }

    void verifyTryCatchFinally5() // torture test
    {
      string src = "class Foo\n" +
        "{\n" +
        "  static Void f(Int[] r)\n" +
        "  {\n" +
        "    r.add(0)\n" +
        "    try\n" +
        "    {\n" +
        "      for (i:=0; i<5; ++i)\n" +
        "      {\n" +
        "        r.add(10+i)\n" +
        "        try\n" +
        "        {\n" +
        "          try\n" +
        "          {\n" +
        "            if (i == 2) throw IOErr.make\n" +
        "            r.add(20+i)\n" +
        "          }\n" +
        "          finally\n" +
        "          {\n" +
        "            r.add(30+i)\n" +
        "          }\n" +
        "\n" +
        "          try\n" +
        "          {\n" +
        "          }\n" +
        "          finally\n" +
        "          {\n" +
        "            r.add(300+i)\n" +
        "          }\n" +
        "        }\n" +
        "        catch\n" +
        "        {\n" +
// TODO - THIS IS NOT EMITTED AS VALID IL....
        "          try\n" +
        "          {\n" +
//        "            r.add(900+i)\n" +
//        "            throw IOErr.make\n" +
//        "            r.add(910+i)\n" +
        "          }\n" +
//        "          catch {}\n" +
        "          finally {}\n" +
//        "          catch (IOErr e)\n" +
//        "          {\n" +
//        "            r.add(920+i)\n" +
//        "          }\n" +
//        "          finally\n" +
//        "          {\n" +
//        "            r.add(930+i)\n" +
//        "          }\n" +
// END TODO
        "          break\n" +
        "        }\n" +
        "        r.add(50+i)\n" +
        "      }\n" +
        "    }\n" +
        "    finally\n" +
        "    {\n" +
        "      r.add(99)\n" +
        "    }\n" +
        "    r.add(999)\n" +
        "  }\n" +
        "}";

      //r := Int[,]
      //t.method("f").call1(r)
      //verifyEq(r, [0, 10, 20, 30, 300, 50, 11, 21, 31, 301, 51, 12, 32, 902, 922, 932, 99, 999])

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[] { r });

      verify(o == null);
      verify(r.get(0).Equals(Int.make(0)));
      verify(r.get(1).Equals(Int.make(10)));
      verify(r.get(2).Equals(Int.make(20)));
      verify(r.get(3).Equals(Int.make(30)));
      verify(r.get(4).Equals(Int.make(300)));
      verify(r.get(5).Equals(Int.make(50)));
      verify(r.get(6).Equals(Int.make(11)));
      verify(r.get(7).Equals(Int.make(21)));
      verify(r.get(8).Equals(Int.make(31)));
      verify(r.get(9).Equals(Int.make(301)));
      verify(r.get(10).Equals(Int.make(51)));
      verify(r.get(11).Equals(Int.make(12)));
      verify(r.get(12).Equals(Int.make(32)));
      verify(r.get(13).Equals(Int.make(902)));
      verify(r.get(14).Equals(Int.make(922)));
      verify(r.get(15).Equals(Int.make(932)));
      verify(r.get(16).Equals(Int.make(99)));
      verify(r.get(17).Equals(Int.make(999)));
    }


    void FuckMe() // torture test
    {
      string src = "class Foo\n" +
        "{\n" +
        "  static Void f()\n" +
        "  {\n" +
        "    try {}\n" +
        "    catch\n" +
        "    {\n" +
        "      try {}\n" +
        //"      catch {}\n" +
        "      finally {}\n" +
        "    }\n" +
        "  }\n" +
        "}";

      System.Type type = CompileToType(src);
      List r = new List(Sys.IntType, new object[0]);
      type.InvokeMember("F", GetStaticFlags(), null, null, new object[0]);
    }

  }
}
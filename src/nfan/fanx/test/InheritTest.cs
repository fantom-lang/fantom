//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Dec 06  Andy Frank  Creation
//

using System.Reflection;
using Fan.Sys;

namespace Fanx.Test
{
  /// <summary>
  /// SlotDefTest.
  /// </summary>
  public class InheritTest : CompileTest
  {
  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    public override void Run()
    {
      verifyForward();
      verifyBackward();
      verifyCovariance();
    }

  //////////////////////////////////////////////////////////////////////////
  // Forward
  //////////////////////////////////////////////////////////////////////////

    string forward  =
      "class A\n" + // : Test\n" +
      "{\n" +
      "  Str a() { return \"a\" }\n" +
      "  virtual Str f() { return \"af\" }\n" +
      "}\n" +

      "class B : A\n" +
      "{\n" +
      "  Str b()  { return \"b\" }\n" +
      "  Str bi() { return b() }\n" +
      "  Str ai() { return a() }\n" +
      "  override Str f()  { return \"bf\" }\n" +
      "}";

    public void verifyForward()
    {
      System.Type[] types = CompileToTypes(forward);
      System.Type clsA = types[0];
      System.Type clsB = types[1];

      verify(clsB.BaseType == clsA);

      object a = Make(clsA);
      object b = Make(clsB);

      verify(InvokeInstance(clsA, a, "A"),  Str.make("a"));
      verify(InvokeInstance(clsB, b, "A"),  Str.make("a"));
      verify(InvokeInstance(clsB, b, "B"),  Str.make("b"));
      verify(InvokeInstance(clsB, b, "Bi"), Str.make("b"));
      verify(InvokeInstance(clsB, b, "Ai"), Str.make("a"));

      verify(InvokeInstance(clsA, a, "F"),  Str.make("af"));
      verify(InvokeInstance(clsB, b, "F"),  Str.make("bf"));

//      verify(invoke(a, "setup"),    null);
//      verify(invoke(a, "teardown"), null);
    }

  //////////////////////////////////////////////////////////////////////////
  // Backward
  //////////////////////////////////////////////////////////////////////////

    string backward =
      "class B : A\n" +
      "{\n" +
      "  Str b() { return \"b\" }\n" +
      "  Str bi() { return b() }\n" +
      "  Str ai() { return a() }\n" +
      "}" +

      "class A\n" +
      "{\n" +
      "  Str a() { return \"a\" }\n" +
      "}\n";

    public void verifyBackward()
    {
      System.Type[] types = CompileToTypes(backward);
      System.Type clsA = types[0];
      System.Type clsB = types[1];

      verify(clsB.BaseType == clsA);

      object a = Make(clsA);
      object b = Make(clsB);

      verify(InvokeInstance(clsA, a, "A"),  Str.make("a"));
      verify(InvokeInstance(clsB, b, "B"),  Str.make("b"));
      verify(InvokeInstance(clsB, b, "Bi"), Str.make("b"));
      verify(InvokeInstance(clsB, b, "Ai"), Str.make("a"));
    }

  //////////////////////////////////////////////////////////////////////////
  // Covariance
  //////////////////////////////////////////////////////////////////////////

    string covariance =
      "class A\n" +
      "{\n" +
      "  virtual A f() { return this }\n" +
      "}" +

      "class B : A\n" +
      "{\n" +
      "  override B f() { return this }\n" +
      "}\n";

    public void verifyCovariance()
    {
      System.Type[] types = CompileToTypes(covariance);
      System.Type clsA = types[0];
      System.Type clsB = types[1];

      verify(clsB.BaseType == clsA);

      object a = Make(clsA);
      object b = Make(clsB);

      verify(InvokeInstance(clsA, a, "F"),  a);
      verify(InvokeInstance(clsB, b, "F"),  b);
    }

  }
}
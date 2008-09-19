//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 06  Andy Frank  Creation
//

using Fan.Sys;

namespace Fanx.Test
{
  /// <summary>
  /// MethodTest.
  /// </summary>
  public class MethodTest : CompileTest
  {

  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    public override void Run()
    {
      verifyTyping();
      //verifyCall();
    }

  //////////////////////////////////////////////////////////////////////////
  // Typing
  //////////////////////////////////////////////////////////////////////////

    public void verifyTyping()
    {
      verifySig("|,|", new Type[] { }, Sys.VoidType);

      verifySig("|->Str|", new Type[] { }, Sys.StrType);

      verifySig("|->Void|", new Type[] { }, Sys.VoidType);

      verifySig("|Bool x-> Str|", new Type[] { Sys.BoolType }, Sys.StrType);

      verifySig("|Str a, Duration b -> Int|",
                new Type[] { Sys.StrType, Sys.DurationType },
                Sys.IntType);

      verifySig("|Bool a, Int b, Int c, Str d, Type e, Obj f, Str g, Bool h -> Int|",
               new Type[] { Sys.BoolType, Sys.IntType, Sys.IntType, Sys.StrType,
                 Sys.TypeType, Sys.ObjType, Sys.StrType, Sys.BoolType  },
               Sys.IntType);

      verifySig("|Bool a, Int b, Int c, Str d, Type e, Obj f, Str g, Bool h, Duration i -> Int|",
               new Type[] { Sys.BoolType, Sys.IntType, Sys.IntType, Sys.StrType,
                 Sys.TypeType, Sys.ObjType, Sys.StrType, Sys.BoolType, Sys.DurationType  },
               Sys.IntType);

      //verifySigErr("|Bool a-> Int,Bool|", "Expected '|', not ','");
    }

    /*
    void verifySigErr(string sig, string msg)
    {
      verifyErr("static Obj f(" + sig + " m) { return null }", msg);
    }
    */

    void verifySig(string sig, Type[] p, Type r)
    {
      // test as method param signature
      Type t = CompileToFanType("class Foo { static Obj f(" + sig + " m) { return null } }");
      Method m = t.method("f", true);
      Param pars = (Param)m.@params().get(0);
      verifySig(pars.of(), p, r);

      // test as type literal
      //t = CompileToFanType("class Foo { static Type f() { return " + sig + ".type } }");
      //m = t.Method("f", true);
      //verifySig((Type)m.Call0(), p, r);

      // test as closure signature
      System.Type cls;
      if (r.isVoid())
        cls = CompileToType("class Foo { static Method f() { return " + sig + " { return; } }}");
      else
        cls = CompileToType("class Foo { static Method f() { return " + sig + " { return null; } }}");
      m = (Method)InvokeStatic(cls, "F");
      verifySig(m.type(), p, r);
    }

    void verifySig(Type t, Type[] p, Type r)
    {
      for (int i=0; i<=Func.MaxIndirectParams; i++)
      {
        Method c = t.method("call"+i, true);

        // verify return
        verify(c.returns() == r);

        // verify p0..pn params
        for (int j=0; j<p.Length && j<i; j++)
        {
          verify(((Param)c.@params().get(j)).of() == p[j]);
        }

        // verify rest left at Obj
        for (int j=p.Length; j<Func.MaxIndirectParams && j<i; j++)
        {
          verify(((Param)c.@params().get(j)).of() == Sys.ObjType);
        }
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Call
  //////////////////////////////////////////////////////////////////////////

    /*
    public void verifyCall()
      throws Exception
    {
      // static
      verify("Obj f(|Str s, Bool c -> Type| m) { return m.call([\"sys::Str\", true]) }",
        new Obj[] { Sys.findMethod("sys::Sys.findType", true) }, Sys.StrType);
      verify("Obj f(|Str s, Bool c -> Type| m) { return m.call([\"sys::Str\", true, 55]) }",
        new Obj[] { Sys.findMethod("sys::Sys.findType", true) }, Sys.StrType);

      // instance
      verify("Obj f(|Int a, Int b -> Int| m) { return m.call([4, 2])}",
        new Obj[] { Sys.findMethod("sys::Int.plus", true) }, Int.make(6));
      verify("Obj f(|Int a, Int b -> Int| m) { return m.call([4, 2])}",
        new Obj[] { Sys.findMethod("sys::Int.star", true) }, Int.make(8));
      verify("Obj f(|Int a, Int b -> Int| m) { return m.call([4, 2, 3])}",
        new Obj[] { Sys.findMethod("sys::Int.star", true) }, Int.make(8));
      verify("Obj f(|Int a, Int b -> Int| m) { return m.call([-3])}",
        new Obj[] { Sys.findMethod("sys::Int.negate", true) }, Int.make(3));
      verify("Obj f(|Int a, Int b -> Int| m) { return m.call([4, 2])}",
        new Obj[] { Sys.findMethod("sys::Int.negate", true) }, Int.make(-4));
    }
    */

  }
}

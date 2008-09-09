//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Dec 06  Andy Frank  Creation
//

using System.Reflection;
using Fan.Sys;

namespace Fanx.Test
{
  /// <summary>
  /// IsAsTest.
  /// </summary>
  public class IsAsTest : CompileTest
  {

  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    public override void Run()
    {
      verifyIs();
      verifyAs();
      // TODO
      //verifyFits();
      //verifyList();
    }

  //////////////////////////////////////////////////////////////////////////
  // Is
  //////////////////////////////////////////////////////////////////////////

    void verifyIs()
    {
      verify("Bool f() { return true is Bool }",  null, Bool.True);
      //verify("Bool f() { return 5 is Bool }",  null, Bool.False);
      verify("Bool f() { return type is Type}",  null, Bool.True);
      //verify("Bool f() { return type.name is Type}",  null, Bool.False);
      verify("Bool f() { return type.name is Str}",  null, Bool.True);
      verify("Bool f() { return type.name.size is Int}",  null, Bool.True);
      verify("Bool f(Obj o) { return o is Int}",  MakeBools(false), Bool.False);
      verify("Bool f(Obj o) { return o is Int}",  MakeInts(7), Bool.True);
    }

  //////////////////////////////////////////////////////////////////////////
  // As
  //////////////////////////////////////////////////////////////////////////

    void verifyAs()
    {
      verify("Str f(Obj x) { return x as Str }", MakeStrs("foo"), Str.make("foo"));
      verify("Str f(Obj x) { return x as Str }", MakeInts(4), null);
      verify("Str f(Obj x) { return x as Str }", new Obj[] { null }, null);
      verify("Str f(Obj x) { return x.type.method(\"toStr\").call1(x) as Str }", MakeInts(2), Str.make("2"));
      verify("Int f(Obj x) { return x.type.method(\"toStr\").call1(x) as Int }", MakeInts(2), null);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fits
  //////////////////////////////////////////////////////////////////////////

    /*
    void verifyFits()
    {
      verify("Bool f() { return true.type.fits(Bool.type) }",  null, Bool.True);
      verify("Bool f() { return 5.type.fits(Bool.type) }",  null, Bool.False);
      verify("Bool f() { return 5ms.type.fits(Obj.type) }",  null, Bool.True);
    }
    */

  //////////////////////////////////////////////////////////////////////////
  // List
  //////////////////////////////////////////////////////////////////////////

    /*
    void verifyList()
    {
      // is Str[,]
      verify("Bool f() { return Str[,] is Bool  }",   null, Bool.False);
      verify("Bool f() { return Str[,] is List  }",   null, Bool.True);
      verify("Bool f() { return Str[,] is Obj[] }",   null, Bool.True);
      verify("Bool f() { return Str[,] is Str[] }",   null, Bool.True);
      verify("Bool f() { return Str[,] is Int[] }",   null, Bool.False);
      verify("Bool f() { return Str[,] is Str[][] }", null, Bool.False);

      // as Str[,]
      Obj x = new List(Sys.StrType);
      Object[] a = { x };
      verify("Bool    f(Obj x) { return x as Bool  }",   a, null);
      verify("List    f(Obj x) { return x as List  }",   a, x);
      verify("Obj[]   f(Obj x) { return x as Obj[] }",   a, x);
      verify("Str[]   f(Obj x) { return x as Str[] }",   a, x);
      verify("Int[]   f(Obj x) { return x as Int[] }",   a, null);
      verify("Str[][] f(Obj x) { return x as Str[][] }", a, null);

      // is [Str[,]]
      verify("Bool f() { return [Str[,]] is Bool  }",      null, Bool.False);
      verify("Bool f() { return [Str[,]] is List  }",      null, Bool.True);
      verify("Bool f() { return [Str[,]] is List[]  }",    null, Bool.True);
      verify("Bool f() { return [Str[,]] is Str[]  }",     null, Bool.False);
      verify("Bool f() { return [Str[,]] is Str[][]  }",   null, Bool.True);
      verify("Bool f() { return [Str[,]] is Obj[][]  }",   null, Bool.True);
      verify("Bool f() { return [Str[,]] is Int[][]  }",   null, Bool.False);
      verify("Bool f() { return [Str[,]] is Str[][][] }",  null, Bool.False);

      // as [Str[,]]
      x = new List(Sys.StrType.toListOf());
      a = new Obj[] { x };
      verify("Bool      f(Obj x) { return x as Bool  }",      a, null);
      verify("List      f(Obj x) { return x as List  }",      a, x);
      verify("List[]    f(Obj x) { return x as List[]  }",    a, x);
      verify("Str[]     f(Obj x) { return x as Str[]  }",     a, null);
      verify("Str[][]   f(Obj x) { return x as Str[][]  }",   a, x);
      verify("Obj[][]   f(Obj x) { return x as Obj[][]  }",   a, x);
      verify("Int[][]   f(Obj x) { return x as Int[][]  }",   a, null);
      verify("Str[][][] f(Obj x) { return x as Str[][][] }",  a, null);
    }
    */

  }
}
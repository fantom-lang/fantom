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
      verify("Boolean f() { return true is Boolean }",  null, Boolean.True);
      //verify("Boolean f() { return 5 is Boolean }",  null, Boolean.False);
      verify("Boolean f() { return type is Type}",  null, Boolean.True);
      //verify("Boolean f() { return type.name is Type}",  null, Boolean.False);
      verify("Boolean f() { return type.name is Str}",  null, Boolean.True);
      verify("Boolean f() { return type.name.size is Int}",  null, Boolean.True);
      verify("Boolean f(Obj o) { return o is Int}",  MakeBools(false), Boolean.False);
      verify("Boolean f(Obj o) { return o is Int}",  MakeInts(7), Boolean.True);
    }

  //////////////////////////////////////////////////////////////////////////
  // As
  //////////////////////////////////////////////////////////////////////////

    void verifyAs()
    {
      verify("Str f(Obj x) { return x as Str }", MakeStrs("foo"), Str.make("foo"));
      verify("Str f(Obj x) { return x as Str }", MakeInts(4), null);
      verify("Str f(Obj x) { return x as Str }", new object[] { null }, null);
      verify("Str f(Obj x) { return x.type.method(\"toStr\").call1(x) as Str }", MakeInts(2), Str.make("2"));
      verify("Int f(Obj x) { return x.type.method(\"toStr\").call1(x) as Int }", MakeInts(2), null);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fits
  //////////////////////////////////////////////////////////////////////////

    /*
    void verifyFits()
    {
      verify("Boolean f() { return true.type.fits(Boolean.type) }",  null, Boolean.True);
      verify("Boolean f() { return 5.type.fits(Boolean.type) }",  null, Boolean.False);
      verify("Boolean f() { return 5ms.type.fits(Obj.type) }",  null, Boolean.True);
    }
    */

  //////////////////////////////////////////////////////////////////////////
  // List
  //////////////////////////////////////////////////////////////////////////

    /*
    void verifyList()
    {
      // is Str[,]
      verify("Boolean f() { return Str[,] is Boolean  }",   null, Boolean.False);
      verify("Boolean f() { return Str[,] is List  }",   null, Boolean.True);
      verify("Boolean f() { return Str[,] is Obj[] }",   null, Boolean.True);
      verify("Boolean f() { return Str[,] is Str[] }",   null, Boolean.True);
      verify("Boolean f() { return Str[,] is Int[] }",   null, Boolean.False);
      verify("Boolean f() { return Str[,] is Str[][] }", null, Boolean.False);

      // as Str[,]
      Obj x = new List(Sys.StrType);
      Object[] a = { x };
      verify("Boolean    f(Obj x) { return x as Boolean  }",   a, null);
      verify("List    f(Obj x) { return x as List  }",   a, x);
      verify("Obj[]   f(Obj x) { return x as Obj[] }",   a, x);
      verify("Str[]   f(Obj x) { return x as Str[] }",   a, x);
      verify("Int[]   f(Obj x) { return x as Int[] }",   a, null);
      verify("Str[][] f(Obj x) { return x as Str[][] }", a, null);

      // is [Str[,]]
      verify("Boolean f() { return [Str[,]] is Boolean  }",      null, Boolean.False);
      verify("Boolean f() { return [Str[,]] is List  }",      null, Boolean.True);
      verify("Boolean f() { return [Str[,]] is List[]  }",    null, Boolean.True);
      verify("Boolean f() { return [Str[,]] is Str[]  }",     null, Boolean.False);
      verify("Boolean f() { return [Str[,]] is Str[][]  }",   null, Boolean.True);
      verify("Boolean f() { return [Str[,]] is Obj[][]  }",   null, Boolean.True);
      verify("Boolean f() { return [Str[,]] is Int[][]  }",   null, Boolean.False);
      verify("Boolean f() { return [Str[,]] is Str[][][] }",  null, Boolean.False);

      // as [Str[,]]
      x = new List(Sys.StrType.toListOf());
      a = new Obj[] { x };
      verify("Boolean      f(Obj x) { return x as Boolean  }",      a, null);
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

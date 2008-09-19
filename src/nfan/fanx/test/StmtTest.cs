//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Nov 06  Brian Frank  Creation
//

using Fan.Sys;

namespace Fanx.Test
{
  /// <summary>
  /// StmtTest.
  /// </summary>
  public class StmtTest : CompileTest
  {

  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    public override void Run()
    {
      verifyIf();
      verifyWhile();
      verifyFor();
      verifyThrow();
    }

  //////////////////////////////////////////////////////////////////////////
  // If Statement
  //////////////////////////////////////////////////////////////////////////

    void verifyIf()
    {
      object[] f  = MakeBools(false);
      object[] t  = MakeBools(true);
      object[] fx = new object[] { Bool.False, Int.make(-1) };
      object[] tx = new object[] { Bool.True,  Int.make(-1) };

      // no else - return
      verify("Int f(Bool b) { if (b) return 2; return 3; }",       t, Int.make(2));
      verify("Int f(Bool b) { if (b) return 2; return 3; }",       f, Int.make(3));
      verify("Int f(Bool b) { if (b) { return 2; } return 3; }",   t, Int.make(2));
      verify("Int f(Bool b) { if (b) { return 2; } return 3; }",   f, Int.make(3));

      // else - return
      verify("Int f(Bool b) { if (b) return 2; else return 3; }",  t, Int.make(2));
      verify("Int f(Bool b) { if (b) return 2; else return 3; }",  f, Int.make(3));
      verify("Int f(Bool b) { if (b) { return 2; } else { return 3; } }",  t, Int.make(2));
      verify("Int f(Bool b) { if (b) { return 2; } else { return 3; } }",  f, Int.make(3));

      // no else - no return
      verify("Int f(Bool b, Int x) { if (b) x = 2; return x; }", tx, Int.make(2));
      verify("Int f(Bool b, Int x) { if (b) x = 2; return x; }", fx, Int.make(-1));
      verify("Int f(Bool b, Int x) { if (b) { x = 2; } return x; }", tx, Int.make(2));
      verify("Int f(Bool b, Int x) { if (b) { x = 2; } return x; }", fx, Int.make(-1));

      // else - no return
      verify("Int f(Bool b, Int x) { if (b) { x = 2; } else { x = 3; } return x; }", tx, Int.make(2));
      verify("Int f(Bool b, Int x) { if (b) { x = 2; } else { x = 3; } return x; }", fx, Int.make(3));

      // if/else if/else - return
      verify("Int f(Int x) { if (x == 0) return 10; else if (x == 1) return 11; else return 12;  }", MakeInts(0), Int.make(10));
      verify("Int f(Int x) { if (x == 0) return 10; else if (x == 1) return 11; else return 12;  }", MakeInts(1), Int.make(11));
      verify("Int f(Int x) { if (x == 0) return 10; else if (x == 1) return 11; else return 12;  }", MakeInts(2), Int.make(12));

      // if/else if - no return
      verify("Int f(Int x, Int y) { if (x == 0) y = 10; else if (x == 1) y = 11; return y;}", MakeInts(0, -1), Int.make(10));
      verify("Int f(Int x, Int y) { if (x == 0) y = 10; else if (x == 1) y = 11; return y;}", MakeInts(1, -1), Int.make(11));
      verify("Int f(Int x, Int y) { if (x == 0) y = 10; else if (x == 1) y = 11; return y;}", MakeInts(2, -1), Int.make(-1));

      // if/else if/else - no return
      verify("Int f(Int x, Int y) { if (x == 0) y = 10; else if (x == 1) y = 11; else y = 12; return y;}", MakeInts(0, -1), Int.make(10));
      verify("Int f(Int x, Int y) { if (x == 0) y = 10; else if (x == 1) y = 11; else y = 12; return y;}", MakeInts(1, -1), Int.make(11));
      verify("Int f(Int x, Int y) { if (x == 0) y = 10; else if (x == 1) y = 11; else y = 12; return y;}", MakeInts(2, -1), Int.make(12));

      // if/else if/else if/else if/else - return
      verify("Int f(Int x) { if (x == 0) return 10; else if (x == 1) return 11; else if (x == 2) return 12; else if (x == 3) return 13; else return 14;}", MakeInts(0), Int.make(10));
      verify("Int f(Int x) { if (x == 0) return 10; else if (x == 1) return 11; else if (x == 2) return 12; else if (x == 3) return 13; else return 14;}", MakeInts(1), Int.make(11));
      verify("Int f(Int x) { if (x == 0) return 10; else if (x == 1) return 11; else if (x == 2) return 12; else if (x == 3) return 13; else return 14;}", MakeInts(2), Int.make(12));
      verify("Int f(Int x) { if (x == 0) return 10; else if (x == 1) return 11; else if (x == 2) return 12; else if (x == 3) return 13; else return 14;}", MakeInts(3), Int.make(13));
      verify("Int f(Int x) { if (x == 0) return 10; else if (x == 1) return 11; else if (x == 2) return 12; else if (x == 3) return 13; else return 14;}", MakeInts(4), Int.make(14));

      // if { if/else } else { if/else } - return
      verify("Int f(Bool x, Bool y) { if (x) { if (y) return 3; else return 2; } else { if (y) return 1; else return 0; } }", MakeBools(false, false), Int.make(0));
      verify("Int f(Bool x, Bool y) { if (x) { if (y) return 3; else return 2; } else { if (y) return 1; else return 0; } }", MakeBools(false, true),  Int.make(1));
      verify("Int f(Bool x, Bool y) { if (x) { if (y) return 3; else return 2; } else { if (y) return 1; else return 0; } }", MakeBools(true,  false), Int.make(2));
      verify("Int f(Bool x, Bool y) { if (x) { if (y) return 3; else return 2; } else { if (y) return 1; else return 0; } }", MakeBools(true,  true),  Int.make(3));

      // errors
//VERR      verifyErr("Int f() { if (5) return 1; else return 2 }", "If condition must be Bool, not 'sys::Int'");
    }

  //////////////////////////////////////////////////////////////////////////
  // While Statement
  //////////////////////////////////////////////////////////////////////////

    void verifyWhile()
    {
      // basic loop
      verify("static Int f(Int x) { while (x < 5) x++; return x }", MakeInts(2), Int.make(5));

      // count to field
      members = "x := 0\n";
      verify("Int f(Int to) { while (x < to) x = x + 1\n return x }", MakeInts(3), Int.make(3));
      verify("Int f(Int to) { while (x < to) x = x + 1;  return x }", MakeInts(4), Int.make(4));
      verify("Int f(Int to) { while (x < to) {x++} return x }", MakeInts(5), Int.make(5));

      // break
      verify("Int f(Int x) { while (true) { x++; if (x == 7) break } return x }", MakeInts(0), Int.make(7));

      // two teir break
      verify("Int f(Int x) { i:=0; j:=0; while (true) { i++; /*echo(\"i=\"+i+\" j=\"+j);*/ if (i > 3) break; j=0; while (j!=5) {j++; x++; /*echo(\"  j=\"+j+\" x=\"+x);*/} } return x }", MakeInts(0), Int.make(15));

      // continue
      verify("Int f(Int x) { i:=0; while (i<10) { i++; if (i%2 == 0) continue; x++ } return x }", MakeInts(0), Int.make(5));

      // two teir break & continue
      verify("Int f(Int x) { i:=0; j:=0; while (i<10) { i++; if (i%2 == 0) continue; j = 0; while (true) { j++; if (j>10) break; x++ } } return x }", MakeInts(0), Int.make(50));

      // errors
//VERR      verifyErr("Void f() { while (5) {} }", "While condition must be Bool, not 'sys::Int'");
//VERR      verifyErr("Void f() { break; }",      "Break outside of loop (break is implicit in switch)");
//VERR      verifyErr("Void f() { continue; }",   "Continue outside of loop");
    }


  //////////////////////////////////////////////////////////////////////////
  // For Statement
  //////////////////////////////////////////////////////////////////////////

    void verifyFor()
    {
      // basic loop
      verify("static Int f() { r:=0; for (x:=0; x<10; ++x) r++; return r }", Int.make(10));

      // init as expr, without init
      verify("static Int f() { r:=0; for (Int x:=0; x<10; ++x) r++; return r }", Int.make(10));
      verify("static Int f() { r:=0; x:=0; for (x=0; x<10; ++x) r++; return r }", Int.make(10));
      verify("static Int f() { r:=0; x:=0; for (; x<10; ++x) r++; return r }", Int.make(10));

      // without update
      verify("static Int f() { r:=0; for (x:=0; x<10;) { r++; x++; } return r }", Int.make(10));

      // without cond, break
      verify("Int f() { x:=0; for (;;++x) if (x == 7) break; return x;}", Int.make(7));

      // two breaks
      verify("Int f(Bool b) { x:=0; for (;;) { if (b) {x=1; break} else {x=-1; break}} return x;}", MakeBools(false), Int.make(-1));
      verify("Int f(Bool b) { x:=0; for (;;) { if (b) {x=1; break} else {x=-1; break}} return x;}", MakeBools(true), Int.make(+1));

      // two tier break
      verify("Int f() {" +
        "x :=0 ;" +
        "for (i:=0; true; ++i)" +
        "{" +
        "  if (i==3) break;" +
        "  for (Int j:=0;; ++j) { if (j==5) break; x++; }" +
        "}" +
        "return x; }", Int.make(15));

      // continue
      verify("Int f() { x:=0; for (i:=0;i<10;) { i++; if (i%2 == 0) continue; x++ } return x }", Int.make(5));

      // reuse vars in for blocks
      verify("Int f() { x:=0; for (Int i:=0; i<3; ++i) x++; for (Int i:=0; i<2; ++i) x++; return x;}", Int.make(5));

      // errors
//VERR      verifyErr("Void f() { for (;\"x\";) {} }", "For condition must be Bool, not 'sys::Str'");
//VERR      verifyErr("Void f() { break; }",      "Break outside of loop (break is implicit in switch)");
//VERR      verifyErr("Void f() { continue; }",   "Continue outside of loop");
    }

  //////////////////////////////////////////////////////////////////////////
  // Throw Statement
  //////////////////////////////////////////////////////////////////////////

    void verifyThrow()
    {
      Err err;

      err = null;
      try { verify("Int f() { throw Err.make(\"bad\") }", null); }
      catch (System.Reflection.TargetInvocationException e) { err = (e.InnerException as Err.Val).err(); }
      verify(err != null);
      verify(err.GetType() == System.Type.GetType("Fan.Sys.Err"));
      verify(err.message().val.Equals("bad"));

      err = null;
      try { verify("Int f() { throw IOErr.make(); return 0; }", null); }
      catch (System.Reflection.TargetInvocationException e) { err = (e.InnerException as Err.Val).err(); }
      verify(err != null);
      verify(err.GetType() == System.Type.GetType("Fan.Sys.IOErr"));
      verify(err.message() == null);

//VERR      verifyErr("Void f() { throw 6 }", "Must throw Err, not 'sys::Int'");
    }

  }
}

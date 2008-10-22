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
      object[] fx = new object[] { Boolean.False, Long.valueOf(-1) };
      object[] tx = new object[] { Boolean.True,  Long.valueOf(-1) };

      // no else - return
      verify("Long f(Boolean b) { if (b) return 2; return 3; }",       t, Long.valueOf(2));
      verify("Long f(Boolean b) { if (b) return 2; return 3; }",       f, Long.valueOf(3));
      verify("Long f(Boolean b) { if (b) { return 2; } return 3; }",   t, Long.valueOf(2));
      verify("Long f(Boolean b) { if (b) { return 2; } return 3; }",   f, Long.valueOf(3));

      // else - return
      verify("Long f(Boolean b) { if (b) return 2; else return 3; }",  t, Long.valueOf(2));
      verify("Long f(Boolean b) { if (b) return 2; else return 3; }",  f, Long.valueOf(3));
      verify("Long f(Boolean b) { if (b) { return 2; } else { return 3; } }",  t, Long.valueOf(2));
      verify("Long f(Boolean b) { if (b) { return 2; } else { return 3; } }",  f, Long.valueOf(3));

      // no else - no return
      verify("Long f(Boolean b, Long x) { if (b) x = 2; return x; }", tx, Long.valueOf(2));
      verify("Long f(Boolean b, Long x) { if (b) x = 2; return x; }", fx, Long.valueOf(-1));
      verify("Long f(Boolean b, Long x) { if (b) { x = 2; } return x; }", tx, Long.valueOf(2));
      verify("Long f(Boolean b, Long x) { if (b) { x = 2; } return x; }", fx, Long.valueOf(-1));

      // else - no return
      verify("Long f(Boolean b, Long x) { if (b) { x = 2; } else { x = 3; } return x; }", tx, Long.valueOf(2));
      verify("Long f(Boolean b, Long x) { if (b) { x = 2; } else { x = 3; } return x; }", fx, Long.valueOf(3));

      // if/else if/else - return
      verify("Long f(Long x) { if (x == 0) return 10; else if (x == 1) return 11; else return 12;  }", MakeInts(0), Long.valueOf(10));
      verify("Long f(Long x) { if (x == 0) return 10; else if (x == 1) return 11; else return 12;  }", MakeInts(1), Long.valueOf(11));
      verify("Long f(Long x) { if (x == 0) return 10; else if (x == 1) return 11; else return 12;  }", MakeInts(2), Long.valueOf(12));

      // if/else if - no return
      verify("Long f(Long x, Long y) { if (x == 0) y = 10; else if (x == 1) y = 11; return y;}", MakeInts(0, -1), Long.valueOf(10));
      verify("Long f(Long x, Long y) { if (x == 0) y = 10; else if (x == 1) y = 11; return y;}", MakeInts(1, -1), Long.valueOf(11));
      verify("Long f(Long x, Long y) { if (x == 0) y = 10; else if (x == 1) y = 11; return y;}", MakeInts(2, -1), Long.valueOf(-1));

      // if/else if/else - no return
      verify("Long f(Long x, Long y) { if (x == 0) y = 10; else if (x == 1) y = 11; else y = 12; return y;}", MakeInts(0, -1), Long.valueOf(10));
      verify("Long f(Long x, Long y) { if (x == 0) y = 10; else if (x == 1) y = 11; else y = 12; return y;}", MakeInts(1, -1), Long.valueOf(11));
      verify("Long f(Long x, Long y) { if (x == 0) y = 10; else if (x == 1) y = 11; else y = 12; return y;}", MakeInts(2, -1), Long.valueOf(12));

      // if/else if/else if/else if/else - return
      verify("Long f(Long x) { if (x == 0) return 10; else if (x == 1) return 11; else if (x == 2) return 12; else if (x == 3) return 13; else return 14;}", MakeInts(0), Long.valueOf(10));
      verify("Long f(Long x) { if (x == 0) return 10; else if (x == 1) return 11; else if (x == 2) return 12; else if (x == 3) return 13; else return 14;}", MakeInts(1), Long.valueOf(11));
      verify("Long f(Long x) { if (x == 0) return 10; else if (x == 1) return 11; else if (x == 2) return 12; else if (x == 3) return 13; else return 14;}", MakeInts(2), Long.valueOf(12));
      verify("Long f(Long x) { if (x == 0) return 10; else if (x == 1) return 11; else if (x == 2) return 12; else if (x == 3) return 13; else return 14;}", MakeInts(3), Long.valueOf(13));
      verify("Long f(Long x) { if (x == 0) return 10; else if (x == 1) return 11; else if (x == 2) return 12; else if (x == 3) return 13; else return 14;}", MakeInts(4), Long.valueOf(14));

      // if { if/else } else { if/else } - return
      verify("Long f(Boolean x, Boolean y) { if (x) { if (y) return 3; else return 2; } else { if (y) return 1; else return 0; } }", MakeBools(false, false), Long.valueOf(0));
      verify("Long f(Boolean x, Boolean y) { if (x) { if (y) return 3; else return 2; } else { if (y) return 1; else return 0; } }", MakeBools(false, true),  Long.valueOf(1));
      verify("Long f(Boolean x, Boolean y) { if (x) { if (y) return 3; else return 2; } else { if (y) return 1; else return 0; } }", MakeBools(true,  false), Long.valueOf(2));
      verify("Long f(Boolean x, Boolean y) { if (x) { if (y) return 3; else return 2; } else { if (y) return 1; else return 0; } }", MakeBools(true,  true),  Long.valueOf(3));

      // errors
//VERR      verifyErr("Long f() { if (5) return 1; else return 2 }", "If condition must be Boolean, not 'sys::Long'");
    }

  //////////////////////////////////////////////////////////////////////////
  // While Statement
  //////////////////////////////////////////////////////////////////////////

    void verifyWhile()
    {
      // basic loop
      verify("static Long f(Long x) { while (x < 5) x++; return x }", MakeInts(2), Long.valueOf(5));

      // count to field
      members = "x := 0\n";
      verify("Long f(Long to) { while (x < to) x = x + 1\n return x }", MakeInts(3), Long.valueOf(3));
      verify("Long f(Long to) { while (x < to) x = x + 1;  return x }", MakeInts(4), Long.valueOf(4));
      verify("Long f(Long to) { while (x < to) {x++} return x }", MakeInts(5), Long.valueOf(5));

      // break
      verify("Long f(Long x) { while (true) { x++; if (x == 7) break } return x }", MakeInts(0), Long.valueOf(7));

      // two teir break
      verify("Long f(Long x) { i:=0; j:=0; while (true) { i++; /*echo(\"i=\"+i+\" j=\"+j);*/ if (i > 3) break; j=0; while (j!=5) {j++; x++; /*echo(\"  j=\"+j+\" x=\"+x);*/} } return x }", MakeInts(0), Long.valueOf(15));

      // continue
      verify("Long f(Long x) { i:=0; while (i<10) { i++; if (i%2 == 0) continue; x++ } return x }", MakeInts(0), Long.valueOf(5));

      // two teir break & continue
      verify("Long f(Long x) { i:=0; j:=0; while (i<10) { i++; if (i%2 == 0) continue; j = 0; while (true) { j++; if (j>10) break; x++ } } return x }", MakeInts(0), Long.valueOf(50));

      // errors
//VERR      verifyErr("Void f() { while (5) {} }", "While condition must be Boolean, not 'sys::Long'");
//VERR      verifyErr("Void f() { break; }",      "Break outside of loop (break is implicit in switch)");
//VERR      verifyErr("Void f() { continue; }",   "Continue outside of loop");
    }


  //////////////////////////////////////////////////////////////////////////
  // For Statement
  //////////////////////////////////////////////////////////////////////////

    void verifyFor()
    {
      // basic loop
      verify("static Long f() { r:=0; for (x:=0; x<10; ++x) r++; return r }", Long.valueOf(10));

      // init as expr, without init
      verify("static Long f() { r:=0; for (Long x:=0; x<10; ++x) r++; return r }", Long.valueOf(10));
      verify("static Long f() { r:=0; x:=0; for (x=0; x<10; ++x) r++; return r }", Long.valueOf(10));
      verify("static Long f() { r:=0; x:=0; for (; x<10; ++x) r++; return r }", Long.valueOf(10));

      // without update
      verify("static Long f() { r:=0; for (x:=0; x<10;) { r++; x++; } return r }", Long.valueOf(10));

      // without cond, break
      verify("Long f() { x:=0; for (;;++x) if (x == 7) break; return x;}", Long.valueOf(7));

      // two breaks
      verify("Long f(Boolean b) { x:=0; for (;;) { if (b) {x=1; break} else {x=-1; break}} return x;}", MakeBools(false), Long.valueOf(-1));
      verify("Long f(Boolean b) { x:=0; for (;;) { if (b) {x=1; break} else {x=-1; break}} return x;}", MakeBools(true), Long.valueOf(+1));

      // two tier break
      verify("Long f() {" +
        "x :=0 ;" +
        "for (i:=0; true; ++i)" +
        "{" +
        "  if (i==3) break;" +
        "  for (Long j:=0;; ++j) { if (j==5) break; x++; }" +
        "}" +
        "return x; }", Long.valueOf(15));

      // continue
      verify("Long f() { x:=0; for (i:=0;i<10;) { i++; if (i%2 == 0) continue; x++ } return x }", Long.valueOf(5));

      // reuse vars in for blocks
      verify("Long f() { x:=0; for (Long i:=0; i<3; ++i) x++; for (Long i:=0; i<2; ++i) x++; return x;}", Long.valueOf(5));

      // errors
//VERR      verifyErr("Void f() { for (;\"x\";) {} }", "For condition must be Boolean, not 'sys::string'");
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
      try { verify("Long f() { throw Err.make(\"bad\") }", null); }
      catch (System.Reflection.TargetInvocationException e) { err = (e.InnerException as Err.Val).err(); }
      verify(err != null);
      verify(err.GetType() == System.Type.GetType("Fan.Sys.Err"));
      verify(err.message().Equals("bad"));

      err = null;
      try { verify("Long f() { throw IOErr.make(); return 0; }", null); }
      catch (System.Reflection.TargetInvocationException e) { err = (e.InnerException as Err.Val).err(); }
      verify(err != null);
      verify(err.GetType() == System.Type.GetType("Fan.Sys.IOErr"));
      verify(err.message() == null);

//VERR      verifyErr("Void f() { throw 6 }", "Must throw Err, not 'sys::Long'");
    }

  }
}
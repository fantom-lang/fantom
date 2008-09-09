//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Oct 06  Andy Frank  Creation
//

using Object = System.Object;
using Fan.Sys;

namespace Fanx.Test
{
  /// <summary>
  /// ExprTest
  /// </summary>
  public class ExprTest : CompileTest
  {

  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    public override void Run()
    {
      verifyCond();
      verifyEquality();
      verifyComparision();
      verifyNegate();
      verifyMultiply();
      verifyDivide();
      verifyMod();
      verifyBitwise();
      verifyAdd();
      verifySub();
      verifyOrderAndPrecedence();
      verifyIncrementDecrement();
      verifyPlusMinusCombos();
      verifyStrAdd();
      verifyLocalVar();
      verifyFieldGet();
      verifyFieldSet();
      verifyCalls();
      verifyParens();
      verifyCasts();
    }

  //////////////////////////////////////////////////////////////////////////
  // || and &&
  //////////////////////////////////////////////////////////////////////////

    void verifyCond()
    {
      verify("Bool f(Bool a, Bool b) { return a || b;  }", tt, or(tt));
      verify("Bool f(Bool a, Bool b) { return a || b;  }", ft, or(ft));
      verify("Bool f(Bool a, Bool b) { return a || b;  }", tf, or(tf));
      verify("Bool f(Bool a, Bool b) { return a || b;  }", ff, or(ff));

      verify("Bool f(Bool a, Bool b, Bool c) { return a || b || c;  }", ttt, or(ttt));
      verify("Bool f(Bool a, Bool b, Bool c) { return a || b || c;  }", ftt, or(ftt));
      verify("Bool f(Bool a, Bool b, Bool c) { return a || b || c;  }", tft, or(tft));
      verify("Bool f(Bool a, Bool b, Bool c) { return a || b || c;  }", ttf, or(ttf));
      verify("Bool f(Bool a, Bool b, Bool c) { return a || b || c;  }", fft, or(fft));
      verify("Bool f(Bool a, Bool b, Bool c) { return a || b || c;  }", ftf, or(ftf));
      verify("Bool f(Bool a, Bool b, Bool c) { return a || b || c;  }", tff, or(tff));
      verify("Bool f(Bool a, Bool b, Bool c) { return a || b || c;  }", fff, or(fff));

      verify("Bool f(Bool a, Bool b) { return a && b;  }", tt, and(tt));
      verify("Bool f(Bool a, Bool b) { return a && b;  }", ft, and(ft));
      verify("Bool f(Bool a, Bool b) { return a && b;  }", tf, and(tf));
      verify("Bool f(Bool a, Bool b) { return a && b;  }", ff, and(ff));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b && c;  }", ttt, and(ttt));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b && c;  }", ftt, and(ftt));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b && c;  }", tft, and(tft));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b && c;  }", ttf, and(ttf));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b && c;  }", fft, and(fft));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b && c;  }", ftf, and(ftf));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b && c;  }", tff, and(tff));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b && c;  }", fff, and(fff));

      verify("Bool f(Bool a, Bool b, Bool c) { return a || b && c;  }", ttt, MakeBool(true ||true &&true));
      verify("Bool f(Bool a, Bool b, Bool c) { return a || b && c;  }", ftt, MakeBool(false||true &&true));
      verify("Bool f(Bool a, Bool b, Bool c) { return a || b && c;  }", tft, MakeBool(true ||false&&true));
      verify("Bool f(Bool a, Bool b, Bool c) { return a || b && c;  }", ttf, MakeBool(true ||true &&false));
      verify("Bool f(Bool a, Bool b, Bool c) { return a || b && c;  }", fft, MakeBool(false||false&&true));
      verify("Bool f(Bool a, Bool b, Bool c) { return a || b && c;  }", tff, MakeBool(true ||false&&false));
      verify("Bool f(Bool a, Bool b, Bool c) { return a || b && c;  }", fff, MakeBool(false||false&&false));

      verify("Bool f(Bool a, Bool b, Bool c) { return a && b || c; }",  ttt, MakeBool(true &&true ||true));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b || c; }",  ftt, MakeBool(false&&true ||true));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b || c; }",  tft, MakeBool(true &&false||true));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b || c; }",  ttf, MakeBool(true &&true ||false));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b || c; }",  fft, MakeBool(false&&false||true));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b || c; }",  ftf, MakeBool(false&&true ||false));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b || c; }",  tff, MakeBool(true &&false||false));
      verify("Bool f(Bool a, Bool b, Bool c) { return a && b || c; }",  fff, MakeBool(false&&false||false));

      verify("Bool f(Bool a) { return !a; }",  MakeBools(true), MakeBool(false));
      verify("Bool f(Bool a) { return !a; }",  MakeBools(false), MakeBool(true));
      verify("Bool f() { return !true; }",     MakeBool(false));
      verify("Bool f() { return !false; }",    MakeBool(true));

      verify("Bool f(Bool a, Bool b) { return !a && !b; }", tt, MakeBool(false));
      verify("Bool f(Bool a, Bool b) { return !a && !b; }", ff, MakeBool(true));
    }

    Bool or(Bool[] b)
    {
      bool r = b[0].val;
      for (int i=1; i<b.Length; i++) r = r || b[i].val;
      return Bool.make(r);
    }

    Bool and(Bool[] b)
    {
      bool r = b[0].val;
      for (int i=1; i<b.Length; i++) r = r && b[i].val;
      return Bool.make(r);
    }

  //////////////////////////////////////////////////////////////////////////
  // == and !=
  //////////////////////////////////////////////////////////////////////////

    void verifyEquality()
    {
      //
      // bool
      //
      verify("static Bool f(Bool a, Bool b) { return a == b; }", tt, Bool.True);
      verify("static Bool f(Bool a, Bool b) { return a == b; }", ft, Bool.False);
      verify("static Bool f(Bool a, Bool b) { return a == b; }", tf, Bool.False);
      verify("static Bool f(Bool a, Bool b) { return a == b; }", ff, Bool.True);

      verify("static Bool f(Bool a, Bool b) { return a != b; }", tt, Bool.False);
      verify("static Bool f(Bool a, Bool b) { return a != b; }", ft, Bool.True);
      verify("static Bool f(Bool a, Bool b) { return a != b; }", tf, Bool.True);
      verify("static Bool f(Bool a, Bool b) { return a != b; }", ff, Bool.False);

      verify("static Bool f(Bool a, Bool b) { return a == b; }", nn, Bool.True);
      verify("static Bool f(Bool a, Bool b) { return a == b; }", tn, Bool.False);
      verify("static Bool f(Bool a, Bool b) { return a == b; }", nt, Bool.False);

      verify("static Bool f(Bool a, Bool b) { return a != b; }", nn, Bool.False);
      verify("static Bool f(Bool a, Bool b) { return a != b; }", tn, Bool.True);
      verify("static Bool f(Bool a, Bool b) { return a != b; }", nt, Bool.True);

      verify("static Bool f(Bool a, Bool b, Bool c) { return a == b == c; }", ttt, Bool.make(true  == true  == true));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a == b == c; }", ftt, Bool.make(false == true  == true));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a == b == c; }", tft, Bool.make(true  == false == true));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a == b == c; }", ttf, Bool.make(true  == true  == false));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a == b == c; }", fft, Bool.make(false == false == true));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a == b == c; }", tff, Bool.make(true  == false == false));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a == b == c; }", ftf, Bool.make(false == true  == false));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a == b == c; }", fff, Bool.make(false == false == false));

      verify("static Bool f(Bool a, Bool b, Bool c) { return a != b != c; }", ttt, Bool.make(true  != true  != true));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a != b != c; }", ftt, Bool.make(false != true  != true));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a != b != c; }", tft, Bool.make(true  != false != true));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a != b != c; }", ttf, Bool.make(true  != true  != false));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a != b != c; }", fft, Bool.make(false != false != true));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a != b != c; }", tff, Bool.make(true  != false != false));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a != b != c; }", ftf, Bool.make(false != true  != false));
      verify("static Bool f(Bool a, Bool b, Bool c) { return a != b != c; }", fff, Bool.make(false != false != false));

      //
      // int
      //
      verify("static Bool f(Int a, Int b) { return a == b; }", MakeInts(0, 0),   Bool.True);
      verify("static Bool f(Int a, Int b) { return a == b; }", MakeInts(1, 0),   Bool.False);
      verify("static Bool f(Int a, Int b) { return a == b; }", MakeInts(0, 1),   Bool.False);
      verify("static Bool f(Int a, Int b) { return a == b; }", MakeInts(1, 1),   Bool.True);
      verify("static Bool f(Int a, Int b) { return a == b; }", MakeInts(-1, -1), Bool.True);
      verify("static Bool f(Int a, Int b) { return a == b; }", MakeInts(-1, -2), Bool.False);
      verify("static Bool f(Int a, Int b) { return a != b; }", MakeInts(0, 0),   Bool.False);
      verify("static Bool f(Int a, Int b) { return a != b; }", MakeInts(1, 0),   Bool.True);
      verify("static Bool f(Int a, Int b) { return a != b; }", MakeInts(0, 1),   Bool.True);
      verify("static Bool f(Int a, Int b) { return a != b; }", MakeInts(1, 1),   Bool.False);
      verify("static Bool f(Int a, Int b) { return a != b; }", MakeInts(77, -3), Bool.True);
      verify("static Bool f(Int a, Int b) { return a == b; }", new Obj[] { null,null  },     Bool.True);
      verify("static Bool f(Int a, Int b) { return a == b; }", new Obj[] { Int.Zero, null }, Bool.False);
      verify("static Bool f(Int a, Int b) { return a == b; }", new Obj[] { null, Int.Zero }, Bool.False);
      verify("static Bool f(Int a, Int b) { return a != b; }", new Obj[] { null,null  },     Bool.False);
      verify("static Bool f(Int a, Int b) { return a != b; }", new Obj[] { Int.Zero, null }, Bool.True);
      verify("static Bool f(Int a, Int b) { return a != b; }", new Obj[] { null, Int.Zero }, Bool.True);

      //
      // floats
      //
      verify("static Bool f(Float a, Float b) { return a == b; }", MakeFloats(0, 0),   Bool.True);
      verify("static Bool f(Float a, Float b) { return a == b; }", MakeFloats(1, 0),   Bool.False);
      verify("static Bool f(Float a, Float b) { return a == b; }", MakeFloats(0, 1),   Bool.False);
      verify("static Bool f(Float a, Float b) { return a == b; }", MakeFloats(1, 1),   Bool.True);
      verify("static Bool f(Float a, Float b) { return a == b; }", MakeFloats(-1, -1), Bool.True);
      verify("static Bool f(Float a, Float b) { return a == b; }", MakeFloats(-1, -2), Bool.False);
      verify("static Bool f(Float a, Float b) { return a != b; }", MakeFloats(0, 0),   Bool.False);
      verify("static Bool f(Float a, Float b) { return a != b; }", MakeFloats(1, 0),   Bool.True);
      verify("static Bool f(Float a, Float b) { return a != b; }", MakeFloats(0, 1),   Bool.True);
      verify("static Bool f(Float a, Float b) { return a != b; }", MakeFloats(1, 1),   Bool.False);
      verify("static Bool f(Float a, Float b) { return a != b; }", MakeFloats(77, -3), Bool.True);
      verify("static Bool f(Float a, Float b) { return a == b; }", new Obj[] { null,null  },     Bool.True);
      verify("static Bool f(Float a, Float b) { return a == b; }", new Obj[] { Float.m_zero, null }, Bool.False);
      verify("static Bool f(Float a, Float b) { return a == b; }", new Obj[] { null, Float.m_zero }, Bool.False);
      verify("static Bool f(Float a, Float b) { return a != b; }", new Obj[] { null,null  },     Bool.False);
      verify("static Bool f(Float a, Float b) { return a != b; }", new Obj[] { Float.m_zero, null }, Bool.True);
      verify("static Bool f(Float a, Float b) { return a != b; }", new Obj[] { null, Float.m_zero }, Bool.True);

      //
      // str
      //
      verify("static Bool f(Str a, Str b) { return a == b; }", MakeStrs(null, null), Bool.True);
      verify("static Bool f(Str a, Str b) { return a == b; }", MakeStrs("a",  null), Bool.False);
      verify("static Bool f(Str a, Str b) { return a == b; }", MakeStrs(null, "a"),  Bool.False);
      verify("static Bool f(Str a, Str b) { return a == b; }", MakeStrs("a", "a"),   Bool.True);
      verify("static Bool f(Str a, Str b) { return a == b; }", MakeStrs("a", "b"),   Bool.False);
      verify("static Bool f(Str a, Str b) { return a != b; }", MakeStrs(null, null), Bool.False);
      verify("static Bool f(Str a, Str b) { return a != b; }", MakeStrs("a",  null), Bool.True);
      verify("static Bool f(Str a, Str b) { return a != b; }", MakeStrs(null, "a"),  Bool.True);
      verify("static Bool f(Str a, Str b) { return a != b; }", MakeStrs("a", "a"),   Bool.False);
      verify("static Bool f(Str a, Str b) { return a != b; }", MakeStrs("a", "b"),   Bool.True);

      //
      // Duration
      //
      verify("static Bool f(Duration a, Duration b) { return a == b; }", MakeDurs(0, 0),  Bool.True);
      verify("static Bool f(Duration a, Duration b) { return a == b; }", MakeDurs(20, 0), Bool.False);
      verify("static Bool f(Duration a, Duration b) { return a != b; }", MakeDurs(0, 0),  Bool.False);
      verify("static Bool f(Duration a, Duration b) { return a != b; }", MakeDurs(20, 0), Bool.True);

      //
      // same ===
      //
      verify("static Bool f() { return null === null; }",        Bool.True);
      verify("static Bool f() { return 5 === null; }",           Bool.False);
      verify("static Bool f() { return null === 5; }",           Bool.False);
      verify("static Bool f() { return 5 === 5; }",              Bool.True);
      verify("static Bool f() { return \"x\" === \"x\"; }",      Bool.True);
      verify("static Bool f() { return \"x\" === \"y\"; }",      Bool.False);
      verify("static Bool f() { return !(\"x\" === \"y\"); }",   Bool.True);
      verify("static Bool f(Int x, Int y) { return x === y; }",  MakeInts(256, 256), Bool.True);
      verify("static Bool f(Int x, Int y) { return x === y; }",  MakeInts(2568888, 2568888), Bool.False);

      // auto-cast matrix
      /*
      verify("Bool f(Int a, Float b) { return a == b; }", new Object[] { Int.make(4), Float.make(4) }, Bool.True);
      verify("Bool f(Int a, Float b) { return a != b; }", new Object[] { Int.make(4), Float.make(4) }, Bool.False);
      verify("Bool f(Float a, Int b) { return a == b; }", new Object[] { Float.make(-99), Int.make(-99) }, Bool.True);
      verify("Bool f(Float a, Int b) { return a != b; }", new Object[] { Float.make(-99), Int.make(-99) }, Bool.False);
      */
    }

  //////////////////////////////////////////////////////////////////////////
  // < <= > >= <=>
  //////////////////////////////////////////////////////////////////////////

    void verifyComparision()
    {
      //
      // MakeInts
      //
      verify("static Bool f(Int a, Int b) { return a < b; }", MakeInts(0, 0),  Bool.make(0 < 0));
      verify("static Bool f(Int a, Int b) { return a < b; }", MakeInts(1, 0),  Bool.make(1 < 0));
      verify("static Bool f(Int a, Int b) { return a < b; }", MakeInts(0, 1),  Bool.make(0 < 1));
      verify("static Bool f(Int a, Int b) { return a < b; }", MakeInts(1, 1),  Bool.make(1 < 1));
      verify("static Bool f(Int a, Int b) { return a < b; }", new Obj[] { null, null },      Bool.False);
      verify("static Bool f(Int a, Int b) { return a < b; }", new Obj[] { Int.Zero, null },  Bool.False);
      verify("static Bool f(Int a, Int b) { return a < b; }", new Obj[] { null, Int.Zero },  Bool.True);

      verify("static Bool f(Int a, Int b) { return a <= b; }", MakeInts(0,  0),   Bool.make(0  <= 0));
      verify("static Bool f(Int a, Int b) { return a <= b; }", MakeInts(-1, 0),   Bool.make(-1 <= 0));
      verify("static Bool f(Int a, Int b) { return a <= b; }", MakeInts(0,  -1),  Bool.make(0  <= -1));
      verify("static Bool f(Int a, Int b) { return a <= b; }", MakeInts(-1, -1),  Bool.make(-1 <= -1));
      verify("static Bool f(Int a, Int b) { return a <= b; }", new Obj[] { null, null },      Bool.True);
      verify("static Bool f(Int a, Int b) { return a <= b; }", new Obj[] { Int.Zero, null },  Bool.False);
      verify("static Bool f(Int a, Int b) { return a <= b; }", new Obj[] { null, Int.Zero },  Bool.True);

      verify("static Bool f(Int a, Int b) { return a > b; }", MakeInts(4, 4),  Bool.make(4 > 4));
      verify("static Bool f(Int a, Int b) { return a > b; }", MakeInts(7, 4),  Bool.make(7 > 4));
      verify("static Bool f(Int a, Int b) { return a > b; }", MakeInts(4, 7),  Bool.make(4 > 7));
      verify("static Bool f(Int a, Int b) { return a > b; }", MakeInts(7, 7),  Bool.make(7 > 7));
      verify("static Bool f(Int a, Int b) { return a > b; }", new Obj[] { null, null },      Bool.False);
      verify("static Bool f(Int a, Int b) { return a > b; }", new Obj[] { Int.Zero, null },  Bool.True);
      verify("static Bool f(Int a, Int b) { return a > b; }", new Obj[] { null, Int.Zero },  Bool.False);

      verify("static Bool f(Int a, Int b) { return a >= b; }", MakeInts(-2, -2),  Bool.make(-2 >= -2));
      verify("static Bool f(Int a, Int b) { return a >= b; }", MakeInts(+2, -2),  Bool.make(+2 >= -2));
      verify("static Bool f(Int a, Int b) { return a >= b; }", MakeInts(-2, +2),  Bool.make(-2 >= +2));
      verify("static Bool f(Int a, Int b) { return a >= b; }", MakeInts(+2, +2),  Bool.make(+2 >= +2));
      verify("static Bool f(Int a, Int b) { return a >= b; }", new Obj[] { null, null },      Bool.True);
      verify("static Bool f(Int a, Int b) { return a >= b; }", new Obj[] { Int.Zero, null },  Bool.True);
      verify("static Bool f(Int a, Int b) { return a >= b; }", new Obj[] { null, Int.Zero },  Bool.False);

      verify("static Int f(Int a, Int b) { return a <=> b; }", MakeInts(3, 2),  Int.make(1));
      verify("static Int f(Int a, Int b) { return a <=> b; }", MakeInts(3, 3),  Int.make(0));
      verify("static Int f(Int a, Int b) { return a <=> b; }", MakeInts(2, 3),  Int.make(-1));
      verify("static Int f(Int a, Int b) { return a <=> b; }", new Obj[] { null, null },      Int.make(0));
      verify("static Int f(Int a, Int b) { return a <=> b; }", new Obj[] { Int.Zero, null },  Int.make(1));
      verify("static Int f(Int a, Int b) { return a <=> b; }", new Obj[] { null, Int.Zero },  Int.make(-1));

      //
      // MakeFloats
      //
      verify("static Bool f(Float a, Float b) { return a < b; }", MakeFloats(0, 0),  Bool.make(0 < 0));
      verify("static Bool f(Float a, Float b) { return a < b; }", MakeFloats(1, 0),  Bool.make(1 < 0));
      verify("static Bool f(Float a, Float b) { return a < b; }", MakeFloats(0, 1),  Bool.make(0 < 1));
      verify("static Bool f(Float a, Float b) { return a < b; }", MakeFloats(1, 1),  Bool.make(1 < 1));

      verify("static Bool f(Float a, Float b) { return a <= b; }", MakeFloats(0,  0),   Bool.make(0  <= 0));
      verify("static Bool f(Float a, Float b) { return a <= b; }", MakeFloats(-1, 0),   Bool.make(-1 <= 0));
      verify("static Bool f(Float a, Float b) { return a <= b; }", MakeFloats(0,  -1),  Bool.make(0  <= -1));
      verify("static Bool f(Float a, Float b) { return a <= b; }", MakeFloats(-1, -1),  Bool.make(-1 <= -1));

      verify("static Bool f(Float a, Float b) { return a > b; }", MakeFloats(4, 4),  Bool.make(4 > 4));
      verify("static Bool f(Float a, Float b) { return a > b; }", MakeFloats(7, 4),  Bool.make(7 > 4));
      verify("static Bool f(Float a, Float b) { return a > b; }", MakeFloats(4, 7),  Bool.make(4 > 7));
      verify("static Bool f(Float a, Float b) { return a > b; }", MakeFloats(7, 7),  Bool.make(7 > 7));

      verify("static Bool f(Float a, Float b) { return a >= b; }", MakeFloats(-2, -2),  Bool.make(-2 >= -2));
      verify("static Bool f(Float a, Float b) { return a >= b; }", MakeFloats(+2, -2),  Bool.make(+2 >= -2));
      verify("static Bool f(Float a, Float b) { return a >= b; }", MakeFloats(-2, +2),  Bool.make(-2 >= +2));
      verify("static Bool f(Float a, Float b) { return a >= b; }", MakeFloats(+2, +2),  Bool.make(+2 >= +2));

      verify("static Int f(Float a, Float b) { return a <=> b; }", MakeFloats(3, 2),  Int.make(1));
      verify("static Int f(Float a, Float b) { return a <=> b; }", MakeFloats(3, 3),  Int.make(0));
      verify("static Int f(Float a, Float b) { return a <=> b; }", MakeFloats(2, 3),  Int.make(-1));

      //
      // bool
      //
      verify("static Bool f(Bool a, Bool b) { return a < b; }", ft,  Bool.True);
      verify("static Bool f(Bool a, Bool b) { return a < b; }", ff,  Bool.False);
      verify("static Bool f(Bool a, Bool b) { return a < b; }", tf,  Bool.False);

      verify("static Bool f(Bool a, Bool b) { return a <= b; }", ft,  Bool.True);
      verify("static Bool f(Bool a, Bool b) { return a <= b; }", ff,  Bool.True);
      verify("static Bool f(Bool a, Bool b) { return a <= b; }", tf,  Bool.False);

      verify("static Bool f(Bool a, Bool b) { return a > b; }", ft,  Bool.False);
      verify("static Bool f(Bool a, Bool b) { return a > b; }", ff,  Bool.False);
      verify("static Bool f(Bool a, Bool b) { return a > b; }", tf,  Bool.True);

      verify("static Bool f(Bool a, Bool b) { return a >= b; }", ft,  Bool.False);
      verify("static Bool f(Bool a, Bool b) { return a >= b; }", ff,  Bool.True);
      verify("static Bool f(Bool a, Bool b) { return a >= b; }", tf,  Bool.True);

      verify("static Int f(Bool a, Bool b) { return a <=> b; }", tf,  Int.make(1));
      verify("static Int f(Bool a, Bool b) { return a <=> b; }", tt,  Int.make(0));
      verify("static Int f(Bool a, Bool b) { return a <=> b; }", ft,  Int.make(-1));

      //
      // str
      //
      verify("static Bool f(Str a, Str b) { return a < b; }", MakeStrs("a", "b"),  Bool.True);
      verify("static Bool f(Str a, Str b) { return a < b; }", MakeStrs("a", "a"),  Bool.False);
      verify("static Bool f(Str a, Str b) { return a < b; }", MakeStrs("b", "a"),  Bool.False);

      verify("static Bool f(Str a, Str b) { return a <= b; }", MakeStrs("a", "b"),  Bool.True);
      verify("static Bool f(Str a, Str b) { return a <= b; }", MakeStrs("a", "a"),  Bool.True);
      verify("static Bool f(Str a, Str b) { return a <= b; }", MakeStrs("b", "a"),  Bool.False);

      verify("static Bool f(Str a, Str b) { return a > b; }", MakeStrs("a", "b"),  Bool.False);
      verify("static Bool f(Str a, Str b) { return a > b; }", MakeStrs("a", "a"),  Bool.False);
      verify("static Bool f(Str a, Str b) { return a > b; }", MakeStrs("b", "a"),  Bool.True);

      verify("static Bool f(Str a, Str b) { return a >= b; }", MakeStrs("a", "b"),  Bool.False);
      verify("static Bool f(Str a, Str b) { return a >= b; }", MakeStrs("a", "a"),  Bool.True);
      verify("static Bool f(Str a, Str b) { return a >= b; }", MakeStrs("b", "a"),  Bool.True);

      verify("static Int f(Str a, Str b) { return a <=> b; }", MakeStrs("a", "b"),  Int.make(-1));
      verify("static Int f(Str a, Str b) { return a <=> b; }", MakeStrs("a", "a"),  Int.make(0));
      verify("static Int f(Str a, Str b) { return a <=> b; }", MakeStrs("b", "a"),  Int.make(1));

      verify("static Int f(Str a, Str b) { return a <=> b; }", MakeStrs(null, null), Int.make(0));
      verify("static Int f(Str a, Str b) { return a <=> b; }", MakeStrs(null, "a"),  Int.make(-1));
      verify("static Int f(Str a, Str b) { return a <=> b; }", MakeStrs("b", null),  Int.make(1));

      //
      // Duration
      //
      verify("static Bool f(Duration a, Duration b) { return a < b; }", MakeDurs(3, 9),  Bool.True);
      verify("static Bool f(Duration a, Duration b) { return a < b; }", MakeDurs(3, 3),  Bool.False);
      verify("static Bool f(Duration a, Duration b) { return a < b; }", MakeDurs(9, 3),  Bool.False);

      verify("static Bool f(Duration a, Duration b) { return a <= b; }", MakeDurs(3, 9),  Bool.True);
      verify("static Bool f(Duration a, Duration b) { return a <= b; }", MakeDurs(3, 3),  Bool.True);
      verify("static Bool f(Duration a, Duration b) { return a <= b; }", MakeDurs(9, 3),  Bool.False);

      verify("static Bool f(Duration a, Duration b) { return a > b; }", MakeDurs(3, 9),  Bool.False);
      verify("static Bool f(Duration a, Duration b) { return a > b; }", MakeDurs(3, 3),  Bool.False);
      verify("static Bool f(Duration a, Duration b) { return a > b; }", MakeDurs(9, 3),  Bool.True);

      verify("static Bool f(Duration a, Duration b) { return a >= b; }", MakeDurs(3, 9),  Bool.False);
      verify("static Bool f(Duration a, Duration b) { return a >= b; }", MakeDurs(3, 3),  Bool.True);
      verify("static Bool f(Duration a, Duration b) { return a >= b; }", MakeDurs(9, 3),  Bool.True);

      verify("static Int f(Duration a, Duration b) { return a <=> b; }", MakeDurs(3, 9),  Int.make(-1));
      verify("static Int f(Duration a, Duration b) { return a <=> b; }", MakeDurs(3, 3),  Int.make(0));
      verify("static Int f(Duration a, Duration b) { return a <=> b; }", MakeDurs(9, 3),  Int.make(1));

      //
      // auto-cast matrix
      //
      /* TODO
      verify("Bool f(Int a, Float b) { return a < b; }",  new Object[] { Int.make(-6), Float.make(-7)  }, Bool.False);
      verify("Bool f(Int a, Float b) { return a <= b; }", new Object[] { Int.make(-6), Float.make(-7)  }, Bool.False);
      verify("Bool f(Int a, Float b) { return a > b; }",  new Object[] { Int.make(-6), Float.make(-7)  }, Bool.True);
      verify("Bool f(Int a, Float b) { return a >= b; }", new Object[] { Int.make(-6), Float.make(-7)  }, Bool.True);

      verify("Bool f(Float a, Int b) { return a < b; }",  new Object[] { Float.make(99), Int.make(-99) }, Bool.False);
      verify("Bool f(Float a, Int b) { return a <= b; }", new Object[] { Float.make(99), Int.make(-99) }, Bool.False);
      verify("Bool f(Float a, Int b) { return a > b; }",  new Object[] { Float.make(99), Int.make(-99) }, Bool.True);
      verify("Bool f(Float a, Int b) { return a >= b; }", new Object[] { Float.make(99), Int.make(-99) }, Bool.True);

      verify("Int f(Float a, Int b) { return a <=> b; }", new Object[] { Float.make(9), Int.make(-9) }, Int.make(1));
      verify("Int f(Float a, Int b) { return a <=> b; }", new Object[] { Float.make(9), Int.make(9) },  Int.make(0));
      verify("Int f(Float a, Int b) { return a <=> b; }", new Object[] { Float.make(9), Int.make(99) }, Int.make(-1));
      verify("Int f(Float a, Int b) { return a <=> b; }", new Object[] { Float.make(9), Int.make(-9) }, Int.make(1));
      verify("Int f(Float a, Int b) { return a <=> b; }", new Object[] { Float.make(9), Int.make(9) },  Int.make(0));
      verify("Int f(Float a, Int b) { return a <=> b; }", new Object[] { Float.make(9), Int.make(99) }, Int.make(-1));
      */
    }

  //////////////////////////////////////////////////////////////////////////
  // Negate
  //////////////////////////////////////////////////////////////////////////

    void verifyNegate()
    {
      // MakeInts
      verify("static Int f(Int a) { return -a; }", MakeInts(0), Int.make(0));
      verify("static Int f(Int a) { return -a; }", MakeInts(1), Int.make(-1));
      verify("static Int f(Int a) { return -a; }", MakeInts(-1), Int.make(1));
      verify("static Int f(Int a) { return -(a); }", MakeInts(8), Int.make(-8));
      verify("static Int f(Int a) { return -(-a); }", MakeInts(8), Int.make(8));

      // MakeFloats
      verify("static Float f(Float a) { return -a; }", MakeFloats(1), Float.make(-1));
      verify("static Float f(Float a) { return -a; }", MakeFloats(-1), Float.make(1));
      verify("static Float f(Float a) { return -(a); }", MakeFloats(8), Float.make(-8));
      verify("static Float f(Float a) { return -(-a); }", MakeFloats(8), Float.make(8));

      // MakeDursation
      verify("static Duration f(Duration a) { return -a; }", MakeDurs(1), Duration.make(-1));
      verify("static Duration f(Duration a) { return -a; }", MakeDurs(-1), Duration.make(1));
      verify("static Duration f(Duration a) { return -(a); }", MakeDurs(8), Duration.make(-8));
      verify("static Duration f(Duration a) { return -(-a); }", MakeDurs(8), Duration.make(8));
    }

  //////////////////////////////////////////////////////////////////////////
  // Multiply
  //////////////////////////////////////////////////////////////////////////

    void verifyMultiply()
    {
      Object o;

      // MakeInts
      verify("Int f(Int a, Int b) { return a * b; }", MakeInts(0, 0), Int.make(0));
      verify("Int f(Int a, Int b) { return a * b; }", MakeInts(0x3146443defL, 7), Int.make(0x3146443defL*7));
      verify("Int f(Int a, Int b) { return a * b; }", MakeInts(-3, 3), Int.make(-3*3));
      verify("Int f(Int a, Int b) { return a * 7; }", MakeInts(-3, 3), Int.make(-3*7));
      verify("Int f() { Int x := 3; x *= 6; return x; }", Int.make(18));
      members = "Int x := 2; Int y;";
      verify("Int f() { x *= 3; return x; }", Int.make(6));
      verify("Int f() { return x *= -3; }",   Int.make(-6));
      o = verify("Int f() { return y = x *= -3; }",   Int.make(-6));
        verify(Get(o, "x").Equals(Int.make(-6)));
        verify(Get(o, "y").Equals(Int.make(-6)));
      members = "static Int x := 2;";
      verify("static Int f() { return x *= 4; }", Int.make(8));

      // MakeFloats
      verify("Float f(Float a, Float b) { return a * b; }", MakeFloats(0, 0), Float.make(0));
      verify("Float f(Float a, Float b) { return a * b; }", MakeFloats(2, 5), Float.make(10));
      verify("Float f(Float a, Float b) { return a * b; }", MakeFloats(-3.32, 66.44), Float.make(-3.32*66.44));
      verify("Float f(Float a, Float b) { return a * 0.8; }", MakeFloats(-3.32, 66.44), Float.make(-3.32*0.8));
      verify("Float f() { x := 3.0; x *= 6.0; return x; }", Float.make(18));
      members = "Float x := 2.0; Float y;";
      verify("Float f() { x *= 3.0; return x; }", Float.make(6));
      verify("Float f() { return x *= -3.0; }",   Float.make(-6));
      o = verify("Float f() { return y = x *= -3f; }", Float.make(-6));
        verify(Get(o, "x").Equals(Float.make(-6)));
        verify(Get(o, "y").Equals(Float.make(-6)));
      members = "static Float x := 0.0;";
      verify("static Float f() { return x *= 4f; }", Float.make(0));

      // MakeDursation
      members = "x := 2ns; \n Duration y;";
      verify("Duration f(Duration a, Float b) { return a * b; }", new Object[] { Duration.make(4), Float.make(3) }, Duration.make(12));
      verify("Duration f(Duration a) { return a * 6.0; }", new Object[] { Duration.make(4) }, Duration.make(24));
      verify("Duration f() { x *= 3.0; return x; }", Duration.make(6));
      verify("Duration f() { return x *= -3.0; }",   Duration.make(-6));

      verify("Duration f() { x := 7ns; x *= 2.0; return x; }", Duration.make(14));
      o = verify("Duration f() { return y = x *= -3f; }", Duration.make(-6));
        verify(Get(o, "x").Equals(Duration.make(-6)));
        verify(Get(o, "y").Equals(Duration.make(-6)));
      members = "static Duration x := 1ms;";
      verify("static Duration f() { return x *= 4f; }", Duration.make(4000000));

      // auto-cast matrix
      /* TODO
      verify("Float f(Int a, Float b) { return a * b; }", new Object[] { Int.make(10), Float.make(-0.004) }, Float.make(10L*-0.004));
      verify("Float f(Float a, Int b) { return a * b; }", new Object[] { Float.make(1.2), Int.make(0xabcdL) }, Float.make(1.2*0xabcdL));
      */
    }

  //////////////////////////////////////////////////////////////////////////
  // Divide
  //////////////////////////////////////////////////////////////////////////

    void verifyDivide()
    {
      // Ints
      verify("Int f(Int a, Int b) { return a / b; }", MakeInts(0, 1), Int.make(0));
      verify("Int f(Int a, Int b) { return a / b; }", MakeInts(0x3146443defL, 7), Int.make(0x3146443defL/7));
      verify("Int f(Int a, Int b) { return a / b; }", MakeInts(-3, 3), Int.make(-3/3));
      verify("Int f(Int a, Int b) { return a / 7; }", MakeInts(-3, 3), Int.make(-3/7));
      verify("Int f() { Int x := 14; x /= 2; return x; }", Int.make(7));
      members = "Int x := 8;";
      verify("Int f() { x /= 4; return x; }", Int.make(2));
      verify("Int f() { return x /= 4; }",    Int.make(2));

      // floats
      verify("Float f(Float a, Float b) { return a / b; }", MakeFloats(0, 1), Float.make(0));
      verify("Float f(Float a, Float b) { return a / b; }", MakeFloats(20, 5), Float.make(20d/5d));
      verify("Float f(Float a, Float b) { return a / b; }", MakeFloats(-3.32, 66.44), Float.make(-3.32/66.44));
      verify("Float f(Float a, Float b) { return a / 0.8; }", MakeFloats(-3.32, 66.44), Float.make(-3.32/0.8));
      verify("Float f() { Float x := 14.0; x /= 2.0; return x; }", Float.make(7));
      members = "Float x := 8F;";
      verify("Float f() { x /= 4f; return x; }", Float.make(2));
      verify("Float f() { return x /= 4f; }",    Float.make(2));

      // duration
      verify("Duration f(Duration a, Float b) { return a / b; }", new Object[] { Duration.make(100), Float.make(4)}, Duration.make(25));
      verify("Duration f(Duration a) { return a / 4.0; }", new Object[] { Duration.make(100), }, Duration.make(25));
      verify("Duration f() { x := 7ns; x /= 2.0; return x; }", Duration.make(3));
      members = "Duration x := 8ns;";
      verify("Duration f() { x /= 4.0; return x; }", Duration.make(2));
      verify("Duration f() { return x /= 4f; }",   Duration.make(2));

      // auto-cast matrix
      /* TODO
      verify("Float f(Int a, Float b) { return a / b; }", new Object[] { Int.make(10), Float.make(-0.004) }, Float.make(10L/-0.004));
      verify("Float f(Float a, Int b) { return a / b; }", new Object[] { Float.make(1.2), Int.make(0xabcdL) }, Float.make(1.2/0xabcdL));
      */
    }

  //////////////////////////////////////////////////////////////////////////
  // Mod
  //////////////////////////////////////////////////////////////////////////

    void verifyMod()
    {
      // MakeInts
      verify("Int f(Int a, Int b) { return a % b; }", MakeInts(3, 2), Int.make(1));
      verify("Int f(Int a, Int b) { return a % b; }", MakeInts(0x3146443defL, 7), Int.make(0x3146443defL%7));
      verify("Int f(Int a, Int b) { return a % b; }", MakeInts(-3, 3), Int.make(-3%3));
      verify("Int f(Int a, Int b) { return a % 7; }", MakeInts(-5, 3), Int.make(-5%7));
      verify("Int f() { Int x := 15; x %= 3; return x; }", Int.make(0));
      members = "Int x := 9;";
      verify("Int f() { x %= 4; return x; }", Int.make(1));
      verify("Int f() { return x %= 4; }",    Int.make(1));

      // MakeFloats
      verify("Float f(Float a, Float b) { return a % b; }", MakeFloats(9, 4), Float.make(1));
      verify("Float f(Float a, Float b) { return a % b; }", MakeFloats(20, 5), Float.make(20d%5d));
      verify("Float f(Float a, Float b) { return a % b; }", MakeFloats(-3.32, 66.44), Float.make(-3.32%66.44));
      verify("Float f(Float a, Float b) { return a % 0.8; }", MakeFloats(-3.32, 66.44), Float.make(-3.32%0.8));
      verify("Float f() { Float x := 15.0; x %= 3.0; return x; }", Float.make(0));
      members = "Float x := 9.0;";
      verify("Float f() { x %= 4.0; return x; }", Float.make(1));
      verify("Float f() { return x %= 4.0; }",    Float.make(1));

      // duration
      verify("Duration f(Duration a, Float b) { return a % b; }", new Object[] { Duration.make(13), Float.make(4)}, Duration.make(1));
      verify("Duration f(Duration a) { return a % 4.0; }", new Object[] { Duration.make(13), }, Duration.make(1));
      verify("Duration f() { x := 7ns; x %= 5.0; return x; }", Duration.make(2));
      members = "Duration x := 10ns;";
      verify("Duration f() { x %= 4.0; return x; }", Duration.make(2));
      verify("Duration f() { return x %= 4f; }",   Duration.make(2));

      // auto-cast matrix
      /* TODO
      verify("Float f(Int a, Float b) { return a % b; }", new Object[] { Int.make(10), Float.make(-0.004) }, Float.make(10L%-0.004));
      verify("Float f(Float a, Int b) { return a % b; }", new Object[] { Float.make(1.2), Int.make(0xabcdL) }, Float.make(1.2%0xabcdL));
      */
    }

  //////////////////////////////////////////////////////////////////////////
  // Bitwise
  //////////////////////////////////////////////////////////////////////////

    void verifyBitwise()
    {
      // and, or, xor, not
      long[] az = { 0, 0x1, 0x1, 0x1, 0xabcd, 0xabcdef987654321L };
      long[] bz = { 0, 0x1, 0x2, 0x3, 0x1234, 0x333333333333333L };

      for (int i=0; i<az.Length; i++)
      {
        long a = az[i];
        long b = bz[i];
        long c = ~a << 3;
        verify("Int f(Int a) { return ~a; }", MakeInts(a), Int.make(~a));
        verify("Int f(Int b) { return ~b; }", MakeInts(b), Int.make(~b));
        verify("Int f(Int a, Int b) { return a & b; }", MakeInts(a, b), Int.make(a & b));
        verify("Int f(Int a, Int b) { return a | b; }", MakeInts(a, b), Int.make(a | b));
        verify("Int f(Int a, Int b) { return a ^ b; }", MakeInts(a, b), Int.make(a ^ b));
        verify("Int f(Int a, Int b, Int c) { return a & b & c; }", MakeInts(a, b, c), Int.make(a & b & c));
        verify("Int f(Int a, Int b, Int c) { return a | b | c; }", MakeInts(a, b, c), Int.make(a | b | c));
        verify("Int f(Int a, Int b, Int c) { return a ^ b ^ c; }", MakeInts(a, b, c), Int.make(a ^ b ^ c));
        verify("Int f(Int a, Int b, Int c) { return a & b | c; }", MakeInts(a, b, c), Int.make(a & b | c));
        verify("Int f(Int a, Int b, Int c) { return a | b & c; }", MakeInts(a, b, c), Int.make(a | b & c));
        verify("Int f(Int a, Int b, Int c) { return a & b ^ c; }", MakeInts(a, b, c), Int.make(a & b ^ c));
        verify("Int f(Int a, Int b, Int c) { return a ^ b & c; }", MakeInts(a, b, c), Int.make(a ^ b & c));
        // note: Fan puts | and ^ at same precedence, so left to right
        verify("Int f(Int a, Int b, Int c) { return a | b ^ c; }", MakeInts(a, b, c), Int.make((a | b) ^ c));
        verify("Int f(Int a, Int b, Int c) { return a ^ b | c; }", MakeInts(a, b, c), Int.make((a ^ b) | c));
        // verify equality lower precedence than bitwise (different than Java/C#)
        verify("Bool f(Int a, Int b) { return a & b == 0 }", MakeInts(0x2, 0x4), Bool.True);
        verify("Bool f(Int a, Int b) { return a & b == 2 }", MakeInts(0x2, 0x3), Bool.True);
        verify("Bool f(Int a, Int b) { return a & b != 2 }", MakeInts(0x2, 0x3), Bool.False);
        verify("Bool f(Int a, Int b) { return a | b == 3 }", MakeInts(0x2, 0x1), Bool.True);
        verify("Bool f(Int a, Int b) { return a ^ b == 1 }", MakeInts(0x2, 0x3), Bool.True);
        // verify comparision lower precedence than bitwise (different than Java/C#)
        verify("Bool f(Int a, Int b) { return a & b >= 2 }", MakeInts(0x2, 0x3), Bool.True);
        verify("Bool f(Int a, Int b) { return a | b < 2 }",  MakeInts(0x2, 0x1), Bool.False);
        verify("Bool f(Int a, Int b) { return a ^ b <= 5 }", MakeInts(0x2, 0x3), Bool.True);
      }

      // shift
      for (int i=0; i<65; i++)
      {
        verify("Int f(Int a, Int b) { return a << b; }", MakeInts(1L, i), Int.make(1L<<i));
        verify("Int f(Int a, Int b) { return a << b; }", MakeInts(0x123456789abcdef1L, i), Int.make(0x123456789abcdef1L<<i));
//ULONG?        verify("Int f(Int a, Int b) { return a >> b; }", MakeInts(0x8000000000000000L, i), Int.make(0x8000000000000000L>>i));
        verify("Int f(Int a, Int b) { return a >> b; }", MakeInts(0x7000000000000000L, i), Int.make(0x7000000000000000L>>i));
        verify("Int f(Int a, Int b) { return a >> b; }", MakeInts(0x7edcba987654321fL, i), Int.make(0x7edcba987654321fL>>i));
      }
      verify("Int f(Int a, Int b, Int c) { return a << b << c; }", MakeInts(1, 2, 3), Int.make(1L<<2<<3));
      verify("Int f(Int a, Int b, Int c) { return a >> b >> c; }", MakeInts(0x800000, 2, 3), Int.make(0x800000>>2>>3));
      verify("Int f(Int a, Int b, Int c) { return a - b - c; }", MakeInts(1, 2, 3), Int.make(1-2-3));

      Object o;

      // local var assignment, pop
      verify("Int f() { x := 0xf; x &= 0xa3; return x }", Int.make(0x3));
      verify("Int f() { x := 0xf; x |= 0xa3; return x }", Int.make(0xaf));
      verify("Int f() { x := 0xf; x ^= 0xa3; return x }", Int.make(0xf ^ 0xa3));
      verify("Int f() { x := 0xf; x <<= 3; return x }", Int.make(0xf << 3));
      verify("Int f() { x := 0xf; x >>= 2; return x }", Int.make(0xf >> 2));

      // local var assignment, leave
      verify("Int f() { x := 0xf; return x &= 0xa3 }", Int.make(0x3));
      verify("Int f() { x := 0xf; return x |= 0xa3 }", Int.make(0xaf));
      verify("Int f() { x := 0xf; return x ^= 0xa3 }", Int.make(0xf ^ 0xa3));
      verify("Int f() { x := 0xf; return x <<= 3 }", Int.make(0xf << 3));
      verify("Int f() { x := 0xf; return x >>= 2 }", Int.make(0xf >> 2));

      // field var assignment, pop
      members = "Int x := 0xf;";
      o = verify("Int f() { x &= 0xa3; return x }", Int.make(0x3));
        verify(Get(o, "x").Equals(Int.make(0x3)));
      o = verify("Int f() { x |= 0xa3; return x }", Int.make(0xaf));
        verify(Get(o, "x").Equals(Int.make(0xaf)));
      o = verify("Int f() { x ^= 0xa3; return x }", Int.make(0xf ^ 0xa3));
        verify(Get(o, "x").Equals(Int.make(0xf ^ 0xa3)));
      o = verify("Int f() { x <<= 3; return x }", Int.make(0xf << 3));
        verify(Get(o, "x").Equals(Int.make(0xf << 3)));
      o = verify("Int f() { x >>= 2; return x }", Int.make(0xf >> 2));
        verify(Get(o, "x").Equals(Int.make(0xf >> 2)));

      // field var assignment, leave
      members = "Int x := 0xf;";
      o = verify("Int f() { return x &= 0xa3; }", Int.make(0x3));
        verify(Get(o, "x").Equals(Int.make(0x3)));
      o = verify("Int f() { return x |= 0xa3; }", Int.make(0xaf));
        verify(Get(o, "x").Equals(Int.make(0xaf)));
      o = verify("Int f() { return x ^= 0xa3; }", Int.make(0xf ^ 0xa3));
        verify(Get(o, "x").Equals(Int.make(0xf ^ 0xa3)));
      o = verify("Int f() { return x <<= 3; }", Int.make(0xf << 3));
        verify(Get(o, "x").Equals(Int.make(0xf << 3)));
      o = verify("Int f() { return x >>= 2; }", Int.make(0xf >> 2));
        verify(Get(o, "x").Equals(Int.make(0xf >> 2)));
    }

  //////////////////////////////////////////////////////////////////////////
  // Add
  //////////////////////////////////////////////////////////////////////////

    void verifyAdd()
    {
      Object o;

      // MakeInts
      verify("Int f(Int a, Int b) { return a + b; }", MakeInts(0, 1), Int.make(1));
      verify("Int f(Int a, Int b) { return a + b; }", MakeInts(0x3146443defL, 7), Int.make(0x3146443defL+7));
      verify("Int f(Int a, Int b) { return a + b; }", MakeInts(-3, 3), Int.make(-3+3));
      verify("Int f(Int a, Int b) { return a + 7; }", MakeInts(-3, 3), Int.make(-3+7));
      verify("Int f() { x := 5; x += 3; return x; }", Int.make(8));
      members = "Int x := 5; Int y;";
      verify("Int f() { x += -3; return x; }", Int.make(2));
      o = verify("Int f() { return y = x += -3; }", Int.make(2));
        verify(Get(o, "x").Equals(Int.make(2)));
        verify(Get(o, "y").Equals(Int.make(2)));

      // MakeFloats
      verify("Float f(Float a, Float b) { return a + b; }", MakeFloats(0, 1), Float.make(1));
      verify("Float f(Float a, Float b) { return a + b; }", MakeFloats(20, 5), Float.make(20d+5d));
      verify("Float f(Float a, Float b) { return a + b; }", MakeFloats(-3.32, 66.44), Float.make(-3.32+66.44));
      verify("Float f(Float a, Float b) { return a + 0.8; }", MakeFloats(-3.32, 66.44), Float.make(-3.32+0.8));
      verify("Float f() { x := 5.0; x+=5.0; return x; }", Float.make(10));
      members = "Float x := 5.0; Float y;";
      verify("Float f() { x += -3.0; return x; }", Float.make(2));
      o = verify("Float f() { return y = x += -3.0; }", Float.make(2));
        verify(Get(o, "x").Equals(Float.make(2)));
        verify(Get(o, "y").Equals(Float.make(2)));

      // duration
      verify("Duration f(Duration a, Duration b) { return a + b; }", MakeDurs(0, 1), Duration.make(1));
      verify("Duration f(Duration a, Duration b) { return a + b; }", MakeDurs(20, 5), Duration.make(20+5));
      verify("Duration f(Duration a, Duration b) { return a + b; }", MakeDurs(-3, 7), Duration.make(4));
      verify("Duration f(Duration a, Duration b) { return a + 6ns; }", MakeDurs(7, 99), Duration.make(13));
      verify("Duration f() { x := 3ns; x += 5ns; return x; }", Duration.make(8));
      members = "Duration x := 5ns; Duration y;";
      verify("Duration f() { x += -3ns; return x; }", Duration.make(2));
      o = verify("Duration f() { return y = x += -3ns; }", Duration.make(2));
        verify(Get(o, "x").Equals(Duration.make(2)));
        verify(Get(o, "y").Equals(Duration.make(2)));

      // auto-cast matrix
      /* TODO
      verify("Float f(Int a, Float b) { return a + b; }", new Object[] { Int.make(10), Float.make(-0.004) }, Float.make(10L+-0.004));
      verify("Float f(Float a, Int b) { return a + b; }", new Object[] { Float.make(1.2), Int.make(0xabcdL) }, Float.make(1.2+0xabcdL));
      */
    }

  //////////////////////////////////////////////////////////////////////////
  // Sub
  //////////////////////////////////////////////////////////////////////////

    void verifySub()
    {
      Object o;

      // MakeInts
      verify("Int f(Int a, Int b) { return a - b; }", MakeInts(0, 1), Int.make(-1));
      verify("Int f(Int a, Int b) { return a - b; }", MakeInts(0x3146443defL, 7), Int.make(0x3146443defL-7));
      verify("Int f(Int a, Int b) { return a - b; }", MakeInts(-3, 3), Int.make(-3-3));
      verify("Int f(Int a, Int b) { return a - 7; }", MakeInts(-3, 3), Int.make(-3-7));
      verify("Int f(Int a, Int b) { return 7 - b; }", MakeInts(-3, 3), Int.make(7-3));
      verify("Int f() { x := 5; x -= 7; return x; }", Int.make(-2));
      members = "Int x := 9;";
      verify("Int f() { x -= 4; return x; }", Int.make(5));
      verify("Int f() { return x -= 4; }", Int.make(5));

      // MakeFloats
      verify("Float f(Float a, Float b) { return a - b; }", MakeFloats(0, 1), Float.make(-1));
      verify("Float f(Float a, Float b) { return a - b; }", MakeFloats(20, 5), Float.make(20d-5d));
      verify("Float f(Float a, Float b) { return a - b; }", MakeFloats(-3.32, 66.44), Float.make(-3.32-66.44));
      verify("Float f(Float a, Float b) { return a - 0.8; }", MakeFloats(-3.32, 66.44), Float.make(-3.32-0.8));
      verify("Float f() { x := 5.0; x -= 6.0; return x; }", Float.make(-1));

      // duration
      verify("Duration f(Duration a, Duration b) { return a - b; }", MakeDurs(4, 6), Duration.make(-2));
      verify("Duration f(Duration a, Duration b) { return a - b; }", MakeDurs(20, 5), Duration.make(20-5));
      verify("Duration f(Duration a, Duration b) { return a - b; }", MakeDurs(-3, 7), Duration.make(-10));
      verify("Duration f(Duration a, Duration b) { return a - 6ns; }", MakeDurs(8, 99), Duration.make(2));
      verify("Duration f() { x := 3ns; x -= 5ns; return x; }", Duration.make(-2));
      members = "Duration x := 5ns; Duration y;";
      verify("Duration f() { x -= 3ns; return x; }", Duration.make(2));
      o = verify("Duration f() { return y = x -= 3ns; }", Duration.make(2));
        verify(Get(o, "x").Equals(Duration.make(2)));
        verify(Get(o, "y").Equals(Duration.make(2)));

      // auto-cast matrix
      /* TODO
      verify("Float f(Int a, Float b) { return a - b; }", new Object[] { Int.make(10), Float.make(-0.004) }, Float.make(10L-(-0.004)));
      members = "Float x := 9;";
      verify("Float f() { x -= 4; return x; }", Float.make(5));
      verify("Float f() { return x -= 4; }", Float.make(5));
      verify("Float f(Float a, Int b) { return a - b; }", new Object[] { Float.make(1.2), Int.make(0xabcdL) }, Float.make(1.2-0xabcdL));
      */
    }

  //////////////////////////////////////////////////////////////////////////
  // IncrementDecrement
  //////////////////////////////////////////////////////////////////////////

    void verifyOrderAndPrecedence()
    {
      verify("Int f(Int a, Int b, Int c) { return a - b - c; }", MakeInts(1, 2, 3), Int.make(1-2-3));
      verify("Int f(Int a, Int b, Int c, Int d) { return a - b - c - d; }", MakeInts(1, 2, 3, 4), Int.make(1-2-3-4));
      verify("Int f(Int a, Int b, Int c, Int d) { return a / b / c / d; }", MakeInts(40, 2, 3, 2), Int.make(40/2/3/2));
      verify("Int f(Int a, Int b, Int c, Int d) { return a * b / c % d; }", MakeInts(40, 2, 3, 2), Int.make(40*2/3%2));
      verify("Int f(Int a, Int b, Int c, Int d) { return a - b * c - d; }", MakeInts(1, 2, 3, 4), Int.make(1-2*3-4));
      verify("Int f(Int a, Int b, Int c, Int d) { return a - b / c - d; }", MakeInts(40, 10, 5, 3), Int.make(40-10/5-3));
      verify("Int f(Int a, Int b, Int c, Int d) { return a / b - c - d; }", MakeInts(40, 10, 5, 3), Int.make(40/10-5-3));
      verify("Int f(Int a, Int b, Int c, Int d) { return a / b - c * d; }", MakeInts(40, 10, 5, 3), Int.make(40/10-5*3));
      verify("Int f(Int a, Int b, Int c) { return a << b << c; }", MakeInts(1, 2, 3), Int.make(1L<<2<<3));
    }

  //////////////////////////////////////////////////////////////////////////
  // IncrementDecrement
  //////////////////////////////////////////////////////////////////////////

    void verifyIncrementDecrement()
    {
      Object o;
      imports = "";

      // int
      members = "Int x := 0;";
      o = verify("Int f() { return ++x; }", Int.make(1)); verify(Get(o, "x").Equals(Int.make(1)));
      o = verify("Int f() { return x++; }", Int.make(0)); verify(Get(o, "x").Equals(Int.make(1)));
      o = verify("Int f() { return --x; }", Int.make(-1)); verify(Get(o, "x").Equals(Int.make(-1)));
      o = verify("Int f() { return x--; }", Int.make(0)); verify(Get(o, "x").Equals(Int.make(-1)));
      members = "static Int x := 0;";
      o = verify("static Int f() { return ++x; }", Int.make(1)); verify(Get(o, "x").Equals(Int.make(1)));
      o = verify("static Int f() { return x++; }", Int.make(0)); verify(Get(o, "x").Equals(Int.make(1)));
      o = verify("static Int f() { return --x; }", Int.make(-1)); verify(Get(o, "x").Equals(Int.make(-1)));
      o = verify("static Int f() { return x--; }", Int.make(0)); verify(Get(o, "x").Equals(Int.make(-1)));
      members = "";
      o = verify("Int f(Int y) { return ++y; }", MakeInts(3), Int.make(4));
      o = verify("Int f(Int y) { return y++; }", MakeInts(3), Int.make(3));
      o = verify("Int f(Int y) { return --y; }", MakeInts(3), Int.make(2));
      o = verify("Int f(Int y) { return y--; }", MakeInts(3), Int.make(3));
      members = "Int x := 0;";
      o = verify("Int f(Int y) { return x = ++y; }", MakeInts(3), Int.make(4)); verify(Get(o, "x").Equals(Int.make(4)));
      o = verify("Int f(Int y) { return x = y++; }", MakeInts(3), Int.make(3)); verify(Get(o, "x").Equals(Int.make(3)));
      o = verify("Int f(Int y) { return x = --y; }", MakeInts(3), Int.make(2)); verify(Get(o, "x").Equals(Int.make(2)));
      o = verify("Int f(Int y) { return x = y--; }", MakeInts(3), Int.make(3)); verify(Get(o, "x").Equals(Int.make(3)));

      // MakeFloats
      members = "Float x := 0.0;";
      o = verify("Float f() { return ++x; }", Float.make(1)); verify(Get(o, "x").Equals(Float.make(1)));
      o = verify("Float f() { return x++; }", Float.make(0)); verify(Get(o, "x").Equals(Float.make(1)));
      o = verify("Float f() { return --x; }", Float.make(-1)); verify(Get(o, "x").Equals(Float.make(-1)));
      o = verify("Float f() { return x--; }", Float.make(0)); verify(Get(o, "x").Equals(Float.make(-1)));
      members = "static Float x := 0.0;";
      o = verify("static Float f() { return ++x; }", Float.make(1)); verify(Get(o, "x").Equals(Float.make(1)));
      o = verify("static Float f() { return x++; }", Float.make(0)); verify(Get(o, "x").Equals(Float.make(1)));
      o = verify("static Float f() { return --x; }", Float.make(-1)); verify(Get(o, "x").Equals(Float.make(-1)));
      o = verify("static Float f() { return x--; }", Float.make(0)); verify(Get(o, "x").Equals(Float.make(-1)));
      members = "";
      o = verify("Float f(Float y) { return ++y; }", MakeFloats(3), Float.make(4));
      o = verify("Float f(Float y) { return y++; }", MakeFloats(3), Float.make(3));
      o = verify("Float f(Float y) { return --y; }", MakeFloats(3), Float.make(2));
      o = verify("Float f(Float y) { return y--; }", MakeFloats(3), Float.make(3));
      members = "Float x := 0.0;";
      o = verify("Float f(Float y) { return x = ++y; }", MakeFloats(3), Float.make(4)); verify(Get(o, "x").Equals(Float.make(4)));
      o = verify("Float f(Float y) { return x = y++; }", MakeFloats(3), Float.make(3)); verify(Get(o, "x").Equals(Float.make(3)));
      o = verify("Float f(Float y) { return x = --y; }", MakeFloats(3), Float.make(2)); verify(Get(o, "x").Equals(Float.make(2)));
      o = verify("Float f(Float y) { return x = y--; }", MakeFloats(3), Float.make(3)); verify(Get(o, "x").Equals(Float.make(3)));
    }

  //////////////////////////////////////////////////////////////////////////
  // Plus Minus Combos (as Unary and Binary)
  //////////////////////////////////////////////////////////////////////////

    void verifyPlusMinusCombos()
    {
      verify("Int f(Int a, Int b) { return a-3;  }",     MakeInts(2, 3), Int.make(-1));
      verify("Int f(Int a, Int b) { return a - 3;  }",   MakeInts(2, 3), Int.make(-1));
      verify("Int f(Int a, Int b) { return a - -3;  }",  MakeInts(2, 3), Int.make(5));
      verify("Int f(Int a, Int b) { return a - - 3;  }", MakeInts(2, 3), Int.make(5));
      verify("Int f(Int a, Int b) { return a+3;  }",     MakeInts(2, 3), Int.make(5));
      verify("Int f(Int a, Int b) { return a + 3;  }",   MakeInts(2, 3), Int.make(5));
      verify("Int f(Int a, Int b) { return a + +3;  }",  MakeInts(2, 3), Int.make(5));
      verify("Int f(Int a, Int b) { return a + + 3;  }", MakeInts(2, 3), Int.make(5));

      verify("Int f(Int a, Int b) { return a-b;  }",     MakeInts(2, 3), Int.make(-1));
      verify("Int f(Int a, Int b) { return a - b;  }",   MakeInts(2, 3), Int.make(-1));
      verify("Int f(Int a, Int b) { return a - -b;  }",  MakeInts(2, 3), Int.make(5));
      verify("Int f(Int a, Int b) { return a - - b;  }", MakeInts(2, 3), Int.make(5));
      verify("Int f(Int a, Int b) { return a+b;  }",     MakeInts(2, 3), Int.make(5));
      verify("Int f(Int a, Int b) { return a + b;  }",   MakeInts(2, 3), Int.make(5));
      verify("Int f(Int a, Int b) { return a + +b;  }",  MakeInts(2, 3), Int.make(5));
      verify("Int f(Int a, Int b) { return a + + b;  }", MakeInts(2, 3), Int.make(5));
    }

  //////////////////////////////////////////////////////////////////////////
  // StrAdd
  //////////////////////////////////////////////////////////////////////////

    void verifyStrAdd()
    {
      // str
      verify("Str f(Str a, Str b) { return a + b; }", MakeStrs("a", "b"), Str.make("ab"));
      verify("Str f(Str a, Str b) { return a + b; }", MakeStrs(null, null), Str.make("nullnull"));
      verify("Str f(Str a, Str b) { return a + b; }", MakeStrs(null, "b"),  Str.make("nullb"));
      verify("Str f(Str a, Str b) { return a + b; }", MakeStrs("a", null),  Str.make("anull"));

      // bool
      verify("Str f(Str a, Bool b) { return a + b; }", new Obj[] {Str.make("a"), Bool.make(true)}, Str.make("atrue"));
      verify("Str f(Bool a, Str b) { return a + b; }", new Obj[] {Bool.make(false), Str.make("a")}, Str.make("falsea"));
      verify("Str f() { return \"foo\" + true; }", Str.make("footrue"));
      verify("Str f() { return false + \" foo\"; }", Str.make("false foo"));

      // int
      verify("Str f(Str a, Int b) { return a + b; }", new Obj[] { Str.make("a"), Int.make(3) }, Str.make("a3"));
      verify("Str f(Int a, Str b) { return a + b; }", new Obj[] { Int.make(-99), Str.make("a") }, Str.make("-99a"));
      verify("Str f() { return \"foo \" + 77; }", Str.make("foo 77"));
      verify("Str f() { return 0 + \" foo\"; }", Str.make("0 foo"));

      // double
      verify("Str f(Str a, Float b) { return a + b; }", new Obj[] { Str.make("a"), Float.make(3) }, Str.make("a3.0"));
      verify("Str f(Float a, Str b) { return a + b; }", new Obj[] { Float.make(-99), Str.make("a") }, Str.make("-99.0a"));
      verify("Str f() { return \"foo \" + 77.0; }", Str.make("foo 77.0"));
      verify("Str f() { return 0.0 + \" foo\"; }", Str.make("0.0 foo"));

      // mix
      verify("Str f(Int a, Str b, Bool c) { return a + b + c; }", new Obj[] { Int.make(3), Str.make(" wow "), Bool.make(true) }, Str.make("3 wow true"));
      verify("Str f(Int a, Str b, Bool c) { return \"w\" + a + \"x\" + b + \"y\" + c + \"z\"; }", new Object[] { Int.make(3), Str.make(" wow "), Bool.make(true) }, Str.make("w3x wow ytruez"));
    }

  //////////////////////////////////////////////////////////////////////////
  // LocalVar
  //////////////////////////////////////////////////////////////////////////

    void verifyLocalVar()
    {
      imports = "";
      members = "";

      // this
//COMPILER      verifyErr("static Obj f() { return this; }", "Cannot access 'this' in static context");

      // local definitions
      verify("Int f() { Int x; x = 7; return x; }", Int.make(7));
      /* TODO is this allowed?
      verify("Int f() { sys::Int x; x = 7; return x; }", Int.make(7));
      */
      verify("Int f(Int a) { Int x := 7; return x; }", MakeInts(1), Int.make(7));
      verify("Str f() { Str x := \"hello\"; return x; }", Str.make("hello"));
      verify("Int f() { Str a := \"hello\"; Int b := 66; return b; }", Int.make(66));

      verify("static Bool f(Bool x, Bool y) { x = true; y = x; return y; }", ff, Bool.True);
      verify("static Bool f(Bool x, Bool y) { return x = y = true; }", ff, Bool.True);

      verify("static Int f(Int x) { x = 17; return x; }", MakeInts(88), Int.make(17));
      verify("static Int f(Int x) { return  x = 17; }", MakeInts(88), Int.make(17));
      verify("static Str f(Str x) { x = \"yeah\"; return x; }", MakeStrs("not"), Str.make("yeah"));
      verify("static Str f(Str x) { return x = \"yeah\"; }", MakeStrs("not"), Str.make("yeah"));

      verify("Bool f(Bool x, Bool y) { x = true; y = x; return y; }", ff, Bool.True);
      verify("Int f(Int x) { x = 17; return x; }",     MakeInts(88), Int.make(17));
      verify("Int f(Int x) { return x = 17; }",        MakeInts(88), Int.make(17));
      verify("Float f(Float x) { x = 17.0; return x; }", MakeFloats(88), Float.make(17));
      verify("Float f(Float x) { return x = 17.0; }",    MakeFloats(88), Float.make(17));
      verify("Str f(Str x) { x = \"yeah\"; return x; }", MakeStrs("not"), Str.make("yeah"));
      verify("Obj f(Obj x) { x = \"yeah\"; return x; }", MakeStrs("not"), Str.make("yeah"));
//COMPILER      verifyErr("Int f(Int x) { x = \"no way\"; return x; }", "Type 'sys::Str' is not assignable to 'sys::Int'");

      // auto-cast matrix: int * x
//COMPILER      verifyErr("Int f(Int a, Float b) { a = b; return a; }", "Type 'sys::Float' is not assignable to 'sys::Int'");
//COMPILER      verifyErr("Int f(Int a, Float b) { a = 6.0; return a; }", "Type 'sys::Float' is not assignable to 'sys::Int'");

      // auto-cast matrix: Float * x
      /*
      verify("Float f(Float a, Int b) { a = b; return a; }", new Object[] { Float.make(0), Int.make(6) }, Float.make(6));
      verify("Float f(Float a, Int b) { a = 6; return a; }", new Object[] { Float.make(0), Int.make(6) }, Float.make(6));
      verify("Float f(Float a, Int b) { return a = b; }", new Object[] { Float.make(0), Int.make(6) }, Float.make(6));
      */
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    void verifyFieldGet()
    {
      imports = "";

      members = "static x := 0;";
      verify("static Int f() { return x; }", Int.make(0));

      members = "static Int x";
      verify("Int f() { return x; }", null);

      members = "Int x := 6;";
      verify("Int f() { return x; }", Int.make(6));

      members = "x := 4;";
      verify("Int f() { return this.x; }", Int.make(4));

      members = "Int x;";
      //verifyErr("static Int f() { return x; }", "Cannot access instance field '" + nextPodName + "::" + nextClassName + ".x' in static context");
//COMPILER      verifyErr("static Int f() { return this.x }", "Cannot access 'this' in static context");

      members = "Float x";
      verify("Float f() { return x; }", null);

      members = "x := 0.0";
      verify("Float f() { return x; }", Float.make(0));
    }

    void verifyFieldSet()
    {
      Object o;

      imports = "";
      members = "static Int x; static Int y;";
      verify("static Int f() { x = 919; return x; }", Int.make(919));
      verify("static Int f() { return x = 919; }",    Int.make(919));
      o = verify("static Int f() { return x = y = 7; }", Int.make(7));
        verify(Get(o, "x").Equals(Int.make(7)));
        verify(Get(o, "y").Equals(Int.make(7)));

      imports = "";
      members = "Int x; Int y;";
      verify("Int f() { x = 69; return x; }", Int.make(69));

      verify("Int f() { return x = 69; }", Int.make(69));
      o = verify("Int f() { return x = y = 7; }", Int.make(7));
        verify(Get(o, "x").Equals(Int.make(7)));
        verify(Get(o, "y").Equals(Int.make(7)));

      imports = "";
      members = "Int x; static Int y;";
      verify("Int f() { this.x = 99; return this.x; }", Int.make(99));
      verify("Int f() { return this.x = 99; }", Int.make(99));
      o = verify("Int f() { return x = y = 7; }", Int.make(7));
        verify(Get(o, "x").Equals(Int.make(7)));
        verify(Get(o, "y").Equals(Int.make(7)));

      imports = "";
      members = "Int x;";
      //verifyErr("static Int f() { x = 5; return x; }", "Cannot access instance field '" + nextPodName + "::" + nextClassName + ".x' in static context");
//COMPILER      verifyErr("static Void f() { this.x = 4; }", "Cannot access 'this' in static context");

      imports = "";
      members = "Float x; Float y;";
      verify("Float f() { x = -4.88; return x; }", Float.make(-4.88));
      verify("Float f() { return x = -4.88; }", Float.make(-4.88));
      verify("Float f() { return x = 88.0; }", Float.make(88));
      o = verify("Float f() { return x = y = 7.0; }", Float.make(7));
        verify(Get(o, "x").Equals(Float.make(7)));
        verify(Get(o, "y").Equals(Float.make(7)));
    }

  //////////////////////////////////////////////////////////////////////////
  // Calls
  //////////////////////////////////////////////////////////////////////////

    void verifyCalls()
    {
      members = "static Int x() { return 0; }";
      verify("static Int f() { return x(); }", Int.make(0));
      verify("static Int f() { return x }", Int.make(0));

      members = "Int x() { return 77; }";
      verify("Int f() { return x(); }", Int.make(77));
      verify("Int f() { return x }", Int.make(77));

      members = "Int x() { return 6; }";
      verify("Int f() { return this.x(); }", Int.make(6));
      verify("Int f() { return this.x; }", Int.make(6));

      members = "static Str x() { return \"hello\"; }";
      verify("Str f() { return x(); }", Str.make("hello"));
      verify("Int f() { return x.size }", Int.make(5));
//COMPILER      verifyErr("Int f() { return x.compare }", "Invalid args compare() for compare(sys::Obj)");

      verify("Str f(Str q) { q = x(); return q; }", MakeStrs("foo"), Str.make("hello"));
      verify("Str f() { x(); return x(); }", Str.make("hello"));
      verify("Str f() { x; return x }", Str.make("hello"));

//COMPILER      members = "Str x() { return \"hello\"; }";
//COMPILER      verifyErr("static Str f() { return x(); }",         "Cannot call instance method '" + nextPodName + "::" + nextClassName + ".x' in static context");
//COMPILER      verifyErr("static Str f() { return x }",            "Cannot call instance method '" + nextPodName + "::" + nextClassName + ".x' in static context");
//COMPILER      verifyErr("static Str f() { return this.x() }",     "Cannot access 'this' in static context");
//COMPILER      verifyErr("static Str f() { return this.x }",       "Cannot access 'this' in static context");
//COMPILER      verifyErr("static Int f() { return Int.plus(3); }", "Cannot call instance method 'sys::Int.plus' in static context");
//COMPILER      verifyErr("static Int f() { return Int.hash() }",   "Cannot call instance method 'sys::Int.hash' in static context");
//COMPILER      verifyErr("static Int f() { return Int.hash}",      "Cannot call instance method 'sys::Int.hash' in static context");

      members = "Int zero() { return 0; }\n" +
                "Int two() { return 2; }";
      verify("Bool f() { return zero() > two(); }",   Bool.False);
      verify("Bool f() { return two()  > zero(); }",  Bool.True);
      verify("Bool f() { return two()  == zero(); }", Bool.False);
      verify("Bool f() { return two()  != zero(); }", Bool.True);
      verify("Bool f() { return two >  zero }",  Bool.True);
      verify("Bool f() { return two != zero }", Bool.True);
    }

  //////////////////////////////////////////////////////////////////////////
  // Parens
  //////////////////////////////////////////////////////////////////////////

    void verifyParens()
    {
      members = "Int one() { return 1; }  Int two() { return 2; }";

      // literals wrapped in parens
      verify("static Bool f() { return (false); }",     MakeBool(false));
      verify("static Bool f() { return (true); }",      MakeBool(true));
      verify("static Bool f() { return ((false)); }",   MakeBool(false));
      verify("static Int f() { return (0); }",          Int.make(0));
      verify("static Int f() { return (77); }",         Int.make(77));
      verify("static Int f() { return (-5); }",         Int.make(-5));
      verify("static Int f() { return ((0)); }",        Int.make(0));
      verify("static Str f() { return (\"foo\"); }",    Str.make("foo"));
      verify("static Str f() { return (((\"foo\"))); }",Str.make("foo"));
      verify("static Bool f(Int a, Int b) { return (a > b); }",     MakeInts(2, 3),  MakeBool(false));
      verify("static Bool f(Int a, Int b) { return (a) > (b); }",   MakeInts(7, -1), MakeBool(true));
      verify("static Bool f(Int a, Int b) { return ((a) > (b)); }", MakeInts(7, -1), MakeBool(true));
      verify("Bool f() { return (one() > two()); }",         MakeBool(false));
      verify("Bool f() { return (one()) > (two()); }",       MakeBool(false));
      verify("Bool f() { return ((one()) > (two())); }",     MakeBool(false));

      // TODO
    }

  //////////////////////////////////////////////////////////////////////////
  // Casts
  //////////////////////////////////////////////////////////////////////////

    void verifyCasts()
    {
      verify("static Str f(Obj x)   { return (Str)x; }", MakeStrs("hello"), Str.make("hello"));
      verify("static Int f(Obj x)   { return (Int)x; }", MakeInts(6), Int.make(6));
      verify("static Int f(Obj x)   { return (Int)5; }", MakeInts(6), Int.make(5));
//GENERICS      verify("static Str[] f(Obj x) { return (Str[])x; }", new Obj[]{new List(Sys.StrType)}, new List(Sys.StrType));

      /*
      if (jcompiler)
      {
        // various reference based casts
        verify("Str f(Int x) { return (java.lang.Long.toHexString(x)); }", MakeInts(16), "10");
        verify("Str f(Int x) { return (Str)java.lang.Long.toHexString(x); }", MakeInts(16), "10");
        verify("Str f(Int x) { return (fan.sys.Str)java.lang.Long.toHexString(x); }", MakeInts(16), "10");
        verify("Str f(Int x) { return (Str)(java.lang.Long.toHexString(x)); }", MakeInts(16), "10");
        verify("Str f(Int x) { return (fan.sys.Str)(java.lang.Long.toHexString(x)); }", MakeInts(16), "10");
        verify("Str f(Int x) { return ((Str)java.lang.Long.toHexString(x)); }", MakeInts(16), "10");
        verify("Str f(Int x) { return ((fan.sys.Str)java.lang.Long.toHexString(x)); }", MakeInts(16), "10");
        verify("Str f(Int x) { return ((Str)(java.lang.Long.toHexString(x))); }", MakeInts(16), "10");
        verify("Str f(Int x) { return ((fan.sys.Str)(java.lang.Long.toHexString(x))); }", MakeInts(16), "10");

        // test primitive cast matrix

        // int to *
        verify("Str f(int x) { return java.lang.String.valueOf(x); }",         MakeInts(65), "65");
        verify("Str f(int x) { return java.lang.String.valueOf((char)x); }",   MakeInts(65), "A");
        verify("Str f(int x) { return java.lang.Byte.toString((byte)x); }",    MakeInts(1000), String.valueOf((byte)1000));
        verify("Str f(int x) { return java.lang.Short.toString((short)x); }",  MakeInts(0xFFFFF), String.valueOf((short)0xFFFFF));
        verify("Str f(int x) { return java.lang.String.valueOf((int)x); }",    MakeInts(-6), "-6");
        verify("Str f(int x) { return java.lang.String.valueOf((long)x); }",   MakeInts(5), "5");
        verify("Str f(int x) { return java.lang.String.valueOf((float)x); }",  MakeInts(6), "6.0");
        verify("Str f(int x) { return java.lang.String.valueOf((double)x); }", MakeInts(7), "7.0");

        // Int to *
        verify("Str f(Int x) { return java.lang.String.valueOf(x); }",         MakeInts(65), "65");
        verify("Str f(Int x) { return java.lang.String.valueOf((char)x); }",   MakeInts(65), "A");
        verify("Str f(Int x) { return java.lang.Byte.toString((byte)x); }",    MakeInts(1000), String.valueOf((byte)1000));
        verify("Str f(Int x) { return java.lang.Short.toString((short)x); }",  MakeInts(0xFFFFF), String.valueOf((short)0xFFFFF));
        verify("Str f(Int x) { return java.lang.String.valueOf((int)x); }",    MakeInts(-6), "-6");
        verify("Str f(Int x) { return java.lang.String.valueOf((long)x); }",   MakeInts(5), "5");
        verify("Str f(Int x) { return java.lang.String.valueOf((float)x); }",  MakeInts(6), "6.0");
        verify("Str f(Int x) { return java.lang.String.valueOf((double)x); }", MakeInts(7), "7.0");

        // float to *
        verify("Str f(float x) { return java.lang.String.valueOf(x); }",         MakeFloats(65), "65.0");
        verify("Str f(float x) { return java.lang.String.valueOf((char)x); }",   MakeFloats(65), "A");
        verify("Str f(float x) { return java.lang.Byte.toString((byte)x); }",    MakeFloats(1000), String.valueOf((byte)1000));
        verify("Str f(float x) { return java.lang.Short.toString((short)x); }",  MakeFloats(0xFFFFF), String.valueOf((short)0xFFFFF));
        verify("Str f(float x) { return java.lang.String.valueOf((int)x); }",    MakeFloats(-6), "-6");
        verify("Str f(float x) { return java.lang.String.valueOf((long)x); }",   MakeFloats(5), "5");
        verify("Str f(float x) { return java.lang.String.valueOf((float)x); }",  MakeFloats(6), "6.0");
        verify("Str f(float x) { return java.lang.String.valueOf((double)x); }", MakeFloats(7), "7.0");

        // Float to *
        verify("Str f(Float x) { return java.lang.String.valueOf(x); }",         MakeFloats(65), "65.0");
        verify("Str f(Float x) { return java.lang.String.valueOf((char)x); }",   MakeFloats(65), "A");
        verify("Str f(Float x) { return java.lang.Byte.toString((byte)x); }",    MakeFloats(1000), String.valueOf((byte)1000));
        verify("Str f(Float x) { return java.lang.Short.toString((short)x); }",  MakeFloats(0xFFFFF), String.valueOf((short)0xFFFFF));
        verify("Str f(Float x) { return java.lang.String.valueOf((int)x); }",    MakeFloats(-6), "-6");
        verify("Str f(Float x) { return java.lang.String.valueOf((long)x); }",   MakeFloats(5), "5");
        verify("Str f(Float x) { return java.lang.String.valueOf((float)x); }",  MakeFloats(6), "6.0");
        verify("Str f(Float x) { return java.lang.String.valueOf((double)x); }", MakeFloats(7), "7.0");

      }
        */
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    Bool[] tt = { Bool.True,  Bool.True  };
    Bool[] ft = { Bool.False, Bool.True  };
    Bool[] tf = { Bool.True,  Bool.False };
    Bool[] ff = { Bool.False, Bool.False };

    Bool[] nn = { null,       null };
    Bool[] tn = { Bool.True,  null};
    Bool[] nt = { null,       Bool.True};

    Bool[] ttt = { Bool.True,  Bool.True,  Bool.True  };
    Bool[] ftt = { Bool.False, Bool.True,  Bool.True  };
    Bool[] tft = { Bool.True,  Bool.False, Bool.True  };
    Bool[] ttf = { Bool.True,  Bool.True,  Bool.False };
    Bool[] fft = { Bool.False, Bool.False, Bool.True  };
    Bool[] ftf = { Bool.False, Bool.True,  Bool.False };
    Bool[] tff = { Bool.True,  Bool.False, Bool.False };
    Bool[] fff = { Bool.False, Bool.False, Bool.False };

  }
}
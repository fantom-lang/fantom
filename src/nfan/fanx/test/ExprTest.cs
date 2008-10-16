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
      verify("Boolean f(Boolean a, Boolean b) { return a || b;  }", tt, or(tt));
      verify("Boolean f(Boolean a, Boolean b) { return a || b;  }", ft, or(ft));
      verify("Boolean f(Boolean a, Boolean b) { return a || b;  }", tf, or(tf));
      verify("Boolean f(Boolean a, Boolean b) { return a || b;  }", ff, or(ff));

      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b || c;  }", ttt, or(ttt));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b || c;  }", ftt, or(ftt));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b || c;  }", tft, or(tft));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b || c;  }", ttf, or(ttf));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b || c;  }", fft, or(fft));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b || c;  }", ftf, or(ftf));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b || c;  }", tff, or(tff));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b || c;  }", fff, or(fff));

      verify("Boolean f(Boolean a, Boolean b) { return a && b;  }", tt, and(tt));
      verify("Boolean f(Boolean a, Boolean b) { return a && b;  }", ft, and(ft));
      verify("Boolean f(Boolean a, Boolean b) { return a && b;  }", tf, and(tf));
      verify("Boolean f(Boolean a, Boolean b) { return a && b;  }", ff, and(ff));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b && c;  }", ttt, and(ttt));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b && c;  }", ftt, and(ftt));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b && c;  }", tft, and(tft));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b && c;  }", ttf, and(ttf));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b && c;  }", fft, and(fft));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b && c;  }", ftf, and(ftf));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b && c;  }", tff, and(tff));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b && c;  }", fff, and(fff));

      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b && c;  }", ttt, MakeBool(true ||true &&true));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b && c;  }", ftt, MakeBool(false||true &&true));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b && c;  }", tft, MakeBool(true ||false&&true));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b && c;  }", ttf, MakeBool(true ||true &&false));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b && c;  }", fft, MakeBool(false||false&&true));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b && c;  }", tff, MakeBool(true ||false&&false));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a || b && c;  }", fff, MakeBool(false||false&&false));

      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b || c; }",  ttt, MakeBool(true &&true ||true));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b || c; }",  ftt, MakeBool(false&&true ||true));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b || c; }",  tft, MakeBool(true &&false||true));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b || c; }",  ttf, MakeBool(true &&true ||false));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b || c; }",  fft, MakeBool(false&&false||true));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b || c; }",  ftf, MakeBool(false&&true ||false));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b || c; }",  tff, MakeBool(true &&false||false));
      verify("Boolean f(Boolean a, Boolean b, Boolean c) { return a && b || c; }",  fff, MakeBool(false&&false||false));

      verify("Boolean f(Boolean a) { return !a; }",  MakeBools(true), MakeBool(false));
      verify("Boolean f(Boolean a) { return !a; }",  MakeBools(false), MakeBool(true));
      verify("Boolean f() { return !true; }",     MakeBool(false));
      verify("Boolean f() { return !false; }",    MakeBool(true));

      verify("Boolean f(Boolean a, Boolean b) { return !a && !b; }", tt, MakeBool(false));
      verify("Boolean f(Boolean a, Boolean b) { return !a && !b; }", ff, MakeBool(true));
    }

    Boolean or(Boolean[] b)
    {
      bool r = b[0].booleanValue();
      for (int i=1; i<b.Length; i++) r = r || b[i].booleanValue();
      return Boolean.valueOf(r);
    }

    Boolean and(Boolean[] b)
    {
      bool r = b[0].booleanValue();
      for (int i=1; i<b.Length; i++) r = r && b[i].booleanValue();
      return Boolean.valueOf(r);
    }

  //////////////////////////////////////////////////////////////////////////
  // == and !=
  //////////////////////////////////////////////////////////////////////////

    void verifyEquality()
    {
      //
      // bool
      //
      verify("static Boolean f(Boolean a, Boolean b) { return a == b; }", tt, Boolean.True);
      verify("static Boolean f(Boolean a, Boolean b) { return a == b; }", ft, Boolean.False);
      verify("static Boolean f(Boolean a, Boolean b) { return a == b; }", tf, Boolean.False);
      verify("static Boolean f(Boolean a, Boolean b) { return a == b; }", ff, Boolean.True);

      verify("static Boolean f(Boolean a, Boolean b) { return a != b; }", tt, Boolean.False);
      verify("static Boolean f(Boolean a, Boolean b) { return a != b; }", ft, Boolean.True);
      verify("static Boolean f(Boolean a, Boolean b) { return a != b; }", tf, Boolean.True);
      verify("static Boolean f(Boolean a, Boolean b) { return a != b; }", ff, Boolean.False);

      verify("static Boolean f(Boolean a, Boolean b) { return a == b; }", nn, Boolean.True);
      verify("static Boolean f(Boolean a, Boolean b) { return a == b; }", tn, Boolean.False);
      verify("static Boolean f(Boolean a, Boolean b) { return a == b; }", nt, Boolean.False);

      verify("static Boolean f(Boolean a, Boolean b) { return a != b; }", nn, Boolean.False);
      verify("static Boolean f(Boolean a, Boolean b) { return a != b; }", tn, Boolean.True);
      verify("static Boolean f(Boolean a, Boolean b) { return a != b; }", nt, Boolean.True);

      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a == b == c; }", ttt, Boolean.valueOf(true  == true  == true));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a == b == c; }", ftt, Boolean.valueOf(false == true  == true));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a == b == c; }", tft, Boolean.valueOf(true  == false == true));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a == b == c; }", ttf, Boolean.valueOf(true  == true  == false));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a == b == c; }", fft, Boolean.valueOf(false == false == true));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a == b == c; }", tff, Boolean.valueOf(true  == false == false));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a == b == c; }", ftf, Boolean.valueOf(false == true  == false));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a == b == c; }", fff, Boolean.valueOf(false == false == false));

      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a != b != c; }", ttt, Boolean.valueOf(true  != true  != true));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a != b != c; }", ftt, Boolean.valueOf(false != true  != true));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a != b != c; }", tft, Boolean.valueOf(true  != false != true));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a != b != c; }", ttf, Boolean.valueOf(true  != true  != false));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a != b != c; }", fft, Boolean.valueOf(false != false != true));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a != b != c; }", tff, Boolean.valueOf(true  != false != false));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a != b != c; }", ftf, Boolean.valueOf(false != true  != false));
      verify("static Boolean f(Boolean a, Boolean b, Boolean c) { return a != b != c; }", fff, Boolean.valueOf(false != false != false));

      //
      // int
      //
      verify("static Boolean f(Int a, Int b) { return a == b; }", MakeInts(0, 0),   Boolean.True);
      verify("static Boolean f(Int a, Int b) { return a == b; }", MakeInts(1, 0),   Boolean.False);
      verify("static Boolean f(Int a, Int b) { return a == b; }", MakeInts(0, 1),   Boolean.False);
      verify("static Boolean f(Int a, Int b) { return a == b; }", MakeInts(1, 1),   Boolean.True);
      verify("static Boolean f(Int a, Int b) { return a == b; }", MakeInts(-1, -1), Boolean.True);
      verify("static Boolean f(Int a, Int b) { return a == b; }", MakeInts(-1, -2), Boolean.False);
      verify("static Boolean f(Int a, Int b) { return a != b; }", MakeInts(0, 0),   Boolean.False);
      verify("static Boolean f(Int a, Int b) { return a != b; }", MakeInts(1, 0),   Boolean.True);
      verify("static Boolean f(Int a, Int b) { return a != b; }", MakeInts(0, 1),   Boolean.True);
      verify("static Boolean f(Int a, Int b) { return a != b; }", MakeInts(1, 1),   Boolean.False);
      verify("static Boolean f(Int a, Int b) { return a != b; }", MakeInts(77, -3), Boolean.True);
      verify("static Boolean f(Int a, Int b) { return a == b; }", new object[] { null,null  },     Boolean.True);
      verify("static Boolean f(Int a, Int b) { return a == b; }", new object[] { Int.Zero, null }, Boolean.False);
      verify("static Boolean f(Int a, Int b) { return a == b; }", new object[] { null, Int.Zero }, Boolean.False);
      verify("static Boolean f(Int a, Int b) { return a != b; }", new object[] { null,null  },     Boolean.False);
      verify("static Boolean f(Int a, Int b) { return a != b; }", new object[] { Int.Zero, null }, Boolean.True);
      verify("static Boolean f(Int a, Int b) { return a != b; }", new object[] { null, Int.Zero }, Boolean.True);

      //
      // floats
      //
      verify("static Boolean f(Double a, Double b) { return a == b; }", MakeFloats(0, 0),   Boolean.True);
      verify("static Boolean f(Double a, Double b) { return a == b; }", MakeFloats(1, 0),   Boolean.False);
      verify("static Boolean f(Double a, Double b) { return a == b; }", MakeFloats(0, 1),   Boolean.False);
      verify("static Boolean f(Double a, Double b) { return a == b; }", MakeFloats(1, 1),   Boolean.True);
      verify("static Boolean f(Double a, Double b) { return a == b; }", MakeFloats(-1, -1), Boolean.True);
      verify("static Boolean f(Double a, Double b) { return a == b; }", MakeFloats(-1, -2), Boolean.False);
      verify("static Boolean f(Double a, Double b) { return a != b; }", MakeFloats(0, 0),   Boolean.False);
      verify("static Boolean f(Double a, Double b) { return a != b; }", MakeFloats(1, 0),   Boolean.True);
      verify("static Boolean f(Double a, Double b) { return a != b; }", MakeFloats(0, 1),   Boolean.True);
      verify("static Boolean f(Double a, Double b) { return a != b; }", MakeFloats(1, 1),   Boolean.False);
      verify("static Boolean f(Double a, Double b) { return a != b; }", MakeFloats(77, -3), Boolean.True);
      verify("static Boolean f(Double a, Double b) { return a == b; }", new object[] { null,null  },     Boolean.True);
      verify("static Boolean f(Double a, Double b) { return a == b; }", new object[] { FanFloat.m_zero, null }, Boolean.False);
      verify("static Boolean f(Double a, Double b) { return a == b; }", new object[] { null, FanFloat.m_zero }, Boolean.False);
      verify("static Boolean f(Double a, Double b) { return a != b; }", new object[] { null,null  },     Boolean.False);
      verify("static Boolean f(Double a, Double b) { return a != b; }", new object[] { FanFloat.m_zero, null }, Boolean.True);
      verify("static Boolean f(Double a, Double b) { return a != b; }", new object[] { null, FanFloat.m_zero }, Boolean.True);

      //
      // str
      //
      verify("static Boolean f(Str a, Str b) { return a == b; }", MakeStrs(null, null), Boolean.True);
      verify("static Boolean f(Str a, Str b) { return a == b; }", MakeStrs("a",  null), Boolean.False);
      verify("static Boolean f(Str a, Str b) { return a == b; }", MakeStrs(null, "a"),  Boolean.False);
      verify("static Boolean f(Str a, Str b) { return a == b; }", MakeStrs("a", "a"),   Boolean.True);
      verify("static Boolean f(Str a, Str b) { return a == b; }", MakeStrs("a", "b"),   Boolean.False);
      verify("static Boolean f(Str a, Str b) { return a != b; }", MakeStrs(null, null), Boolean.False);
      verify("static Boolean f(Str a, Str b) { return a != b; }", MakeStrs("a",  null), Boolean.True);
      verify("static Boolean f(Str a, Str b) { return a != b; }", MakeStrs(null, "a"),  Boolean.True);
      verify("static Boolean f(Str a, Str b) { return a != b; }", MakeStrs("a", "a"),   Boolean.False);
      verify("static Boolean f(Str a, Str b) { return a != b; }", MakeStrs("a", "b"),   Boolean.True);

      //
      // Duration
      //
      verify("static Boolean f(Duration a, Duration b) { return a == b; }", MakeDurs(0, 0),  Boolean.True);
      verify("static Boolean f(Duration a, Duration b) { return a == b; }", MakeDurs(20, 0), Boolean.False);
      verify("static Boolean f(Duration a, Duration b) { return a != b; }", MakeDurs(0, 0),  Boolean.False);
      verify("static Boolean f(Duration a, Duration b) { return a != b; }", MakeDurs(20, 0), Boolean.True);

      //
      // same ===
      //
      verify("static Boolean f() { return null === null; }",        Boolean.True);
      verify("static Boolean f() { return 5 === null; }",           Boolean.False);
      verify("static Boolean f() { return null === 5; }",           Boolean.False);
      verify("static Boolean f() { return 5 === 5; }",              Boolean.True);
      verify("static Boolean f() { return \"x\" === \"x\"; }",      Boolean.True);
      verify("static Boolean f() { return \"x\" === \"y\"; }",      Boolean.False);
      verify("static Boolean f() { return !(\"x\" === \"y\"); }",   Boolean.True);
      verify("static Boolean f(Int x, Int y) { return x === y; }",  MakeInts(256, 256), Boolean.True);
      verify("static Boolean f(Int x, Int y) { return x === y; }",  MakeInts(2568888, 2568888), Boolean.False);

      // auto-cast matrix
      /*
      verify("Boolean f(Int a, Double b) { return a == b; }", new Object[] { Int.make(4), Double.valueOf(4) }, Boolean.True);
      verify("Boolean f(Int a, Double b) { return a != b; }", new Object[] { Int.make(4), Double.valueOf(4) }, Boolean.False);
      verify("Boolean f(Double a, Int b) { return a == b; }", new Object[] { Double.valueOf(-99), Int.make(-99) }, Boolean.True);
      verify("Boolean f(Double a, Int b) { return a != b; }", new Object[] { Double.valueOf(-99), Int.make(-99) }, Boolean.False);
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
      verify("static Boolean f(Int a, Int b) { return a < b; }", MakeInts(0, 0),  Boolean.valueOf(0 < 0));
      verify("static Boolean f(Int a, Int b) { return a < b; }", MakeInts(1, 0),  Boolean.valueOf(1 < 0));
      verify("static Boolean f(Int a, Int b) { return a < b; }", MakeInts(0, 1),  Boolean.valueOf(0 < 1));
      verify("static Boolean f(Int a, Int b) { return a < b; }", MakeInts(1, 1),  Boolean.valueOf(1 < 1));
      verify("static Boolean f(Int a, Int b) { return a < b; }", new object[] { null, null },      Boolean.False);
      verify("static Boolean f(Int a, Int b) { return a < b; }", new object[] { Int.Zero, null },  Boolean.False);
      verify("static Boolean f(Int a, Int b) { return a < b; }", new object[] { null, Int.Zero },  Boolean.True);

      verify("static Boolean f(Int a, Int b) { return a <= b; }", MakeInts(0,  0),   Boolean.valueOf(0  <= 0));
      verify("static Boolean f(Int a, Int b) { return a <= b; }", MakeInts(-1, 0),   Boolean.valueOf(-1 <= 0));
      verify("static Boolean f(Int a, Int b) { return a <= b; }", MakeInts(0,  -1),  Boolean.valueOf(0  <= -1));
      verify("static Boolean f(Int a, Int b) { return a <= b; }", MakeInts(-1, -1),  Boolean.valueOf(-1 <= -1));
      verify("static Boolean f(Int a, Int b) { return a <= b; }", new object[] { null, null },      Boolean.True);
      verify("static Boolean f(Int a, Int b) { return a <= b; }", new object[] { Int.Zero, null },  Boolean.False);
      verify("static Boolean f(Int a, Int b) { return a <= b; }", new object[] { null, Int.Zero },  Boolean.True);

      verify("static Boolean f(Int a, Int b) { return a > b; }", MakeInts(4, 4),  Boolean.valueOf(4 > 4));
      verify("static Boolean f(Int a, Int b) { return a > b; }", MakeInts(7, 4),  Boolean.valueOf(7 > 4));
      verify("static Boolean f(Int a, Int b) { return a > b; }", MakeInts(4, 7),  Boolean.valueOf(4 > 7));
      verify("static Boolean f(Int a, Int b) { return a > b; }", MakeInts(7, 7),  Boolean.valueOf(7 > 7));
      verify("static Boolean f(Int a, Int b) { return a > b; }", new object[] { null, null },      Boolean.False);
      verify("static Boolean f(Int a, Int b) { return a > b; }", new object[] { Int.Zero, null },  Boolean.True);
      verify("static Boolean f(Int a, Int b) { return a > b; }", new object[] { null, Int.Zero },  Boolean.False);

      verify("static Boolean f(Int a, Int b) { return a >= b; }", MakeInts(-2, -2),  Boolean.valueOf(-2 >= -2));
      verify("static Boolean f(Int a, Int b) { return a >= b; }", MakeInts(+2, -2),  Boolean.valueOf(+2 >= -2));
      verify("static Boolean f(Int a, Int b) { return a >= b; }", MakeInts(-2, +2),  Boolean.valueOf(-2 >= +2));
      verify("static Boolean f(Int a, Int b) { return a >= b; }", MakeInts(+2, +2),  Boolean.valueOf(+2 >= +2));
      verify("static Boolean f(Int a, Int b) { return a >= b; }", new object[] { null, null },      Boolean.True);
      verify("static Boolean f(Int a, Int b) { return a >= b; }", new object[] { Int.Zero, null },  Boolean.True);
      verify("static Boolean f(Int a, Int b) { return a >= b; }", new object[] { null, Int.Zero },  Boolean.False);

      verify("static Int f(Int a, Int b) { return a <=> b; }", MakeInts(3, 2),  Int.make(1));
      verify("static Int f(Int a, Int b) { return a <=> b; }", MakeInts(3, 3),  Int.make(0));
      verify("static Int f(Int a, Int b) { return a <=> b; }", MakeInts(2, 3),  Int.make(-1));
      verify("static Int f(Int a, Int b) { return a <=> b; }", new object[] { null, null },      Int.make(0));
      verify("static Int f(Int a, Int b) { return a <=> b; }", new object[] { Int.Zero, null },  Int.make(1));
      verify("static Int f(Int a, Int b) { return a <=> b; }", new object[] { null, Int.Zero },  Int.make(-1));

      //
      // MakeFloats
      //
      verify("static Boolean f(Double a, Double b) { return a < b; }", MakeFloats(0, 0),  Boolean.valueOf(0 < 0));
      verify("static Boolean f(Double a, Double b) { return a < b; }", MakeFloats(1, 0),  Boolean.valueOf(1 < 0));
      verify("static Boolean f(Double a, Double b) { return a < b; }", MakeFloats(0, 1),  Boolean.valueOf(0 < 1));
      verify("static Boolean f(Double a, Double b) { return a < b; }", MakeFloats(1, 1),  Boolean.valueOf(1 < 1));

      verify("static Boolean f(Double a, Double b) { return a <= b; }", MakeFloats(0,  0),   Boolean.valueOf(0  <= 0));
      verify("static Boolean f(Double a, Double b) { return a <= b; }", MakeFloats(-1, 0),   Boolean.valueOf(-1 <= 0));
      verify("static Boolean f(Double a, Double b) { return a <= b; }", MakeFloats(0,  -1),  Boolean.valueOf(0  <= -1));
      verify("static Boolean f(Double a, Double b) { return a <= b; }", MakeFloats(-1, -1),  Boolean.valueOf(-1 <= -1));

      verify("static Boolean f(Double a, Double b) { return a > b; }", MakeFloats(4, 4),  Boolean.valueOf(4 > 4));
      verify("static Boolean f(Double a, Double b) { return a > b; }", MakeFloats(7, 4),  Boolean.valueOf(7 > 4));
      verify("static Boolean f(Double a, Double b) { return a > b; }", MakeFloats(4, 7),  Boolean.valueOf(4 > 7));
      verify("static Boolean f(Double a, Double b) { return a > b; }", MakeFloats(7, 7),  Boolean.valueOf(7 > 7));

      verify("static Boolean f(Double a, Double b) { return a >= b; }", MakeFloats(-2, -2),  Boolean.valueOf(-2 >= -2));
      verify("static Boolean f(Double a, Double b) { return a >= b; }", MakeFloats(+2, -2),  Boolean.valueOf(+2 >= -2));
      verify("static Boolean f(Double a, Double b) { return a >= b; }", MakeFloats(-2, +2),  Boolean.valueOf(-2 >= +2));
      verify("static Boolean f(Double a, Double b) { return a >= b; }", MakeFloats(+2, +2),  Boolean.valueOf(+2 >= +2));

      verify("static Int f(Double a, Double b) { return a <=> b; }", MakeFloats(3, 2),  Int.make(1));
      verify("static Int f(Double a, Double b) { return a <=> b; }", MakeFloats(3, 3),  Int.make(0));
      verify("static Int f(Double a, Double b) { return a <=> b; }", MakeFloats(2, 3),  Int.make(-1));

      //
      // bool
      //
      verify("static Boolean f(Boolean a, Boolean b) { return a < b; }", ft,  Boolean.True);
      verify("static Boolean f(Boolean a, Boolean b) { return a < b; }", ff,  Boolean.False);
      verify("static Boolean f(Boolean a, Boolean b) { return a < b; }", tf,  Boolean.False);

      verify("static Boolean f(Boolean a, Boolean b) { return a <= b; }", ft,  Boolean.True);
      verify("static Boolean f(Boolean a, Boolean b) { return a <= b; }", ff,  Boolean.True);
      verify("static Boolean f(Boolean a, Boolean b) { return a <= b; }", tf,  Boolean.False);

      verify("static Boolean f(Boolean a, Boolean b) { return a > b; }", ft,  Boolean.False);
      verify("static Boolean f(Boolean a, Boolean b) { return a > b; }", ff,  Boolean.False);
      verify("static Boolean f(Boolean a, Boolean b) { return a > b; }", tf,  Boolean.True);

      verify("static Boolean f(Boolean a, Boolean b) { return a >= b; }", ft,  Boolean.False);
      verify("static Boolean f(Boolean a, Boolean b) { return a >= b; }", ff,  Boolean.True);
      verify("static Boolean f(Boolean a, Boolean b) { return a >= b; }", tf,  Boolean.True);

      verify("static Int f(Boolean a, Boolean b) { return a <=> b; }", tf,  Int.make(1));
      verify("static Int f(Boolean a, Boolean b) { return a <=> b; }", tt,  Int.make(0));
      verify("static Int f(Boolean a, Boolean b) { return a <=> b; }", ft,  Int.make(-1));

      //
      // str
      //
      verify("static Boolean f(Str a, Str b) { return a < b; }", MakeStrs("a", "b"),  Boolean.True);
      verify("static Boolean f(Str a, Str b) { return a < b; }", MakeStrs("a", "a"),  Boolean.False);
      verify("static Boolean f(Str a, Str b) { return a < b; }", MakeStrs("b", "a"),  Boolean.False);

      verify("static Boolean f(Str a, Str b) { return a <= b; }", MakeStrs("a", "b"),  Boolean.True);
      verify("static Boolean f(Str a, Str b) { return a <= b; }", MakeStrs("a", "a"),  Boolean.True);
      verify("static Boolean f(Str a, Str b) { return a <= b; }", MakeStrs("b", "a"),  Boolean.False);

      verify("static Boolean f(Str a, Str b) { return a > b; }", MakeStrs("a", "b"),  Boolean.False);
      verify("static Boolean f(Str a, Str b) { return a > b; }", MakeStrs("a", "a"),  Boolean.False);
      verify("static Boolean f(Str a, Str b) { return a > b; }", MakeStrs("b", "a"),  Boolean.True);

      verify("static Boolean f(Str a, Str b) { return a >= b; }", MakeStrs("a", "b"),  Boolean.False);
      verify("static Boolean f(Str a, Str b) { return a >= b; }", MakeStrs("a", "a"),  Boolean.True);
      verify("static Boolean f(Str a, Str b) { return a >= b; }", MakeStrs("b", "a"),  Boolean.True);

      verify("static Int f(Str a, Str b) { return a <=> b; }", MakeStrs("a", "b"),  Int.make(-1));
      verify("static Int f(Str a, Str b) { return a <=> b; }", MakeStrs("a", "a"),  Int.make(0));
      verify("static Int f(Str a, Str b) { return a <=> b; }", MakeStrs("b", "a"),  Int.make(1));

      verify("static Int f(Str a, Str b) { return a <=> b; }", MakeStrs(null, null), Int.make(0));
      verify("static Int f(Str a, Str b) { return a <=> b; }", MakeStrs(null, "a"),  Int.make(-1));
      verify("static Int f(Str a, Str b) { return a <=> b; }", MakeStrs("b", null),  Int.make(1));

      //
      // Duration
      //
      verify("static Boolean f(Duration a, Duration b) { return a < b; }", MakeDurs(3, 9),  Boolean.True);
      verify("static Boolean f(Duration a, Duration b) { return a < b; }", MakeDurs(3, 3),  Boolean.False);
      verify("static Boolean f(Duration a, Duration b) { return a < b; }", MakeDurs(9, 3),  Boolean.False);

      verify("static Boolean f(Duration a, Duration b) { return a <= b; }", MakeDurs(3, 9),  Boolean.True);
      verify("static Boolean f(Duration a, Duration b) { return a <= b; }", MakeDurs(3, 3),  Boolean.True);
      verify("static Boolean f(Duration a, Duration b) { return a <= b; }", MakeDurs(9, 3),  Boolean.False);

      verify("static Boolean f(Duration a, Duration b) { return a > b; }", MakeDurs(3, 9),  Boolean.False);
      verify("static Boolean f(Duration a, Duration b) { return a > b; }", MakeDurs(3, 3),  Boolean.False);
      verify("static Boolean f(Duration a, Duration b) { return a > b; }", MakeDurs(9, 3),  Boolean.True);

      verify("static Boolean f(Duration a, Duration b) { return a >= b; }", MakeDurs(3, 9),  Boolean.False);
      verify("static Boolean f(Duration a, Duration b) { return a >= b; }", MakeDurs(3, 3),  Boolean.True);
      verify("static Boolean f(Duration a, Duration b) { return a >= b; }", MakeDurs(9, 3),  Boolean.True);

      verify("static Int f(Duration a, Duration b) { return a <=> b; }", MakeDurs(3, 9),  Int.make(-1));
      verify("static Int f(Duration a, Duration b) { return a <=> b; }", MakeDurs(3, 3),  Int.make(0));
      verify("static Int f(Duration a, Duration b) { return a <=> b; }", MakeDurs(9, 3),  Int.make(1));

      //
      // auto-cast matrix
      //
      /* TODO
      verify("Boolean f(Int a, Double b) { return a < b; }",  new Object[] { Int.make(-6), Double.valueOf(-7)  }, Boolean.False);
      verify("Boolean f(Int a, Double b) { return a <= b; }", new Object[] { Int.make(-6), Double.valueOf(-7)  }, Boolean.False);
      verify("Boolean f(Int a, Double b) { return a > b; }",  new Object[] { Int.make(-6), Double.valueOf(-7)  }, Boolean.True);
      verify("Boolean f(Int a, Double b) { return a >= b; }", new Object[] { Int.make(-6), Double.valueOf(-7)  }, Boolean.True);

      verify("Boolean f(Double a, Int b) { return a < b; }",  new Object[] { Double.valueOf(99), Int.make(-99) }, Boolean.False);
      verify("Boolean f(Double a, Int b) { return a <= b; }", new Object[] { Double.valueOf(99), Int.make(-99) }, Boolean.False);
      verify("Boolean f(Double a, Int b) { return a > b; }",  new Object[] { Double.valueOf(99), Int.make(-99) }, Boolean.True);
      verify("Boolean f(Double a, Int b) { return a >= b; }", new Object[] { Double.valueOf(99), Int.make(-99) }, Boolean.True);

      verify("Int f(Double a, Int b) { return a <=> b; }", new Object[] { Double.valueOf(9), Int.make(-9) }, Int.make(1));
      verify("Int f(Double a, Int b) { return a <=> b; }", new Object[] { Double.valueOf(9), Int.make(9) },  Int.make(0));
      verify("Int f(Double a, Int b) { return a <=> b; }", new Object[] { Double.valueOf(9), Int.make(99) }, Int.make(-1));
      verify("Int f(Double a, Int b) { return a <=> b; }", new Object[] { Double.valueOf(9), Int.make(-9) }, Int.make(1));
      verify("Int f(Double a, Int b) { return a <=> b; }", new Object[] { Double.valueOf(9), Int.make(9) },  Int.make(0));
      verify("Int f(Double a, Int b) { return a <=> b; }", new Object[] { Double.valueOf(9), Int.make(99) }, Int.make(-1));
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
      verify("static Double f(Double a) { return -a; }", MakeFloats(1), Double.valueOf(-1));
      verify("static Double f(Double a) { return -a; }", MakeFloats(-1), Double.valueOf(1));
      verify("static Double f(Double a) { return -(a); }", MakeFloats(8), Double.valueOf(-8));
      verify("static Double f(Double a) { return -(-a); }", MakeFloats(8), Double.valueOf(8));

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
      verify("Double f(Double a, Double b) { return a * b; }", MakeFloats(0, 0), Double.valueOf(0));
      verify("Double f(Double a, Double b) { return a * b; }", MakeFloats(2, 5), Double.valueOf(10));
      verify("Double f(Double a, Double b) { return a * b; }", MakeFloats(-3.32, 66.44), Double.valueOf(-3.32*66.44));
      verify("Double f(Double a, Double b) { return a * 0.8; }", MakeFloats(-3.32, 66.44), Double.valueOf(-3.32*0.8));
      verify("Double f() { x := 3.0; x *= 6.0; return x; }", Double.valueOf(18));
      members = "Double x := 2.0; Double y;";
      verify("Double f() { x *= 3.0; return x; }", Double.valueOf(6));
      verify("Double f() { return x *= -3.0; }",   Double.valueOf(-6));
      o = verify("Double f() { return y = x *= -3f; }", Double.valueOf(-6));
        verify(Get(o, "x").Equals(Double.valueOf(-6)));
        verify(Get(o, "y").Equals(Double.valueOf(-6)));
      members = "static Double x := 0.0;";
      verify("static Double f() { return x *= 4f; }", Double.valueOf(0));

      // MakeDursation
      members = "x := 2ns; \n Duration y;";
      verify("Duration f(Duration a, Double b) { return a * b; }", new Object[] { Duration.make(4), Double.valueOf(3) }, Duration.make(12));
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
      verify("Double f(Int a, Double b) { return a * b; }", new Object[] { Int.make(10), Double.valueOf(-0.004) }, Double.valueOf(10L*-0.004));
      verify("Double f(Double a, Int b) { return a * b; }", new Object[] { Double.valueOf(1.2), Int.make(0xabcdL) }, Double.valueOf(1.2*0xabcdL));
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
      verify("Double f(Double a, Double b) { return a / b; }", MakeFloats(0, 1), Double.valueOf(0));
      verify("Double f(Double a, Double b) { return a / b; }", MakeFloats(20, 5), Double.valueOf(20d/5d));
      verify("Double f(Double a, Double b) { return a / b; }", MakeFloats(-3.32, 66.44), Double.valueOf(-3.32/66.44));
      verify("Double f(Double a, Double b) { return a / 0.8; }", MakeFloats(-3.32, 66.44), Double.valueOf(-3.32/0.8));
      verify("Double f() { Double x := 14.0; x /= 2.0; return x; }", Double.valueOf(7));
      members = "Double x := 8F;";
      verify("Double f() { x /= 4f; return x; }", Double.valueOf(2));
      verify("Double f() { return x /= 4f; }",    Double.valueOf(2));

      // duration
      verify("Duration f(Duration a, Double b) { return a / b; }", new Object[] { Duration.make(100), Double.valueOf(4)}, Duration.make(25));
      verify("Duration f(Duration a) { return a / 4.0; }", new Object[] { Duration.make(100), }, Duration.make(25));
      verify("Duration f() { x := 7ns; x /= 2.0; return x; }", Duration.make(3));
      members = "Duration x := 8ns;";
      verify("Duration f() { x /= 4.0; return x; }", Duration.make(2));
      verify("Duration f() { return x /= 4f; }",   Duration.make(2));

      // auto-cast matrix
      /* TODO
      verify("Double f(Int a, Double b) { return a / b; }", new Object[] { Int.make(10), Double.valueOf(-0.004) }, Double.valueOf(10L/-0.004));
      verify("Double f(Double a, Int b) { return a / b; }", new Object[] { Double.valueOf(1.2), Int.make(0xabcdL) }, Double.valueOf(1.2/0xabcdL));
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
      verify("Double f(Double a, Double b) { return a % b; }", MakeFloats(9, 4), Double.valueOf(1));
      verify("Double f(Double a, Double b) { return a % b; }", MakeFloats(20, 5), Double.valueOf(20d%5d));
      verify("Double f(Double a, Double b) { return a % b; }", MakeFloats(-3.32, 66.44), Double.valueOf(-3.32%66.44));
      verify("Double f(Double a, Double b) { return a % 0.8; }", MakeFloats(-3.32, 66.44), Double.valueOf(-3.32%0.8));
      verify("Double f() { Double x := 15.0; x %= 3.0; return x; }", Double.valueOf(0));
      members = "Double x := 9.0;";
      verify("Double f() { x %= 4.0; return x; }", Double.valueOf(1));
      verify("Double f() { return x %= 4.0; }",    Double.valueOf(1));

      // duration
      verify("Duration f(Duration a, Double b) { return a % b; }", new Object[] { Duration.make(13), Double.valueOf(4)}, Duration.make(1));
      verify("Duration f(Duration a) { return a % 4.0; }", new Object[] { Duration.make(13), }, Duration.make(1));
      verify("Duration f() { x := 7ns; x %= 5.0; return x; }", Duration.make(2));
      members = "Duration x := 10ns;";
      verify("Duration f() { x %= 4.0; return x; }", Duration.make(2));
      verify("Duration f() { return x %= 4f; }",   Duration.make(2));

      // auto-cast matrix
      /* TODO
      verify("Double f(Int a, Double b) { return a % b; }", new Object[] { Int.make(10), Double.valueOf(-0.004) }, Double.valueOf(10L%-0.004));
      verify("Double f(Double a, Int b) { return a % b; }", new Object[] { Double.valueOf(1.2), Int.make(0xabcdL) }, Double.valueOf(1.2%0xabcdL));
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
        verify("Boolean f(Int a, Int b) { return a & b == 0 }", MakeInts(0x2, 0x4), Boolean.True);
        verify("Boolean f(Int a, Int b) { return a & b == 2 }", MakeInts(0x2, 0x3), Boolean.True);
        verify("Boolean f(Int a, Int b) { return a & b != 2 }", MakeInts(0x2, 0x3), Boolean.False);
        verify("Boolean f(Int a, Int b) { return a | b == 3 }", MakeInts(0x2, 0x1), Boolean.True);
        verify("Boolean f(Int a, Int b) { return a ^ b == 1 }", MakeInts(0x2, 0x3), Boolean.True);
        // verify comparision lower precedence than bitwise (different than Java/C#)
        verify("Boolean f(Int a, Int b) { return a & b >= 2 }", MakeInts(0x2, 0x3), Boolean.True);
        verify("Boolean f(Int a, Int b) { return a | b < 2 }",  MakeInts(0x2, 0x1), Boolean.False);
        verify("Boolean f(Int a, Int b) { return a ^ b <= 5 }", MakeInts(0x2, 0x3), Boolean.True);
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
      verify("Double f(Double a, Double b) { return a + b; }", MakeFloats(0, 1), Double.valueOf(1));
      verify("Double f(Double a, Double b) { return a + b; }", MakeFloats(20, 5), Double.valueOf(20d+5d));
      verify("Double f(Double a, Double b) { return a + b; }", MakeFloats(-3.32, 66.44), Double.valueOf(-3.32+66.44));
      verify("Double f(Double a, Double b) { return a + 0.8; }", MakeFloats(-3.32, 66.44), Double.valueOf(-3.32+0.8));
      verify("Double f() { x := 5.0; x+=5.0; return x; }", Double.valueOf(10));
      members = "Double x := 5.0; Double y;";
      verify("Double f() { x += -3.0; return x; }", Double.valueOf(2));
      o = verify("Double f() { return y = x += -3.0; }", Double.valueOf(2));
        verify(Get(o, "x").Equals(Double.valueOf(2)));
        verify(Get(o, "y").Equals(Double.valueOf(2)));

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
      verify("Double f(Int a, Double b) { return a + b; }", new Object[] { Int.make(10), Double.valueOf(-0.004) }, Double.valueOf(10L+-0.004));
      verify("Double f(Double a, Int b) { return a + b; }", new Object[] { Double.valueOf(1.2), Int.make(0xabcdL) }, Double.valueOf(1.2+0xabcdL));
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
      verify("Double f(Double a, Double b) { return a - b; }", MakeFloats(0, 1), Double.valueOf(-1));
      verify("Double f(Double a, Double b) { return a - b; }", MakeFloats(20, 5), Double.valueOf(20d-5d));
      verify("Double f(Double a, Double b) { return a - b; }", MakeFloats(-3.32, 66.44), Double.valueOf(-3.32-66.44));
      verify("Double f(Double a, Double b) { return a - 0.8; }", MakeFloats(-3.32, 66.44), Double.valueOf(-3.32-0.8));
      verify("Double f() { x := 5.0; x -= 6.0; return x; }", Double.valueOf(-1));

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
      verify("Double f(Int a, Double b) { return a - b; }", new Object[] { Int.make(10), Double.valueOf(-0.004) }, Double.valueOf(10L-(-0.004)));
      members = "Double x := 9;";
      verify("Double f() { x -= 4; return x; }", Double.valueOf(5));
      verify("Double f() { return x -= 4; }", Double.valueOf(5));
      verify("Double f(Double a, Int b) { return a - b; }", new Object[] { Double.valueOf(1.2), Int.make(0xabcdL) }, Double.valueOf(1.2-0xabcdL));
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
      members = "Double x := 0.0;";
      o = verify("Double f() { return ++x; }", Double.valueOf(1)); verify(Get(o, "x").Equals(Double.valueOf(1)));
      o = verify("Double f() { return x++; }", Double.valueOf(0)); verify(Get(o, "x").Equals(Double.valueOf(1)));
      o = verify("Double f() { return --x; }", Double.valueOf(-1)); verify(Get(o, "x").Equals(Double.valueOf(-1)));
      o = verify("Double f() { return x--; }", Double.valueOf(0)); verify(Get(o, "x").Equals(Double.valueOf(-1)));
      members = "static Double x := 0.0;";
      o = verify("static Double f() { return ++x; }", Double.valueOf(1)); verify(Get(o, "x").Equals(Double.valueOf(1)));
      o = verify("static Double f() { return x++; }", Double.valueOf(0)); verify(Get(o, "x").Equals(Double.valueOf(1)));
      o = verify("static Double f() { return --x; }", Double.valueOf(-1)); verify(Get(o, "x").Equals(Double.valueOf(-1)));
      o = verify("static Double f() { return x--; }", Double.valueOf(0)); verify(Get(o, "x").Equals(Double.valueOf(-1)));
      members = "";
      o = verify("Double f(Double y) { return ++y; }", MakeFloats(3), Double.valueOf(4));
      o = verify("Double f(Double y) { return y++; }", MakeFloats(3), Double.valueOf(3));
      o = verify("Double f(Double y) { return --y; }", MakeFloats(3), Double.valueOf(2));
      o = verify("Double f(Double y) { return y--; }", MakeFloats(3), Double.valueOf(3));
      members = "Double x := 0.0;";
      o = verify("Double f(Double y) { return x = ++y; }", MakeFloats(3), Double.valueOf(4)); verify(Get(o, "x").Equals(Double.valueOf(4)));
      o = verify("Double f(Double y) { return x = y++; }", MakeFloats(3), Double.valueOf(3)); verify(Get(o, "x").Equals(Double.valueOf(3)));
      o = verify("Double f(Double y) { return x = --y; }", MakeFloats(3), Double.valueOf(2)); verify(Get(o, "x").Equals(Double.valueOf(2)));
      o = verify("Double f(Double y) { return x = y--; }", MakeFloats(3), Double.valueOf(3)); verify(Get(o, "x").Equals(Double.valueOf(3)));
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
      verify("Str f(Str a, Boolean b) { return a + b; }", new object[] {Str.make("a"), Boolean.valueOf(true)}, Str.make("atrue"));
      verify("Str f(Boolean a, Str b) { return a + b; }", new object[] {Boolean.valueOf(false), Str.make("a")}, Str.make("falsea"));
      verify("Str f() { return \"foo\" + true; }", Str.make("footrue"));
      verify("Str f() { return false + \" foo\"; }", Str.make("false foo"));

      // int
      verify("Str f(Str a, Int b) { return a + b; }", new object[] { Str.make("a"), Int.make(3) }, Str.make("a3"));
      verify("Str f(Int a, Str b) { return a + b; }", new object[] { Int.make(-99), Str.make("a") }, Str.make("-99a"));
      verify("Str f() { return \"foo \" + 77; }", Str.make("foo 77"));
      verify("Str f() { return 0 + \" foo\"; }", Str.make("0 foo"));

      // double
      verify("Str f(Str a, Double b) { return a + b; }", new object[] { Str.make("a"), Double.valueOf(3) }, Str.make("a3.0"));
      verify("Str f(Double a, Str b) { return a + b; }", new object[] { Double.valueOf(-99), Str.make("a") }, Str.make("-99.0a"));
      verify("Str f() { return \"foo \" + 77.0; }", Str.make("foo 77.0"));
      verify("Str f() { return 0.0 + \" foo\"; }", Str.make("0.0 foo"));

      // mix
      verify("Str f(Int a, Str b, Boolean c) { return a + b + c; }", new object[] { Int.make(3), Str.make(" wow "), Boolean.valueOf(true) }, Str.make("3 wow true"));
      verify("Str f(Int a, Str b, Boolean c) { return \"w\" + a + \"x\" + b + \"y\" + c + \"z\"; }", new Object[] { Int.make(3), Str.make(" wow "), Boolean.valueOf(true) }, Str.make("w3x wow ytruez"));
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

      verify("static Boolean f(Boolean x, Boolean y) { x = true; y = x; return y; }", ff, Boolean.True);
      verify("static Boolean f(Boolean x, Boolean y) { return x = y = true; }", ff, Boolean.True);

      verify("static Int f(Int x) { x = 17; return x; }", MakeInts(88), Int.make(17));
      verify("static Int f(Int x) { return  x = 17; }", MakeInts(88), Int.make(17));
      verify("static Str f(Str x) { x = \"yeah\"; return x; }", MakeStrs("not"), Str.make("yeah"));
      verify("static Str f(Str x) { return x = \"yeah\"; }", MakeStrs("not"), Str.make("yeah"));

      verify("Boolean f(Boolean x, Boolean y) { x = true; y = x; return y; }", ff, Boolean.True);
      verify("Int f(Int x) { x = 17; return x; }",     MakeInts(88), Int.make(17));
      verify("Int f(Int x) { return x = 17; }",        MakeInts(88), Int.make(17));
      verify("Double f(Double x) { x = 17.0; return x; }", MakeFloats(88), Double.valueOf(17));
      verify("Double f(Double x) { return x = 17.0; }",    MakeFloats(88), Double.valueOf(17));
      verify("Str f(Str x) { x = \"yeah\"; return x; }", MakeStrs("not"), Str.make("yeah"));
      verify("Obj f(Obj x) { x = \"yeah\"; return x; }", MakeStrs("not"), Str.make("yeah"));
//COMPILER      verifyErr("Int f(Int x) { x = \"no way\"; return x; }", "Type 'sys::Str' is not assignable to 'sys::Int'");

      // auto-cast matrix: int * x
//COMPILER      verifyErr("Int f(Int a, Double b) { a = b; return a; }", "Type 'sys::Double' is not assignable to 'sys::Int'");
//COMPILER      verifyErr("Int f(Int a, Double b) { a = 6.0; return a; }", "Type 'sys::Double' is not assignable to 'sys::Int'");

      // auto-cast matrix: Double * x
      /*
      verify("Double f(Double a, Int b) { a = b; return a; }", new Object[] { Double.valueOf(0), Int.make(6) }, Double.valueOf(6));
      verify("Double f(Double a, Int b) { a = 6; return a; }", new Object[] { Double.valueOf(0), Int.make(6) }, Double.valueOf(6));
      verify("Double f(Double a, Int b) { return a = b; }", new Object[] { Double.valueOf(0), Int.make(6) }, Double.valueOf(6));
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

      members = "Double x";
      verify("Double f() { return x; }", null);

      members = "x := 0.0";
      verify("Double f() { return x; }", Double.valueOf(0));
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
      members = "Double x; Double y;";
      verify("Double f() { x = -4.88; return x; }", Double.valueOf(-4.88));
      verify("Double f() { return x = -4.88; }", Double.valueOf(-4.88));
      verify("Double f() { return x = 88.0; }", Double.valueOf(88));
      o = verify("Double f() { return x = y = 7.0; }", Double.valueOf(7));
        verify(Get(o, "x").Equals(Double.valueOf(7)));
        verify(Get(o, "y").Equals(Double.valueOf(7)));
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
      verify("Boolean f() { return zero() > two(); }",   Boolean.False);
      verify("Boolean f() { return two()  > zero(); }",  Boolean.True);
      verify("Boolean f() { return two()  == zero(); }", Boolean.False);
      verify("Boolean f() { return two()  != zero(); }", Boolean.True);
      verify("Boolean f() { return two >  zero }",  Boolean.True);
      verify("Boolean f() { return two != zero }", Boolean.True);
    }

  //////////////////////////////////////////////////////////////////////////
  // Parens
  //////////////////////////////////////////////////////////////////////////

    void verifyParens()
    {
      members = "Int one() { return 1; }  Int two() { return 2; }";

      // literals wrapped in parens
      verify("static Boolean f() { return (false); }",     MakeBool(false));
      verify("static Boolean f() { return (true); }",      MakeBool(true));
      verify("static Boolean f() { return ((false)); }",   MakeBool(false));
      verify("static Int f() { return (0); }",          Int.make(0));
      verify("static Int f() { return (77); }",         Int.make(77));
      verify("static Int f() { return (-5); }",         Int.make(-5));
      verify("static Int f() { return ((0)); }",        Int.make(0));
      verify("static Str f() { return (\"foo\"); }",    Str.make("foo"));
      verify("static Str f() { return (((\"foo\"))); }",Str.make("foo"));
      verify("static Boolean f(Int a, Int b) { return (a > b); }",     MakeInts(2, 3),  MakeBool(false));
      verify("static Boolean f(Int a, Int b) { return (a) > (b); }",   MakeInts(7, -1), MakeBool(true));
      verify("static Boolean f(Int a, Int b) { return ((a) > (b)); }", MakeInts(7, -1), MakeBool(true));
      verify("Boolean f() { return (one() > two()); }",         MakeBool(false));
      verify("Boolean f() { return (one()) > (two()); }",       MakeBool(false));
      verify("Boolean f() { return ((one()) > (two())); }",     MakeBool(false));

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

        // Double to *
        verify("Str f(Double x) { return java.lang.String.valueOf(x); }",         MakeFloats(65), "65.0");
        verify("Str f(Double x) { return java.lang.String.valueOf((char)x); }",   MakeFloats(65), "A");
        verify("Str f(Double x) { return java.lang.Byte.toString((byte)x); }",    MakeFloats(1000), String.valueOf((byte)1000));
        verify("Str f(Double x) { return java.lang.Short.toString((short)x); }",  MakeFloats(0xFFFFF), String.valueOf((short)0xFFFFF));
        verify("Str f(Double x) { return java.lang.String.valueOf((int)x); }",    MakeFloats(-6), "-6");
        verify("Str f(Double x) { return java.lang.String.valueOf((long)x); }",   MakeFloats(5), "5");
        verify("Str f(Double x) { return java.lang.String.valueOf((float)x); }",  MakeFloats(6), "6.0");
        verify("Str f(Double x) { return java.lang.String.valueOf((double)x); }", MakeFloats(7), "7.0");

      }
        */
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    Boolean[] tt = { Boolean.True,  Boolean.True  };
    Boolean[] ft = { Boolean.False, Boolean.True  };
    Boolean[] tf = { Boolean.True,  Boolean.False };
    Boolean[] ff = { Boolean.False, Boolean.False };

    Boolean[] nn = { null,       null };
    Boolean[] tn = { Boolean.True,  null};
    Boolean[] nt = { null,       Boolean.True};

    Boolean[] ttt = { Boolean.True,  Boolean.True,  Boolean.True  };
    Boolean[] ftt = { Boolean.False, Boolean.True,  Boolean.True  };
    Boolean[] tft = { Boolean.True,  Boolean.False, Boolean.True  };
    Boolean[] ttf = { Boolean.True,  Boolean.True,  Boolean.False };
    Boolean[] fft = { Boolean.False, Boolean.False, Boolean.True  };
    Boolean[] ftf = { Boolean.False, Boolean.True,  Boolean.False };
    Boolean[] tff = { Boolean.True,  Boolean.False, Boolean.False };
    Boolean[] fff = { Boolean.False, Boolean.False, Boolean.False };

  }
}
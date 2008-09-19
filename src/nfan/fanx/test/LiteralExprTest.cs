//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//

using Fan.Sys;

namespace Fanx.Test
{
  /// <summary>
  /// LiteralExprTest
  /// </summary>
  public class LiteralExprTest : CompileTest
  {

  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    public override void Run()
    {
      verifyBoolLiterals();
      verifyIntLiterals();
      verifyCharLiterals();
      verifyFloatLiterals();
      verifyStrLiterals();
      verifyDurationLiterals();
      verifyUriLiterals();
      verifyTypeLiterals();
    }

  //////////////////////////////////////////////////////////////////////////
  // Boolean Literals
  //////////////////////////////////////////////////////////////////////////

    void verifyBoolLiterals()
    {
      verify("Bool f() { return true }",  Bool.True);
      verify("Bool f() { return false }", Bool.False);
      verify("Bool f() { return null; }", null);
    }

  //////////////////////////////////////////////////////////////////////////
  // Int Literals
  //////////////////////////////////////////////////////////////////////////

    void verifyIntLiterals()
    {
      verifyIntLiteral(System.UInt32.MinValue);
      verifyIntLiteral(System.UInt32.MinValue+1);
      verifyIntLiteral(System.UInt32.MinValue+2);
      verifyIntLiteral(-32769);
      verifyIntLiteral(-32768);
      verifyIntLiteral(-32767);
      verifyIntLiteral(-32766);
      verifyIntLiteral(-129);
      verifyIntLiteral(-128);
      verifyIntLiteral(-127);
      verifyIntLiteral(-126);
      verifyIntLiteral(-100);
      verifyIntLiteral(-2);
      verifyIntLiteral(-1);
      verifyIntLiteral(0);
      verifyIntLiteral(1);
      verifyIntLiteral(2);
      verifyIntLiteral(3);
      verifyIntLiteral(4);
      verifyIntLiteral(5);
      verifyIntLiteral(6);
      verifyIntLiteral(100);
      verifyIntLiteral(126);
      verifyIntLiteral(127);
      verifyIntLiteral(128);
      verifyIntLiteral(129);
      verifyIntLiteral(254);
      verifyIntLiteral(255);
      verifyIntLiteral(256);
      verifyIntLiteral(257);
      verifyIntLiteral(32766);
      verifyIntLiteral(32767);
      verifyIntLiteral(32768);
      verifyIntLiteral(32769);
      verifyIntLiteral(65535);
      verifyIntLiteral(65536);
      verifyIntLiteral(65537);
      verifyIntLiteral(65538);
      verifyIntLiteral(123456);
      verifyIntLiteral(1234567);
      verifyIntLiteral(System.UInt32.MaxValue-2);
      verifyIntLiteral(System.UInt32.MaxValue-1);
      verifyIntLiteral(System.UInt32.MaxValue);
      //verifyIntLiteral(0xabcd0123fedc4567L);
      //verifyIntLiteral(Long.MIN_VALUE);
      //verifyIntLiteral(Long.MAX_VALUE);
      verify("Int f() { return null; }", null);
    }

    void verifyIntLiteral(long val)
    {
      verify("Int f() { return " + val + "; }", Int.make(val));
      //verify("static Int f() { return 0x" + Long.toHexString(val) + "; }", Int.make(val));
    }

  //////////////////////////////////////////////////////////////////////////
  // Char Literals
  //////////////////////////////////////////////////////////////////////////

    void verifyCharLiterals()
    {
      verify("Int f() { return 'a'; }",      Int.make('a'));
      verify("Int f() { return '_'; }",      Int.make('_'));
      verify("Int f() { return '\n'; }",     Int.make('\n'));
      verify("Int f() { return '\0'; }",     Int.make('\0'));
      verify("Int f() { return '\''; }",     Int.make('\''));
      verify("Int f() { return '\uabcd'; }", Int.make('\uabcd'));
    }

  //////////////////////////////////////////////////////////////////////////
  // Float Literals
  //////////////////////////////////////////////////////////////////////////

    void verifyFloatLiterals()
    {
      verify("Float f() { return 0.0; }",       Float.make(0));
      verify("Float f() { return 2.0; }",       Float.make(2));
      verify("Float f() { return +1.0; }",      Float.make(1));
      verify("Float f() { return -1.0; }",      Float.make(-1));
      verify("Float f() { return 0.005; }",     Float.make(0.005));
      verify("Float f() { return -1000.003; }", Float.make(-1000.003));
      verify("Float f() { return -4.5e33; }",   Float.make(-4.5e33));
      verify("Float f() { return null; }",      null);
    }

  //////////////////////////////////////////////////////////////////////////
  // Str Literals
  //////////////////////////////////////////////////////////////////////////

    void verifyStrLiterals()
    {
      verify("Str f() { return \"a\"; }", Str.make("a"));
      verify("Str f() { return \"hello world\"; }", Str.make("hello world"));
      verify("Str f() { return null; }", null);
    }

  //////////////////////////////////////////////////////////////////////////
  // Duration Literals
  //////////////////////////////////////////////////////////////////////////

    void verifyDurationLiterals()
    {
      long ms = 1000L*1000L;
      long sec = 1000L*ms;
      long min = 60L*sec;
      long hr  = 60L*min;
      verify("Duration f() { return 0ns; }",      Duration.make(0));
      verify("Duration f() { return 1ns; }",      Duration.make(1));
      verify("Duration f() { return -1ns; }",     Duration.make(-1));
      verify("Duration f() { return 1_999ns; }",  Duration.make(1999));
      verify("Duration f() { return -2ms; }",     Duration.make(-2*ms));
      verify("Duration f() { return 0.5sec; }",   Duration.make(sec/2L));
      verify("Duration f() { return 24hr; }",     Duration.make(24L*hr));
    }

  //////////////////////////////////////////////////////////////////////////
  // Uri Literals
  //////////////////////////////////////////////////////////////////////////

    void verifyUriLiterals()
    {
      verify("Uri f() { return `http://www.google.com`; }", Uri.fromStr("http://www.google.com"));
      verify("Uri f() { return null; }", null);
    }

  //////////////////////////////////////////////////////////////////////////
  // Type Literals
  //////////////////////////////////////////////////////////////////////////

    void verifyTypeLiterals()
    {
      // verify basic sys types
      verify("Type f() { return Bool.type }",  Sys.BoolType);
      verify("Type f() { return Int.type }",   Sys.IntType);
      verify("Type f() { return Str.type; }",   Sys.StrType);
      verify("Type f() { return Type.type }",  Sys.TypeType);

      // verify variegated list literal
      //verify("static Type f() { return Str[].type }",  Sys.StrType.toListOf());
      //verify("static Type f() { return Int[][].type }",  Sys.IntType.toListOf().toListOf());

      // verify non-sys non-variegated type
      //Type t = CompileToType("class HappyDays { static Type f() { return HappyDays.type } }");
      //verify(t.method("f", true).call(null) == t);

      // verify multiple usages of same type literal
      //t = CompileToType(
      //  "class Coolio {\n" +
      //  "  static Type f() { return Coolio.type }\n" +
      //  "  static Type g() { return Coolio.type }\n" +
      //  "  static Type h() { return Coolio[].type }\n" +
      //  "  static Type i() { return Coolio[].type }\n" +
      //  "  static Type j() { return Obj.type }\n" +
      //  "}");
      //verify(t.method("f", true).call(null) == t);
      //verify(t.method("g", true).call(null) == t);
      //verify(t.method("h", true).call(null) == t.toListOf());
      //verify(t.method("i", true).call(null) == t.toListOf());
      //verify(t.method("j", true).call(null) == Sys.ObjType);
    }

  }
}

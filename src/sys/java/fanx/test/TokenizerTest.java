//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Sep 05  Brian Frank  Creation
//
package fanx.test;

import java.io.*;
import java.io.File;
import java.math.*;
import java.util.*;
import fan.sys.*;
import fanx.serial.*;
import fanx.util.*;

/**
 * TokenizerTest
 */
public class TokenizerTest
  extends Test
{

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  public void run()
    throws Exception
  {
    // empty source
    verify("",         new Tok[0]);
    verify(" ",        new Tok[0]);
    verify("\n",       new Tok[0]);
    verify(" \n \n",   new Tok[0]);

    // identifiers
    verify("a",        id("a"));
    verify(" a",       id("a"));
    verify("a ",       id("a"));
    verify(" a ",      id("a"));
    verify("ab",       id("ab"));
    verify("a\n",      id("a"));
    verify("a77",      id("a77"));
    verify("x9y",      id("x9y"));
    verify("_",        id("_"));
    verify("_foo_",    id("_foo_"));
    verify("For",      id("For"));
    verify("java",     id("java"));
    verify("net",      id("net"));
    verify("jalias",   id("jalias"));
    verify("nalias",   id("nalias"));
    verify("jcode",    id("jcode"));
    verify("ncode",    id("ncode"));

    // numbers
    verify("3",            i(3));
    verify("+9",           i(9));
    verify("3f",           f(3d));
    verify("3F",           f(3D));
    verify("3.0f",         f(3.0));
    verify("3.0f",         f(3.0));
    verify("-3.0f",        f(-3.0));
    verify("73",           i(73));
    verify("-73",          i(-73));
    verify("73f",          f(73d));
    verify("73F",          f(73D));
    verify("73.0f",        f(73.0));
    verify("73.0f",        f(73.0));
    verify("123456",       i(123456));
    verify("123456f",      f(123456d));
    verify("123456F",      f(123456D));
    verify("123456.0f",    f(123456.0));
    verify("123456.0f",    f(123456.0));
    verify("07",           i(07));
    verify("7f",           f(7f));
    verify("07.0f",        f(07f));
    verify(".2f",          f(.2));
    verify("0.2f",         f(0.2));
    verify("0.007f",       f(0.007));
    verify(".12345f",      f(.12345));
    verify("0.12345f",     f(.12345));
    verify("12345.6789f",  f(12345.6789));
    verify("3e6f",         f(3e6));
    verify("3E6f",         f(3E6));
    verify("3.0e6F",       f(3.0e6));
    verify("3.0E6F",       f(3.0E6));
    verify("3e-6f",        f(3e-6));
    verify("3E-6f",        f(3E-6));
    verify(".2e+6f",       f(.2e+6));
    verify(".2E+6F",       f(.2E+6));
    verify(".2e-03f",      f(.2e-03));
    verify(".2E-03f",      f(.2E-03));
    verify("1_234",        i(1234));
    verify("1_234_567",    i(1234567));
    verify("1.234_567F",   f(1.234567));
    verify("1.2e3_00f",    f(1.2e300));
    verify("1_2.3_7e5_6F", f(12.37e56));
    verify("0x3",          i(0x3));
    verify("0x03",         i(0x03));
    verify("0x123",        i(0x123));
    verify("0xabcdef",     i(0xabcdef));
    verify("0xABCDEF",     i(0xABCDEF));
    verify("0x3aF7cE",     i(0x3aF7cE));
    verify("0x12345678",   i(0x12345678));
    verify("0xffffffff",   i(0xffffffffL));
    verify("0xfedcba98",   i(0xfedcba98L));
    verify("0xfedcba9812345678",     i(0xfedcba9812345678L));
    verify("0xFFFFFFFFFFFFFFFF",     i(0xFFFFFFFFFFFFFFFFL));
    verify("0xffff_ffff",            i(0xffffffffL));
    verify("0xFFFF_FFFF_FFFF_FFFF",  i(0xFFFFFFFFFFFFFFFFL));
    verify("2147483647",             i(2147483647L));
    //verify("-9223372036854775808",   i(-9223372036854775808L));
    verify("9223372036854775807",    i(9223372036854775807L));
    //verify("-9_223_372_036_854_775_808", i(-9223372036854775808L));
    verify("9_223_372_036_854_775_807", i(9223372036854775807L));
    verify("1.5E-45f",               f(1.5E-45));
    verify("3.402E77f",              f(3.402E77));
    verify("1.4E-100f",              f(1.4E-100));
    verify("1.7976931348623157E38f", f(1.7976931348623157E38));
    verify("3.0d", dec("3.0"));
    verify("3.00", dec("3.00"));
    verifyInvalid("3e");
    verifyInvalid("-3e");
    verifyInvalid("-.3e");
    verifyInvalid("+0.3e");
    verifyInvalid("0x");
    verifyInvalid("0xG");
    verifyInvalid("0x1FFFFFFFFFFFFFFFF");
    /* int bounds
    verifyInvalid("-2147483649");
    verifyInvalid("2147483648");
    verifyInvalid("-12345678900");
    verifyInvalid("+12345678900");
    */
    // these are not caught right now (20+ digits is caught)
    // verify("-9223372036854775808",  l(-9223372036854775808L));
    // verify("9223372036854775807",   l(9223372036854775807L));
    //verifyInvalid("-92233720368547758080");
    verifyInvalid("92233720368547758070");
    //verifyInvalid("-92233720368547758080");
    verifyInvalid("92233720368547758070");

    // char literals
    verify("'a'",       i('a'));
    verify("'X'",       i('X'));
    verify("' '",       i(' '));
    verify("'\"'",      i('"'));
    verify("'\\n'",     i('\n'));
    verify("'\\r'",     i('\r'));
    verify("'\\''",     i('\''));
    verify("'\\uabcd'", i('\uabcd'));
    verifyInvalid("'a");
    verifyInvalid("'ab'");
    verifyInvalid("'\\q'");
    verifyInvalid("'\\ug000'");

    // durations
    verify("0ns",        dur(0));
    verify("5ns",        dur(5));
    verify("1ms",        dur(1000L*1000L));
    verify("1sec",       dur(1000L*1000L*1000L));
    verify("-5sec",      dur(-5000L*1000L*1000L));
    verify("1min",       dur(60L*1000L*1000L*1000L));
    verify("1hr",        dur(60L*60L*1000L*1000L*1000L));
    verify("0.5ms",      dur(500L*1000L));
    verify("-3.2ms",     dur(-3200L*1000L));
    verify("0.001sec",   dur(1000L*1000L));
    verify("0.25min",    dur(15L*1000L*1000L*1000L));
    verify("24hr",       dur(24L*60L*60L*1000L*1000L*1000L));
    verify("876000hr",   dur(876000L*60L*60L*1000L*1000L*1000L));  // 100yr
    verify("1day",       dur(24L*60L*60L*1000L*1000L*1000L)); // 1day
    verify("0.5day",     dur(12L*60L*60L*1000L*1000L*1000L)); // 1/2yr
    verify("30day",      dur(30L*24L*60L*60L*1000L*1000L*1000L)); // 1day
    verify("36500day",   dur(876000L*60L*60L*1000L*1000L*1000L));  // 100yr

    // strings
    verify("\"\"",        s(""));
    verify("\"a\"",       s("a"));
    verify("\"ab\"",      s("ab"));
    verify("\"abc\"",     s("abc"));
    verify("\"a b\"",     s("a b"));
    verify("\"a\\nb\"",   s("a\nb"));
    verify("\"ab\\ncd\"", s("ab\ncd"));
    verify("\"\\b\"",     s("\b"));
    verify("\"\\t\"",     s("\t"));
    verify("\"\\n\"",     s("\n"));
    verify("\"\\f\"",     s("\f"));
    verify("\"\\r\"",     s("\r"));
    verify("\"\\\"\"",    s("\""));
    verify("\"''\"",      s("''"));
    verify("\"\\r\\n\"",  s("\r\n"));
    verify("\"\\u0001\"", s("\u0001"));
    verify("\"\\u0010\"", s("\u0010"));
    verify("\"\\u0100\"", s("\u0100"));
    verify("\"\\u1000\"", s("\u1000"));
    verify("\"\\uF000\"", s("\uF000"));
    verify("\"\\uFFFF\"", s("\uFFFF"));
    verify("\"\\uabcd\"", s("\uabcd"));
    verify("\"\\uABCD\"", s("\uABCD"));
    verify("\"a\nb\"",    s("a\nb"));      // with newline
    verify("\"a\nb\r c\"",s("a\nb\n c"));  // with norm newline
    verify("\"a\nb\r\nc\r\"",s("a\nb\nc\n"));  // with norm newline
    verifyInvalid("\"");
    verifyInvalid("\"a");
    verifyInvalid("\"a\n");
    //verifyInvalid("\"\n\"");
    //verifyInvalid("\"a\n\"");
    verifyInvalid("\"\\u000g\"");
    verifyInvalid("\"\\u00g0\"");
    verifyInvalid("\"\\u0g00\"");
    verifyInvalid("\"\\ug000\"");

    // uri literals
    verify("``",               uri(""));
    verify("`.`",              uri("."));
    verify("`'\"`",            uri("'\""));
    verify("`http://f/`",      uri("http://f/"));
    verify("`/foo bar.txt?q`", uri("/foo bar.txt?q"));
    verify("`\\$`",            uri("$"));
    verify("`\u1234 \\u0abc \\` \\n\\t`",  uri("\u1234 \u0abc ` \n\t"));

    // comments
    verifyImpl("// foo bar",       new Tok[0]);
    verifyImpl("/* foo bar */",    new Tok[0]);
    verifyImpl("a// /* */",        new Tok[] { id("a") } );
    verifyImpl("a// /* */more...", new Tok[] { id("a") } );
    verifyImpl("a// /* */more\n",  new Tok[] { id("a") } );
    verifyImpl("a// /* */more\nx", new Tok[] { id("a"), id("x") } );
    verifyImpl("a/* foo bar */",   new Tok[] { id("a") } );
    verifyImpl("a// blah blah\nb", new Tok[] { id("a"), id("b") } );
    verifyImpl("a/* blah blah*/b", new Tok[] { id("a"), id("b") } );
    verifyImpl("a/* 33 // 33 */b", new Tok[] { id("a"), id("b") } );
    verifyImpl("a/* /*33*/ // 33 */b", new Tok[] { id("a"), id("b") } );

    // symbols
    verify(";",       new Tok(Token.SEMICOLON));
    verify(",",       new Tok(Token.COMMA));
    verify("=",       new Tok(Token.EQ));
    verify("{",       new Tok(Token.LBRACE));
    verify("}",       new Tok(Token.RBRACE));
    verify("(",       new Tok(Token.LPAREN));
    verify(")",       new Tok(Token.RPAREN));
    verify("[",       new Tok(Token.LBRACKET));
    verify("]",       new Tok(Token.RBRACKET));
    verify(":",       new Tok(Token.COLON));
    verify("[]",      new Tok(Token.LRBRACKET));
    verifyInvalid("*");

    // double tokens
    verify("a b",       id("a"),  id("b"));
    verify("a\nb",      id("a"),  id("b"));
    verify("a3\n_f",    id("a3"), id("_f"));
    verify("a;b",       id("a"),  new Tok(Token.SEMICOLON), id("b"));
    verify("1 2",       i(1), i(2));

    // position checking
    Tok[] tok;
    tok = tokenize("\nfoo");
    verifyPos(tok[0], 2, 1);  verify(tok[0].equals(id("foo")));
    tok = tokenize("\n\n bar");
    verifyPos(tok[0], 3, 2);  verify(tok[0].equals(id("bar")));
    tok = tokenize("a\nb\nc");
    verifyPos(tok[0], 1, 1);  verify(tok[0].equals(id("a")));
    verifyPos(tok[1], 2, 1);  verify(tok[1].equals(id("b")));
    verifyPos(tok[2], 3, 1);  verify(tok[2].equals(id("c")));
    tok = tokenize(
    /*         123456789_123456789_1234 *
    /*  1 */  "foo bar\n" +
    /*  2 */  "here:\"there\"//junk\n" +
    /*  3 */  " 308 1.0f 55 8f\r" +
    /*  4 */  "/* a b /*c*/ d \n" +
    /*  5 */  "*/ = ;\n" +
    /*  6 */  "  a\n" +
    /*  7 */  " /*/* /*f*/ */!** */  b\r\n" +
    /*  8 */  " [\n" +
    /*  9 */  "\r\n" +
    /* 10 */  "     bear\n" +
    /* 11 */  "\n" +
    /* 12 */  "}");
    verifyPos(tok[0],   1, 1);  // foo
    verifyPos(tok[1],   1, 5);  // bar
    verifyPos(tok[2],   2, 1);  // here
    verifyPos(tok[3],   2, 5);  // :
    verifyPos(tok[4],   2, 6);  // "there"
    verifyPos(tok[5],   3, 2);  // 308
    verifyPos(tok[6],   3, 6);  // 1.0
    verifyPos(tok[7],   3, 11); // 55
    verifyPos(tok[8],   3, 14); // 8r
    verifyPos(tok[9],   5, 4);  // =
    verifyPos(tok[10],  5, 6);  // ;
    verifyPos(tok[11],  6, 3);  // a
    verifyPos(tok[12],  7, 23); // b
    verifyPos(tok[13],  8, 2);  // [
    verifyPos(tok[14], 10, 6);  // bear
    verifyPos(tok[15], 12, 1);  // }
  }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  public Tok[] tokenize(String src)
  {
    InStream in = FanStr.in(src);
    Tokenizer tokenizer = new Tokenizer(in);

    ArrayList acc = new ArrayList();
    while (true)
    {
      int tt = tokenizer.next();
      if (tt < 0) break;
      verify(tt, tokenizer.type);
      acc.add(new Tok(tt, tokenizer.val, tokenizer.line));
    }
    return (Tok[])acc.toArray(new Tok[acc.size()]);
  }

  public void verify(String src, Tok want)
  {
    verify(src, new Tok[] { want });
  }

  public void verify(String src, Tok want0, Tok want1)
  {
    verify(src, new Tok[] { want0, want1 });
  }

  public void verify(String src, Tok want0, Tok want1, Tok want2)
  {
    verify(src, new Tok[] { want0, want1, want2 });
  }

  public void verify(String src, Tok[] want)
  {
    // try exact
    verifyImpl(src, want);

    // try with trailing semi colon to ensure
    // tokenizer  left in correct state
    Tok[] withSemi = new Tok[want.length+1];
    System.arraycopy(want, 0, withSemi, 0, want.length);
    withSemi[want.length] = new Tok(Token.SEMICOLON);
    verifyImpl(src + ";", withSemi);
  }

  public void verifyImpl(String src, Tok[] want)
  {
    Tok[] got = tokenize(src);

    /*
    System.out.println("-- Tokenize \"" + src.replace('\n', 'n') + "\" -> " + got.length);
    for (int i=0; i<got.length; ++i)
      System.out.println("got[" + i + "] =" + got[i]);
    */

    verify(got.length == want.length);
    for (int i=0; i<got.length; ++i)
    {
      if (verbose) System.out.println("  [" + i + "] " + got[i] + " ?= " + want[i]);
      verify(got[i], want[i]);
    }
  }

  public void verifyInvalid(String src)
  {
    RuntimeException ex = null;
    try
    {
      tokenize(src);
    }
    catch (RuntimeException e)
    {
      // System.out.println(e);
      ex = e;
    }
    verify(ex != null);
  }

  public void verifyPos(Tok t, int line, int col)
  {
    // System.out.println(" pos " + t.line + " ?= " + line + "  " + t + "  " + t.val);
    verify(t.line == line);
  }

//////////////////////////////////////////////////////////////////////////
// Tok Factory
//////////////////////////////////////////////////////////////////////////

  public Tok id(String v)  { return new Tok(Token.ID, v); }
  public Tok i(long v)     { return new Tok(Token.INT_LITERAL,   Long.valueOf(v));    }
  public Tok f(double v)   { return new Tok(Token.FLOAT_LITERAL, Double.valueOf(v));  }
  public Tok s(String v)   { return new Tok(Token.STR_LITERAL,   v); }
  public Tok dec(String v) { return new Tok(Token.DECIMAL_LITERAL,  FanDecimal.fromStr(v)); }
  public Tok dur(long v)   { return new Tok(Token.DURATION_LITERAL,  Duration.make(v)); }
  public Tok uri(String v) { return new Tok(Token.URI_LITERAL,   Uri.fromStr(v)); }

//////////////////////////////////////////////////////////////////////////
// Tok (type/val combo for testing)
//////////////////////////////////////////////////////////////////////////

  static class Tok
  {
    Tok(int t) { this(t, null, -1); }
    Tok(int t, Object v) { this(t, v, -1); }
    Tok(int t, Object v, int l) { type = t; val = v; line = l; }

    public String toString()
    {
      if (val instanceof String)
        return "\"" + StrUtil.asCode(val.toString()) + "\"";
      else
        return Token.toString(type) + " " + val;
    }

    public boolean equals(Object obj)
    {
      Tok that = (Tok)obj;
      return type == that.type && Test.equals(val, that.val);
    }

    int type;
    Object val;
    int line;
  }

}
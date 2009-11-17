//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 Sep 05  Brian Frank  Creation for Fan compiler
//   17 Aug 07  Brian        Rework for serialization parser
//
package fanx.serial;

import java.math.*;
import fan.sys.*;
import fanx.util.StrUtil;

/**
 * Tokenizer inputs a stream of Unicode characters and
 * outputs tokens for the Fantom serialization grammar.
 */
public class Tokenizer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  /**
   * Construct for specified input stream.
   */
  public Tokenizer(InStream in)
  {
    this.in = in;
    consume();
    consume();
  }

////////////////////////////////////////////////////////////////
// Access
////////////////////////////////////////////////////////////////

  /**
   * Read the next token from the stream.  The token is
   * available via the 'type' and 'val' fields.  The line
   * of the current token is available in 'line' field.
   * Return the 'type' field or -1 if at end of stream.
   */
  public int next()
  {
    if (undo != null) { undo.reset(this); undo = null; return type; }
    val = null;
    return type = doNext();
  }

  /**
   * Read the next token, set the 'val' field but return
   * type without worrying setting the 'type' field.
   */
  private int doNext()
  {
    while (true)
    {
      // skip whitespace
      while (curt == SPACE) consume();
      if (cur < 0) return Token.EOF;

      // alpha means identifier
      if (curt == ALPHA) return id();

      // number
      if (curt == DIGIT) return number(false);

      // symbol
      switch (cur)
      {
        case '+':   consume(); return number(false);
        case '-':   consume(); return number(true);
        case '"':   return str();
        case '\'':  return ch();
        case '`':   return uri();
        case '(':   consume(); return Token.LPAREN;
        case ')':   consume(); return Token.RPAREN;
        case ',':   consume(); return Token.COMMA;
        case ';':   consume(); return Token.SEMICOLON;
        case '=':   consume(); return Token.EQ;
        case '{':   consume(); return Token.LBRACE;
        case '}':   consume(); return Token.RBRACE;
        case '#':   consume(); return Token.POUND;
        case '?':   consume(); return Token.QUESTION;
        case '@':   consume(); return Token.AT;
        case '.':
          if (peekt == DIGIT) return number(false);
          consume();
          return Token.DOT;
        case '[':
          consume();
          if (cur == ']') { consume(); return Token.LRBRACKET; }
          return Token.LBRACKET;
        case ']':
          consume();
          return Token.RBRACKET;
        case ':':
          consume();
          if (cur == ':') { consume(); return Token.DOUBLE_COLON; }
          return Token.COLON;
        case '*':
          if (peek == '*') { skipCommentSL(); continue; }
          break;
        case '/':
          if (peek == '/') { skipCommentSL(); continue; }
          if (peek == '*') { skipCommentML(); continue; }
          break;
      }

      // invalid character
      throw err("Unexpected symbol: " + (char)cur + " (0x" + Integer.toHexString(cur) + ")");
    }
  }

//////////////////////////////////////////////////////////////////////////
// Word
//////////////////////////////////////////////////////////////////////////

  /**
   * Parse an identifier: alpha (alpha|number)*
   */
  private int id()
  {
    StringBuilder s = new StringBuilder();
    int first = cur;
    while ((curt == ALPHA || curt == DIGIT) && cur > 0)
    {
      s.append((char)cur);
      consume();
    }

    String val = s.toString();
    switch (first)
    {
      case 'a':
        if (val.equals("as")) { return Token.AS; }
        break;
      case 'f':
        if (val.equals("false")) { this.val = false; return Token.BOOL_LITERAL; }
        break;
      case 'n':
        if (val.equals("null")) { this.val = null; return Token.NULL_LITERAL; }
        break;
      case 't':
        if (val.equals("true")) { this.val = true; return Token.BOOL_LITERAL; }
        break;
      case 'u':
        if (val.equals("using")) { return Token.USING; }
        break;
    }

    this.val = val;
    return Token.ID;
  }

//////////////////////////////////////////////////////////////////////////
// Number
//////////////////////////////////////////////////////////////////////////

  /**
   * Parse a number literal token.
   */
  private int number(boolean neg)
  {
    // check for hex value
    if (cur == '0' && peek == 'x')
      return hex();

    // read whole part
    StringBuilder s = null;
    long whole = 0;
    int wholeCount = 0;
    while (curt == DIGIT)
    {
      if (s != null)
      {
        s.append((char)cur);
      }
      else
      {
        whole = whole*10 + (cur - '0');
        wholeCount++;
        if (wholeCount >= 18) { s = new StringBuilder(32); if (neg) s.append('-'); s.append(whole); }
      }
      consume();
      if (cur == '_') consume();
    }

    // fraction part
    boolean floating = false;
    if (cur == '.' && peekt == DIGIT)
    {
      floating = true;
      if (s == null) { s = new StringBuilder(32); if (neg) s.append('-'); s.append(whole); }
      s.append('.');
      consume();
      while (curt == DIGIT)
      {
        s.append((char)cur);
        consume();
        if (cur == '_') consume();
      }
    }

    // exponent
    if (cur == 'e' || cur == 'E')
    {
      floating = true;
      if (s == null) { s = new StringBuilder(32); if (neg) s.append('-'); s.append(whole); }
      s.append('e');
      consume();
      if (cur == '-' || cur == '+') { s.append((char)cur); consume(); }
      if (curt != DIGIT) throw err("Expected exponent digits");
      while (curt == DIGIT)
      {
        s.append((char)cur);
        consume();
        if (cur == '_') consume();
      }
    }

    // check for suffixes
    boolean floatSuffix  = false;
    boolean decimalSuffix = false;
    long dur = -1;
    if ('d' <= cur && cur <= 's')
    {
      if (cur == 'n' && peek == 's') { consume(); consume(); dur = 1L; }
      if (cur == 'm' && peek == 's') { consume(); consume(); dur = 1000000L; }
      if (cur == 's' && peek == 'e') { consume(); consume(); if (cur != 'c') throw err("Expected 'sec' in Duration literal"); consume(); dur = 1000000000L; }
      if (cur == 'm' && peek == 'i') { consume(); consume(); if (cur != 'n') throw err("Expected 'min' in Duration literal"); consume(); dur = 60000000000L; }
      if (cur == 'h' && peek == 'r') { consume(); consume(); dur = 3600000000000L; }
      if (cur == 'd' && peek == 'a') { consume(); consume(); if (cur != 'y') throw err("Expected 'day' in Duration literal"); consume(); dur = 86400000000000L; }
    }
    if (cur == 'f' || cur == 'F')
    {
      consume();
      floatSuffix = true;
    }
    else if (cur == 'd' || cur == 'D')
    {
      consume();
      decimalSuffix = true;
    }

    if (neg) whole = -whole;

    try
    {
      // float literal
      if (floatSuffix)
      {
        if (s == null)
          this.val = Double.valueOf((double)whole);
        else
          this.val = Double.valueOf(Double.parseDouble(s.toString()));
        return Token.FLOAT_LITERAL;
      }

      // decimal literal (or duration)
      if (decimalSuffix || floating)
      {
        BigDecimal num = (s == null) ?
          new BigDecimal(whole) :
          new BigDecimal(s.toString());
        if (dur > 0)
        {
          this.val = Duration.make(num.multiply(new BigDecimal(dur)).longValue());
          return Token.DURATION_LITERAL;
        }
        else
        {
          this.val = num;
          return Token.DECIMAL_LITERAL;
        }
      }

      // int literal (or duration)
      long num = (s == null) ? whole : new BigDecimal(s.toString()).longValueExact();
      if (dur > 0)
      {
        this.val = Duration.make(num*dur);
        return Token.DURATION_LITERAL;
      }
      else
      {
        this.val = Long.valueOf(num);
        return Token.INT_LITERAL;
      }
    }
    catch (Exception e)
    {
      throw err("Invalid numeric literal: " + s);
    }
  }

  /**
   * Process hex int/long literal starting with 0x
   */
  int hex()
  {
    consume(); // 0
    consume(); // x

    // read first hex
    int type = Token.INT_LITERAL;
    long val = hex(cur);
    if (val < 0) throw err("Expecting hex number");
    consume();
    int nibCount = 1;
    while (true)
    {
      int nib = hex(cur);
      if (nib < 0)
      {
        if (cur == '_') { consume(); continue; }
        break;
      }
      nibCount++;
      if (nibCount > 16) throw err("Hex literal too big");
      val = (val << 4) + nib;
      consume();
    }

    this.val = Long.valueOf(val);
    return type;
  }

  static int hex(int c)
  {
    if ('0' <= c && c <= '9') return c - '0';
    if ('a' <= c && c <= 'f') return c - 'a' + 10;
    if ('A' <= c && c <= 'F') return c - 'A' + 10;
    return -1;
  }

//////////////////////////////////////////////////////////////////////////
// String
//////////////////////////////////////////////////////////////////////////

  /**
   * Parse a string literal token.
   */
  private int str()
  {
    consume();  // opening quote
    StringBuilder s = new StringBuilder();
    loop: while (true)
    {
      switch (cur)
      {
        case '"':   consume(); break loop;
        case -1:    throw err("Unexpected end of string");
        case '$':   throw err("Interpolated strings unsupported");
        case '\\':  s.append(escape()); break;
        case '\r':  s.append('\n'); consume(); break;
        default:    s.append((char)cur); consume(); break;
      }
    }
    this.val = s.toString();
    return Token.STR_LITERAL;
  }

//////////////////////////////////////////////////////////////////////////
// Character
//////////////////////////////////////////////////////////////////////////

  /**
   * Parse a char literal token (as Int literal).
   */
  private int ch()
  {
    // consume opening quote
    consume();

    // if \ then process as escape
    char c;
    if (cur == '\\')
    {
      c = escape();
    }
    else
    {
      c = (char)cur;
      consume();
    }

    // expecting ' quote
    if (cur != '\'') throw err("Expecting ' close of char literal");
    consume();

    this.val = Long.valueOf(c);
    return Token.INT_LITERAL;
  }

  /**
   * Parse an escapse sequence which starts with a \
   */
  char escape()
  {
    // consume slash
    if (cur != '\\') throw err("Internal error");
    consume();

    // check basics
    switch (cur)
    {
      case 'b':   consume(); return '\b';
      case 'f':   consume(); return '\f';
      case 'n':   consume(); return '\n';
      case 'r':   consume(); return '\r';
      case 't':   consume(); return '\t';
      case '$':   consume(); return '$';
      case '"':   consume(); return '"';
      case '\'':  consume(); return '\'';
      case '`':   consume(); return '`';
      case '\\':  consume(); return '\\';
    }

    // check for uxxxx
    if (cur == 'u')
    {
      consume();
      int n3 = hex(cur); consume();
      int n2 = hex(cur); consume();
      int n1 = hex(cur); consume();
      int n0 = hex(cur); consume();
      if (n3 < 0 || n2 < 0 || n1 < 0 || n0 < 0) throw err("Invalid hex value for \\uxxxx");
      return (char)((n3 << 12) | (n2 << 8) | (n1 << 4) | n0);
    }

    throw err("Invalid escape sequence");
  }

//////////////////////////////////////////////////////////////////////////
// Uri
//////////////////////////////////////////////////////////////////////////

  /**
   * Parse a uri literal token.
   */
  private int uri()
  {
    // consume opening tick
    consume();

    // store starting position
    StringBuilder s = new StringBuilder();

    // loop until we find end of string
    while (true)
    {
      if (cur < 0) throw err("Unexpected end of uri");
      if (cur == '\\')
      {
        s.append((char)escape());
      }
      else
      {
        if (cur == '`') { consume(); break; }
        s.append((char)cur);
        consume();
      }
    }

    this.val = Uri.fromStr(s.toString());
    return Token.URI_LITERAL;
  }

//////////////////////////////////////////////////////////////////////////
// Comments
//////////////////////////////////////////////////////////////////////////

  /**
   * Skip a single line // comment
   */
  private Token skipCommentSL()
  {
    consume(); // first slash
    consume(); // next slash
    while (true)
    {
      if (cur == '\n' || cur == '\r') { consume(); break; }
      if (cur < 0) break;
      consume();
    }
    return null;
  }

  /**
   * Skip a multi line /* comment.  Note unlike C/Java,
   * slash/star comments can be nested.
   */
  private Token skipCommentML()
  {
    consume(); // first slash
    consume(); // next slash
    int depth = 1;
    while (true)
    {
      if (cur == '*' && peek == '/') { consume(); consume(); depth--; if (depth <= 0) break; }
      if (cur == '/' && peek == '*') { consume(); consume(); depth++; continue; }
      if (cur < 0) break;
      consume();
    }
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  /**
   * Return a IOErr for current location in source.
   */
  public RuntimeException err(String msg)
  {
    return ObjDecoder.err(msg, line);
  }

////////////////////////////////////////////////////////////////
// Read
////////////////////////////////////////////////////////////////

  /**
   * Consume the cur char and advance to next char in buffer:
   *  - updates cur, curt, peek, and peekt fields
   *  - updates the line and col count
   *  - end of file, sets fields to 0
   */
  private void consume()
  {
    // check for newline
    if (cur == '\n' || cur == '\r') line++;

    // get the next character from the
    // stream; normalize \r\n newlines
    int c = in.rChar();
    if (c == '\n' && peek == '\r') c = in.rChar();

    // roll cur to peek, and peek to new char
    cur   = peek;
    curt  = peekt;
    peek  = c;
    peekt = 0 < c && c < 128 ? charMap[c] : ALPHA;
  }

////////////////////////////////////////////////////////////////
// Char Map
////////////////////////////////////////////////////////////////

  private static final byte[] charMap = new byte[128];
  private static final int SPACE = 1;
  private static final int ALPHA = 2;
  private static final int DIGIT = 3;
  static
  {
    // space characters; note \r is error in symbol()
    charMap[' ']  = SPACE;
    charMap['\n'] = SPACE;
    charMap['\r'] = SPACE;
    charMap['\t'] = SPACE;

    // alpha characters
    for (int i='a'; i<='z'; ++i) charMap[i] = ALPHA;
    for (int i='A'; i<='Z'; ++i) charMap[i] = ALPHA;
    charMap['_'] = ALPHA;

    // digit characters
    for (int i='0'; i<='9'; ++i) charMap[i] = DIGIT;
  }

//////////////////////////////////////////////////////////////////////////
// Undo
//////////////////////////////////////////////////////////////////////////

  /**
   * Pushback a token which will be the next read.
   */
  public void undo(int type, Object val, int line)
  {
    if (undo != null) throw new IllegalStateException("only one pushback supported");
    undo = new Undo(type, val, line);
  }

  /**
   * Reset the current token state.
   */
  public int reset(int type, Object val, int line)
  {
    this.type = type;
    this.val  = val;
    this.line = line;
    return type;
  }

  static class Undo
  {
    Undo(int t, Object v, int l)  { type = t; val = v; line = l; }
    void reset(Tokenizer t) { t.reset(type, val, line); }
    int type;
    Object val;
    int line;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public InStream in;    // input stream
  public int type;       // current Token type constant
  public Object val;     // String for id, Obj for literal
  public int line = 1;   // current line number
  Undo undo;             // if we've pushed back a token
  int cur;               // current char
  int curt;              // current charMap type
  int peek;              // next char
  int peekt;             // next charMap type

}
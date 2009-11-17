//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 07  Andy Frank  Creation
//

using System.Text;
using Fan.Sys;

namespace Fanx.Serial
{
  /// <summary>
  /// Tokenizer inputs a stream of Unicode characters and
  /// outputs tokens for the Fantom serialization grammar.
  /// </summary>
  public class Tokenizer
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Construct for specified input stream.
    /// </summary>
    public Tokenizer(InStream @in)
    {
      m_in = @in;
      consume();
      consume();
    }

  ////////////////////////////////////////////////////////////////
  // Access
  ////////////////////////////////////////////////////////////////

    /// <summary>
    /// Read the next token from the stream.  The token is
    /// available via the 'type' and 'val' fields.  The line
    /// of the current token is available in 'line' field.
    /// Return the 'type' field or -1 if at end of stream.
    /// </summary>
    public int next()
    {
      if (m_undo != null) { m_undo.reset(this); m_undo = null; return m_type; }
      m_val = null;
      return m_type = doNext();
    }

    /// <summary>
    /// Read the next token, set the 'val' field but return
    /// type without worrying setting the 'type' field.
    /// </summary>
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
        throw err("Unexpected symbol: " + (char)cur + " (0x" + System.Convert.ToInt32(cur).ToString("X").ToLower() + ")");

      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Word
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Parse an identifier: alpha (alpha|number)*
    /// </summary>
    private int id()
    {
      StringBuilder s = new StringBuilder();
      int first = cur;
      while ((curt == ALPHA || curt == DIGIT) && cur > 0)
      {
        s.Append((char)cur);
        consume();
      }

      string val = s.ToString();
      switch (first)
      {
        case 'a':
          if (val == "as") { return Token.AS; }
          break;
        case 'f':
          if (val == "false") { m_val = Boolean.False; return Token.BOOL_LITERAL; }
          break;
        case 'n':
          if (val == "null") { m_val = null; return Token.NULL_LITERAL; }
          break;
        case 't':
          if (val == "true") { m_val = Boolean.True; return Token.BOOL_LITERAL; }
          break;
        case 'u':
          if (val == "using") { return Token.USING; }
          break;
      }

      m_val = val;
      return Token.ID;
    }

  //////////////////////////////////////////////////////////////////////////
  // Number
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Parse a number literal token.
    /// </summary>
    private int number(bool neg)
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
          s.Append((char)cur);
        }
        else
        {
          whole = whole*10 + (cur - '0');
          wholeCount++;
          if (wholeCount >= 18) { s = new StringBuilder(32); if (neg) s.Append('-'); s.Append(whole); }
        }
        consume();
        if (cur == '_') consume();
      }

      // fraction part
      bool floating = false;
      if (cur == '.' && peekt == DIGIT)
      {
        floating = true;
        if (s == null) { s = new StringBuilder(32); if (neg) s.Append('-'); s.Append(whole); }
        s.Append('.');
        consume();
        while (curt == DIGIT)
        {
          s.Append((char)cur);
          consume();
          if (cur == '_') consume();
        }
      }

      // exponent
      if (cur == 'e' || cur == 'E')
      {
        floating = true;
        if (s == null) { s = new StringBuilder(32); if (neg) s.Append('-'); s.Append(whole); }
        s.Append('e');
        consume();
        if (cur == '-' || cur == '+') { s.Append((char)cur); consume(); }
        if (curt != DIGIT) throw err("Expected exponent digits");
        while (curt == DIGIT)
        {
          s.Append((char)cur);
          consume();
          if (cur == '_') consume();
        }
      }

      if (neg) whole = -whole;

      // check for suffixes
      bool floatSuffix  = false;
      bool decimalSuffix = false;
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

      try
      {
        // float literal
        if (floatSuffix)
        {
          if (s == null)
            this.m_val = Double.valueOf((double)whole);
          else
            this.m_val = Double.valueOf(s.ToString());
          return Token.FLOAT_LITERAL;
        }

        // decimal literal (or duration)
        if (decimalSuffix || floating)
        {
          BigDecimal dnum = (s == null) ?
            BigDecimal.valueOf(whole) :
            BigDecimal.valueOf(s.ToString());
          if (dur > 0)
          {
            this.m_val = Duration.make(dnum.multiply(BigDecimal.valueOf(dur)).longValue());
            return Token.DURATION_LITERAL;
          }
          else
          {
            this.m_val = dnum;
            return Token.DECIMAL_LITERAL;
          }
        }

        // int literal (or duration)
        long num = (s == null) ? whole : BigDecimal.valueOf(s.ToString()).longValue();
        if (dur > 0)
        {
          this.m_val = Duration.make(num*dur);
          return Token.DURATION_LITERAL;
        }
        else
        {
          this.m_val = Long.valueOf(num);
          return Token.INT_LITERAL;
        }
      }
      catch (System.Exception)
      {
        throw err("Invalid numeric literal: " + s);
      }
    }

    /// <summary>
    /// Process hex int/long literal starting with 0x
    /// </summary>
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

      m_val = Long.valueOf(val);
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

    /// <summary>
    /// Parse a string literal token.
    /// </summary>
    private int str()
    {
      consume();  // opening quote
      StringBuilder s = new StringBuilder();
      bool loop = true;
      while (loop)
      {
        switch (cur)
        {
          case '"':   consume(); loop = false; break;
          case -1:    throw err("Unexpected end of string");
          case '$':   throw err("Interpolated strings unsupported");
          case '\\':  s.Append(escape()); break;
          case '\r':  s.Append('\n'); consume(); break;
          default:    s.Append((char)cur); consume(); break;
        }
      }
      m_val = s.ToString();
      return Token.STR_LITERAL;
    }

  //////////////////////////////////////////////////////////////////////////
  // Character
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Parse a char literal token (as Long literal).
    /// </summary>
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

      m_val = Long.valueOf(c);
      return Token.INT_LITERAL;
    }

    /// <summary>
    /// Parse an escapse sequence which starts with a \
    /// </summary>
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

    /// <summary>
    /// Parse a uri literal token.
    /// </summary>
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
          s.Append((char)escape());
        }
        else
        {
          if (cur == '`') { consume(); break; }
          s.Append((char)cur);
          consume();
        }
      }

      m_val = Uri.fromStr(s.ToString());
      return Token.URI_LITERAL;
    }

  //////////////////////////////////////////////////////////////////////////
  // Comments
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Skip a single line // comment
    /// </summary>
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

    /// <summary>
    /// Skip a multi line /* comment.  Note unlike C/Java,
    /// slash/star comments can be nested.
    /// </summary>
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
    public System.Exception err(string msg)
    {
      return ObjDecoder.err(msg, m_line);
    }

  ////////////////////////////////////////////////////////////////
  // Read
  ////////////////////////////////////////////////////////////////

    /// <summary>
    /// Consume the cur char and advance to next char in buffer:
    ///  - updates cur, curt, peek, and peekt fields
    ///  - updates the line and col count
    ///  - end of file, sets fields to 0
    /// <summary>
    private void consume()
    {
      // check for newline
      if (cur == '\n' || cur == '\r') m_line++;

      // get the next character from the
      // stream; normalize \r\n newlines
      int c = m_in.rChar();
      if (c == '\n' && peek == '\r') c = m_in.rChar();

      // roll cur to peek, and peek to new char
      cur   = peek;
      curt  = peekt;
      peek  = c;
      peekt = 0 < c && c < 128 ? (int)charMap[c] : ALPHA;
    }

  ////////////////////////////////////////////////////////////////
  // Char Map
  ////////////////////////////////////////////////////////////////

    private static readonly byte[] charMap = new byte[128];
    private const int SPACE = 1;
    private const int ALPHA = 2;
    private const int DIGIT = 3;
    static Tokenizer()
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

    /// <summary>
    /// Pushback a token which will be the next read.
    /// </summary>
    public void undo(int type, object val, int line)
    {
      if (m_undo != null) throw new System.InvalidOperationException("only one pushback supported");
      m_undo = new Undo(type, val, line);
    }

    /// <summary>
    /// Reset the current token state.
    /// </summary>
    public int reset(int type, object val, int line)
    {
      this.m_type = type;
      this.m_val  = val;
      this.m_line = line;
      return m_type;
    }

    internal class Undo
    {
      internal Undo(int t, object v, int l)  { type = t; val = v; line = l; }
      internal void reset(Tokenizer t) { t.reset(type, val, line); }
      internal int type;
      internal object val;
      internal int line;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public InStream m_in;    // input stream
    public int m_type;       // current Token type constant
    public object m_val;     // String for id, Obj for literal
    public int m_line = 1;   // current line number
    Undo m_undo;             // if we've pushed back a token
    int cur;                 // current char
    int curt;                // current charMap type
    int peek;                // next char
    int peekt;               // next charMap type
  }
}
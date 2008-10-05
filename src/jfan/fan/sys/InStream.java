//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Mar 06  Brian Frank  Creation
//
package fan.sys;

import fanx.serial.*;

/**
 * InStream interface.
 */
public class InStream
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static InStream makeForStr(Str s)
  {
    return new StrInStream(s);
  }

  public static InStream makeForStr(String s)
  {
    return new StrInStream(s);
  }

  public static InStream make(InStream in)
  {
    InStream self = new InStream();
    make$(self, in);
    return self;
  }

  public static void make$(InStream self, InStream in)
  {
    self.in = in;
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.InStreamType; }

//////////////////////////////////////////////////////////////////////////
// Java InputStream
//////////////////////////////////////////////////////////////////////////

  /**
   * Read a byte using a Java primitive int.  Most
   * reads route to this method for efficient mapping to
   * a java.io.InputStream.  If we aren't overriding this
   * method, then route back to read() for the subclass
   * to handle.
   */
  public int r()
  {
    Int n = read();
    if (n == null) return -1;
    return (int)n.val;
  }

  /**
   * Unread a byte using a Java primitive int.  If we aren't
   * overriding this method, then route back to read() for the
   * subclass to handle.
   */
  public InStream unread(int b)
  {
    return unread(Int.make(b));
  }

  /**
   * Read char as primitive int.
   */
  public int rChar()
  {
    return charsetDecoder.decode(this);
  }

  /**
   * Unread char as primitive int.
   */
  public InStream unreadChar(int b)
  {
    return unreadChar(Int.make(b));
  }

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

  public Int read()
  {
    try
    {
      return in.read();
    }
    catch (NullPointerException e)
    {
      if (in == null)
        throw UnsupportedErr.make(type().qname() + " wraps null InStream").val;
      else
        throw e;
    }
  }

  public Int readBuf(Buf buf, Int n)
  {
    try
    {
      return in.readBuf(buf, n);
    }
    catch (NullPointerException e)
    {
      if (in == null)
        throw UnsupportedErr.make(type().qname() + " wraps null InStream").val;
      else
        throw e;
    }
  }

  public InStream unread(Int n)
  {
    try
    {
      in.unread(n);
      return this;
    }
    catch (NullPointerException e)
    {
      if (in == null)
        throw UnsupportedErr.make(type().qname() + " wraps null InStream").val;
      else
        throw e;
    }
  }

  public Int skip(Int n)
  {
    if (in != null) return in.skip(n);

    long nval = n.val;
    for (int i=0; i<nval; ++i)
      if (r() < 0) return Int.pos(i);
    return n;
  }

  public Buf readAllBuf()
  {
    try
    {
      Int size = Int.Chunk;
      Buf buf = Buf.make(size);
      while (readBuf(buf, size) != null);
      buf.flip();
      return buf;
    }
    finally
    {
      try { close(); } catch (Exception e) { e.printStackTrace(); }
    }
  }

  public Buf readBufFully(Buf buf, Int n)
  {
    if (buf == null) buf = Buf.make(n);

    long total = n.val;
    long got = 0;
    while (got < total)
    {
      Int r = readBuf(buf, Int.make(total-got));
      if (r == null || r.val == 0) throw IOErr.make("Unexpected end of stream").val;
      got += r.val;
    }

    buf.flip();
    return buf;
  }

  public Int peek()
  {
    Int x = read();
    if (x != null) unread(x);
    return x;
  }

  public Int readU1()
  {
    int c = r();
    if (c < 0) throw IOErr.make("Unexpected end of stream").val;
    return Int.make(c);
  }

  public Int readS1()
  {
    int c = r();
    if (c < 0) throw IOErr.make("Unexpected end of stream").val;
    return Int.make((byte)c);
  }

  public Int readU2()
  {
    int c1 = r();
    int c2 = r();
    if ((c1 | c2) < 0) throw IOErr.make("Unexpected end of stream").val;
    return Int.make(c1 << 8 | c2);
  }

  public Int readS2()
  {
    int c1 = r();
    int c2 = r();
    if ((c1 | c2) < 0) throw IOErr.make("Unexpected end of stream").val;
    return Int.make((short)(c1 << 8 | c2));
  }

  public Int readU4()
  {
    long c1 = r();
    long c2 = r();
    long c3 = r();
    long c4 = r();
    if ((c1 | c2 | c3 | c4) < 0) throw IOErr.make("Unexpected end of stream").val;
    return Int.make((c1 << 24) + (c2 << 16) + (c3 << 8) + c4);
  }

  public Int readS4() { return Int.make(readInt()); }
  public int readInt()
  {
    int c1 = r();
    int c2 = r();
    int c3 = r();
    int c4 = r();
    if ((c1 | c2 | c3 | c4) < 0) throw IOErr.make("Unexpected end of stream").val;
    return ((c1 << 24) + (c2 << 16) + (c3 << 8) + c4);
  }

  public Int readS8() { return Int.make(readLong()); }
  public long readLong()
  {
    long c1 = r();
    long c2 = r();
    long c3 = r();
    long c4 = r();
    long c5 = r();
    long c6 = r();
    long c7 = r();
    long c8 = r();
    if ((c1 | c2 | c3 | c4 | c5 | c6 | c7 | c8) < 0) throw IOErr.make("Unexpected end of stream").val;
    return ((c1 << 56) + (c2 << 48) + (c3 << 40) + (c4 << 32) +
            (c5 << 24) + (c6 << 16) + (c7 << 8) + c8);
  }

  public Double readF4()
  {
    return Double.valueOf(Float.intBitsToFloat(readInt()));
  }

  public Double readF8()
  {
    return Double.valueOf(Double.longBitsToDouble(readLong()));
  }

  public Decimal readDecimal()
  {
    return Decimal.fromStr(readUtfString(), true);
  }

  public Bool readBool()
  {
    int n = r();
    if (n < 0) throw IOErr.make("Unexpected end of stream").val;
    return n == 0 ? Bool.False : Bool.True;
  }

  public Str readUtf() { return Str.make(readUtfString()); }
  private String readUtfString()
  {
    // read two-byte length
    int len1 = r();
    int len2 = r();
    if ((len1 | len2) < 0) throw IOErr.make("Unexpected end of stream").val;
    int utflen = len1 << 8 | len2;

    char[] buf = new char[utflen]; // char buffer we read into
    int bnum = 0, cnum = 0;        // byte count, char count

    // read the chars
    int c, c2, c3;
    while (bnum < utflen)
    {
      c = r(); bnum++;
      if (c < 0) throw IOErr.make("Unexpected end of stream").val;
      switch (c >> 4) {
        case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
          /* 0xxxxxxx*/
          buf[cnum++]=(char)c;
          break;
        case 12: case 13:
          /* 110x xxxx   10xx xxxx*/
          if (bnum >= utflen) throw IOErr.make("UTF encoding error").val;
          c2 = r(); bnum++;
          if (c2 < 0) throw IOErr.make("Unexpected end of stream").val;
          if ((c2 & 0xC0) != 0x80) throw IOErr.make("UTF encoding error").val;
          buf[cnum++]=(char)(((c & 0x1F) << 6) | (c2 & 0x3F));
          break;
        case 14:
          /* 1110 xxxx  10xx xxxx  10xx xxxx */
          if (bnum+1 >= utflen) throw IOErr.make("UTF encoding error").val;
          c2 = r(); bnum++;
          c3 = r(); bnum++;
          if ((c2|c3) < 0) throw IOErr.make("Unexpected end of stream").val;
          if (((c2 & 0xC0) != 0x80) || ((c3 & 0xC0) != 0x80))  throw IOErr.make("UTF encoding error").val;
          buf[cnum++]=(char)(((c & 0x0F) << 12) | ((c2 & 0x3F) << 6) | ((c3 & 0x3F) << 0));
          break;
        default:
          /* 10xx xxxx,  1111 xxxx */
          throw IOErr.make("UTF encoding error").val;
      }
    }

    // allocate as Str
    return new String(buf, 0, cnum);
  }

  public Charset charset()
  {
    return charset;
  }

  public void charset(Charset charset)
  {
    this.charsetDecoder = charset.newDecoder();
    this.charsetEncoder = charset.newEncoder();
    this.charset = charset;
  }

  public Int readChar()
  {
    int ch = charsetDecoder.decode(this);
    return ch < 0 ? null : Int.pos(ch);
  }

  public InStream unreadChar(Int c)
  {
    charsetEncoder.encode((char)c.val, this);
    return this;
  }

  public Int peekChar()
  {
    Int x = readChar();
    if (x != null) unreadChar(x);
    return x;
  }

  public Str readLine() { return readLine(Int.Chunk); }
  public Str readLine(Int max)
  {
    // max limit
    int maxChars = (max != null) ? (int)max.val : Integer.MAX_VALUE;
    if (maxChars <= 0) return Str.Empty;

    // read first char, if at end of file bail
    int c = rChar();
    if (c < 0) return null;

    // loop reading chars until we hit newline
    // combo or end of stream
    StringBuilder buf = new StringBuilder(256);
    while (true)
    {
      // check for \n, \r\n, or \r
      if (c == '\n') break;
      if (c == '\r')
      {
        c = rChar();
        if (c >= 0 && c != '\n') unreadChar(c);
        break;
      }

      // append to working buffer
      buf.append((char)c);
      if (buf.length() >= maxChars) break;

      // read next char
      c = rChar();
      if (c < 0) break;
    }
    return Str.make(buf.toString());
  }

  public Str readStrToken() { return readStrToken(Int.Chunk, null); }
  public Str readStrToken(Int max) { return readStrToken(max, null); }
  public Str readStrToken(Int max, Func f)
  {
    // max limit
    int maxChars = (max != null) ? (int)max.val : Integer.MAX_VALUE;
    if (maxChars <= 0) return Str.Empty;

    // read first char, if at end of file bail
    int c = rChar();
    if (c < 0) return null;

    // loop reading chars until our closure returns false
    StringBuilder buf = new StringBuilder();
    while (true)
    {
      // check for \n, \r\n, or \r
      boolean terminate;
      if (f == null)
        terminate = Int.isSpace(c);
      else
        terminate = ((Bool)f.call1(Int.pos(c))).val;
      if (terminate)
      {
        unreadChar(c);
        break;
      }

      // append to working buffer
      buf.append((char)c);
      if (buf.length() >= maxChars) break;

      // read next char
      c = rChar();
      if (c < 0) break;
    }
    return Str.make(buf.toString());
  }

  public List readAllLines()
  {
    try
    {
      List list = new List(Sys.StrType);
      Str line;
      while ((line = readLine()) != null)
        list.add(line);
      return list;
    }
    finally
    {
      try { close(); } catch (Exception e) { e.printStackTrace(); }
    }
  }

  public void eachLine(Func f)
  {
    try
    {
      Str line;
      while ((line = readLine()) != null)
        f.call1(line);
    }
    finally
    {
      try { close(); } catch (Exception e) { e.printStackTrace(); }
    }
  }

  public Str readAllStr() { return readAllStr(Bool.True); }
  public Str readAllStr(Bool normalizeNewlines)
  {
    try
    {
      char[] buf  = new char[4096];
      int n = 0;
      boolean normalize = normalizeNewlines.val;

      // read characters
      int last = -1;
      while (true)
      {
        int c = rChar();
        if (c < 0) break;

        // grow buffer if needed
        if (n >= buf.length)
        {
          char[] temp = new char[buf.length*2];
          System.arraycopy(buf, 0, temp, 0, n);
          buf = temp;
        }

        // normalize newlines and add to buffer
        if (normalize)
        {
          if (c == '\r') buf[n++] = '\n';
          else if (last == '\r' && c == '\n') {}
          else buf[n++] = (char)c;
          last = c;
        }
        else
        {
          buf[n++] = (char)c;
        }
      }

      return Str.make(new String(buf, 0, n));
    }
    finally
    {
      try { close(); } catch (Exception e) { e.printStackTrace(); }
    }
  }

  public Object readObj() { return readObj(null); }
  public Object readObj(Map options)
  {
    return new ObjDecoder(this, options).readObj();
  }

  public Map readProps()
  {
    Charset origCharset = charset();
    charset(Charset.utf8());
    try
    {
      Map props = new Map(Sys.StrType, Sys.StrType);

      StringBuilder name = new StringBuilder();
      StringBuilder val = null;
      int inBlockComment = 0;
      boolean inEndOfLineComment = false;
      int c =  ' ', last = ' ';
      int lineNum = 1;

      while (true)
      {
        last = c;
        c = rChar();
        if (c < 0) break;

        // end of line
        if (c == '\n' || c == '\r')
        {
          inEndOfLineComment = false;
          if (last == '\r' && c == '\n') continue;
          Str n = Str.makeTrim(name);
          if (val != null)
          {
            props.add(n, Str.makeTrim(val));
            name = new StringBuilder();
            val = null;
          }
          else if (n.val.length() > 0)
            throw IOErr.make("Invalid name/value pair [Line " + lineNum + "]").val;
          lineNum++;
          continue;
        }

        // if in comment
        if (inEndOfLineComment) continue;

        // block comment
        if (inBlockComment > 0)
        {
          if (last == '/' && c == '*') inBlockComment++;
          if (last == '*' && c == '/') inBlockComment--;
          continue;
        }

        // equal
        if (c == '=' && val == null)
        {
          val = new StringBuilder();
          continue;
        }

        // comment
        if (c == '/' && Int.isSpace(last))
        {
          int peek = rChar();
          if (peek < 0) break;
          if (peek == '/') { inEndOfLineComment = true; continue; }
          if (peek == '*') { inBlockComment++; continue; }
          unreadChar(peek);
        }

        // escape or line continuation
        if (c == '\\')
        {
          int peek = rChar();
          if (peek < 0) break;
          else if (peek == 'n')  c = '\n';
          else if (peek == 'r')  c = '\r';
          else if (peek == 't')  c = '\t';
          else if (peek == '\\') c = '\\';
          else if (peek == '\r' || peek == '\n')
          {
            // line continuation
            lineNum++;
            if (peek == '\r')
            {
              peek = rChar();
              if (peek != '\n') unreadChar(peek);
            }
            while (true)
            {
              peek = rChar();
              if (peek == ' ' || peek == '\t') continue;
              unreadChar(peek);
              break;
            }
            continue;
          }
          else if (peek == 'u')
          {
            int n3 = hex(rChar());
            int n2 = hex(rChar());
            int n1 = hex(rChar());
            int n0 = hex(rChar());
            if (n3 < 0 || n2 < 0 || n1 < 0 || n0 < 0) throw IOErr.make("Invalid hex value for \\uxxxx [Line " +  lineNum + "]").val;
            c = ((n3 << 12) | (n2 << 8) | (n1 << 4) | n0);
          }
          else throw IOErr.make("Invalid escape sequence [Line " + lineNum + "]").val;
        }

        // normal character
        if (val == null)
          name.append((char)c);
        else
          val.append((char)c);
      }

      Str n = Str.makeTrim(name);
      if (val != null)
        props.add(n, Str.makeTrim(val));
      else if (n.val.length() > 0)
        throw IOErr.make("Invalid name/value pair [Line " + lineNum + "]").val;

      return props;
    }
    finally
    {
      try { close(); } catch (Exception e) { e.printStackTrace(); }
      charset(origCharset);
    }
  }

  static int hex(int c)
  {
    if ('0' <= c && c <= '9') return c - '0';
    if ('a' <= c && c <= 'f') return c - 'a' + 10;
    if ('A' <= c && c <= 'F') return c - 'A' + 10;
    return -1;
  }

  public Int pipe(OutStream out) { return pipe(out, null, Bool.True); }
  public Int pipe(OutStream out, Int n) { return pipe(out, n, Bool.True); }
  public Int pipe(OutStream out, Int toPipe, Bool close)
  {
    try
    {
      Int bufSize = Int.Chunk;
      Buf buf = Buf.make(bufSize);
      long total = 0;
      if (toPipe == null)
      {
        while (true)
        {
          Int n = readBuf(buf.clear(), bufSize);
          if (n == null) break;
          out.writeBuf(buf.flip(), buf.remaining());
          total += n.val;
        }
      }
      else
      {
        long toPipeVal = toPipe.val;
        while (total < toPipeVal)
        {
          if (toPipeVal - total < bufSize.val) bufSize = Int.make(toPipeVal - total);
          Int n = readBuf(buf.clear(), bufSize);
          if (n == null) throw IOErr.make("Unexpected end of stream").val;
          out.writeBuf(buf.flip(), buf.remaining());
          total += n.val;
        }
      }
      return Int.make(total);
    }
    finally
    {
      if (close.val) close();
    }
  }

  public Bool close()
  {
    if (in != null) return in.close();
    return Bool.True;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  InStream in;
  Charset charset = Charset.utf8();
  Charset.Decoder charsetDecoder = charset.newDecoder();
  Charset.Encoder charsetEncoder = charset.newEncoder();

}
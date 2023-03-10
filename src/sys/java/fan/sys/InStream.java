//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Mar 06  Brian Frank  Creation
//
package fan.sys;

import java.math.*;
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

  public static InStream make(InStream in)
  {
    InStream self = new InStream();
    make$(self, in);
    return self;
  }

  public static void make$(InStream self, InStream in)
  {
    self.in = in;
    if (in != null)
    {
      self.inChar = in.toCharInStream();
      self.charset(in.charset());
    }
  }

  /**
   * If this input stream is optimized to read chars, then return
   * this.  Otherwise return null so that wrapped InStreams always
   * do charset decoding themselves from the raw bytes.
   */
  protected InStream toCharInStream()
  {
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.InStreamType; }

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
    Long n = read();
    if (n == null) return -1;
    return n.intValue();
  }

  /**
   * Unread a byte using a Java primitive int.  If we aren't
   * overriding this method, then route back to read() for the
   * subclass to handle.
   */
  public InStream unread(int b)
  {
    return unread((long)b);
  }

  /**
   * Read char as primitive int.
   */
  public int rChar()
  {
    if (inChar != null)
      return inChar.rChar();
    else
      return charsetDecoder.decode(this);
  }

  /**
   * Unread char as primitive int.
   */
  public InStream unreadChar(int b)
  {
    return unreadChar((long)b);
  }

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

  public long avail()
  {
    try
    {
      return in.avail();
    }
    catch (NullPointerException e)
    {
      if (in == null)
        throw UnsupportedErr.make(getClass().getName() + " wraps null InStream");
      else
        throw e;
    }
  }

  public Long read()
  {
    try
    {
      return in.read();
    }
    catch (NullPointerException e)
    {
      if (in == null)
        throw UnsupportedErr.make(getClass().getName() + " wraps null InStream");
      else
        throw e;
    }
  }

  public Long readBuf(Buf buf, long n)
  {
    try
    {
      return in.readBuf(buf, n);
    }
    catch (NullPointerException e)
    {
      if (in == null)
        throw UnsupportedErr.make(getClass().getName() + " wraps null InStream");
      else
        throw e;
    }
  }

  public InStream unread(long n)
  {
    try
    {
      in.unread(n);
      return this;
    }
    catch (NullPointerException e)
    {
      if (in == null)
        throw UnsupportedErr.make(getClass().getName() + " wraps null InStream");
      else
        throw e;
    }
  }

  public long skip(long n)
  {
    if (in != null) return in.skip(n);

    long nval = n;
    for (int i=0; i<nval; ++i)
      if (r() < 0) return i;
    return n;
  }

  public Buf readAllBuf()
  {
    try
    {
      long size = FanInt.Chunk;
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

  public Buf readBufFully(Buf buf, long n)
  {
    if (buf == null) buf = Buf.make(n);

    long total = n;
    long got = 0;
    while (got < total)
    {
      Long r = readBuf(buf, total-got);
      if (r == null || r.longValue() == 0) throw IOErr.make("Unexpected end of stream");
      got += r.longValue();
    }

    buf.flip();
    return buf;
  }

  public Endian endian()
  {
    return bigEndian ? Endian.big : Endian.little;
  }

  public void endian(Endian endian)
  {
    bigEndian = endian == Endian.big;
  }

  public Long peek()
  {
    Long x = read();
    if (x != null) unread(x);
    return x;
  }

  public long readU1()
  {
    int c = r();
    if (c < 0) throw IOErr.make("Unexpected end of stream");
    return c;
  }

  public long readS1()
  {
    int c = r();
    if (c < 0) throw IOErr.make("Unexpected end of stream");
    return (byte)c;
  }

  public long readU2()
  {
    int c1 = r();
    int c2 = r();
    if ((c1 | c2) < 0) throw IOErr.make("Unexpected end of stream");
    if (bigEndian)
      return c1 << 8 | c2;
    else
      return c2 << 8 | c1;
  }

  public long readS2()
  {
    int c1 = r();
    int c2 = r();
    if ((c1 | c2) < 0) throw IOErr.make("Unexpected end of stream");
    if (bigEndian)
      return (short)(c1 << 8 | c2);
    else
      return (short)(c2 << 8 | c1);
  }

  public long readU4()
  {
    long c1 = r();
    long c2 = r();
    long c3 = r();
    long c4 = r();
    if ((c1 | c2 | c3 | c4) < 0) throw IOErr.make("Unexpected end of stream");
    if (bigEndian)
      return (c1 << 24) + (c2 << 16) + (c3 << 8) + c4;
    else
      return (c4 << 24) + (c3 << 16) + (c2 << 8) + c1;
  }

  public long readS4()
  {
    int c1 = r();
    int c2 = r();
    int c3 = r();
    int c4 = r();
    if ((c1 | c2 | c3 | c4) < 0) throw IOErr.make("Unexpected end of stream");
    if (bigEndian)
      return ((c1 << 24) + (c2 << 16) + (c3 << 8) + c4);
    else
      return ((c4 << 24) + (c3 << 16) + (c2 << 8) + c1);
  }

  public long readS8()
  {
    long c1 = r();
    long c2 = r();
    long c3 = r();
    long c4 = r();
    long c5 = r();
    long c6 = r();
    long c7 = r();
    long c8 = r();
    if ((c1 | c2 | c3 | c4 | c5 | c6 | c7 | c8) < 0) throw IOErr.make("Unexpected end of stream");
    if (bigEndian)
      return ((c1 << 56) + (c2 << 48) + (c3 << 40) + (c4 << 32) +
              (c5 << 24) + (c6 << 16) + (c7 << 8) + c8);
    else
      return ((c8 << 56) + (c7 << 48) + (c6 << 40) + (c5 << 32) +
              (c4 << 24) + (c3 << 16) + (c2 << 8) + c1);  }

  public double readF4()
  {
    return Float.intBitsToFloat((int)readS4());
  }

  public double readF8()
  {
    return Double.longBitsToDouble(readS8());
  }

  public BigDecimal readDecimal()
  {
    return FanDecimal.fromStr(readUtf(), true);
  }

  public boolean readBool()
  {
    int n = r();
    if (n < 0) throw IOErr.make("Unexpected end of stream");
    return n != 0;
  }

  public String readUtf()
  {
    // read two-byte length
    int len1 = r();
    int len2 = r();
    if ((len1 | len2) < 0) throw IOErr.make("Unexpected end of stream");
    int utflen = len1 << 8 | len2;

    char[] buf = new char[utflen]; // char buffer we read into
    int bnum = 0, cnum = 0;        // byte count, char count

    // read the chars
    int c, c2, c3;
    while (bnum < utflen)
    {
      c = r(); bnum++;
      if (c < 0) throw IOErr.make("Unexpected end of stream");
      switch (c >> 4) {
        case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
          /* 0xxxxxxx*/
          buf[cnum++]=(char)c;
          break;
        case 12: case 13:
          /* 110x xxxx   10xx xxxx*/
          if (bnum >= utflen) throw IOErr.make("UTF encoding error");
          c2 = r(); bnum++;
          if (c2 < 0) throw IOErr.make("Unexpected end of stream");
          if ((c2 & 0xC0) != 0x80) throw IOErr.make("UTF encoding error");
          buf[cnum++]=(char)(((c & 0x1F) << 6) | (c2 & 0x3F));
          break;
        case 14:
          /* 1110 xxxx  10xx xxxx  10xx xxxx */
          if (bnum+1 >= utflen) throw IOErr.make("UTF encoding error");
          c2 = r(); bnum++;
          c3 = r(); bnum++;
          if ((c2|c3) < 0) throw IOErr.make("Unexpected end of stream");
          if (((c2 & 0xC0) != 0x80) || ((c3 & 0xC0) != 0x80))  throw IOErr.make("UTF encoding error");
          buf[cnum++]=(char)(((c & 0x0F) << 12) | ((c2 & 0x3F) << 6) | ((c3 & 0x3F) << 0));
          break;
        default:
          /* 10xx xxxx,  1111 xxxx */
          throw IOErr.make("UTF encoding error");
      }
    }

    // allocate as Str
    return new String(buf, 0, cnum);
  }

  public long readBits(long num)
  {
    // arg checking
    if (num == 0) return 0;
    if (num < 0 || num > 64) throw ArgErr.make("Bit num not 0 - 64: " + num);

    // buffer is stored in two bytes: <size> <byte>
    int bitsBuf = this.bitsBuf;
    int bufByte = bitsBuf & 0xff;
    int bufSize = (bitsBuf >> 8) & 0xff;

    // read bits, sourcing a new byte once we run out bits
    // in current byte buffer
    long result = 0;
    for (int i=(int)num-1; i>=0; --i)
    {
      if (bufSize == 0)
      {
        bufByte = r();
        if (bufByte < 0) throw IOErr.make("End of stream");
        bufSize = 8;
      }
      int bit = (bufByte >> (bufSize - 1)) & 0x1;
      bufSize--;
      result = result << 1 | (long)bit;
    }

    // update buffer and return result
    this.bitsBuf = (bufSize << 8) | bufByte;
    return result;
  }

  public long numPendingBits()
  {
    return (bitsBuf >> 8) & 0xff;
  }

  public Charset charset()
  {
    return charset;
  }

  public void charset(Charset charset)
  {
    if (this.charset == charset) return;
    this.charsetDecoder = charset.newDecoder();
    this.charsetEncoder = charset.newEncoder();
    this.charset = charset;
  }

  public Long readChar()
  {
    if (in != null) return in.readChar();
    int ch = charsetDecoder.decode(this);
    return ch < 0 ? null : Long.valueOf(ch);
  }

  public InStream unreadChar(long c)
  {
    if (in != null)
      in.unreadChar(c);
    else
      charsetEncoder.encode((char)c, this);
    return this;
  }

  public Long peekChar()
  {
    Long x = readChar();
    if (x != null) unreadChar(x);
    return x;
  }

  public String readChars(long n)
  {
    if (n < 0) throw ArgErr.make("readChars n < 0: " + n);
    if (n == 0) return "";
    StringBuilder buf = new StringBuilder(256);
    for (int i=(int)n; i>0; --i)
    {
      int ch = rChar();
      if (ch < 0) throw IOErr.make("Unexpected end of stream");
      buf.append((char)ch);
    }
    return buf.toString();
  }

  public String readLine() { return readLine(null); }
  public String readLine(Long max)
  {
    // max limit
    int maxChars = Integer.MAX_VALUE;
    if (max != null)
    {
      long maxLong = max.longValue();
      if (maxLong == 0L) return "";
      if (maxLong < 0L) throw ArgErr.make("Invalid max: " + max);
      if (maxLong < Integer.MAX_VALUE)
        maxChars = (int)maxLong;
    }

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
    return buf.toString();
  }

  public String readStrToken() { return readStrToken(null, null); }
  public String readStrToken(Long max) { return readStrToken(max, null); }
  public String readStrToken(Long max, Func f)
  {
    // max limit
    int maxChars = (max != null) ? max.intValue() : Integer.MAX_VALUE;
    if (maxChars <= 0) return "";

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
        terminate = FanInt.isSpace(c);
      else
        terminate = (Boolean)f.call(Long.valueOf(c));
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
    return buf.toString();
  }

  public String readNullTerminatedStr() { return readNullTerminatedStr(null); }
  public String readNullTerminatedStr(Long max)
  {
    // max limit
    int maxChars = (max != null) ? max.intValue() : Integer.MAX_VALUE;
    if (maxChars <= 0) return "";

    // read first char, if at end of file bail
    int c = rChar();
    if (c < 0) return null;

    // loop reading chars until we hit '\0' or max chars
    StringBuilder buf = new StringBuilder();
    while (true)
    {
      if (c == '\0') break;

      // append to working buffer
      buf.append((char)c);
      if (buf.length() >= maxChars) break;

      // read next char
      c = rChar();
      if (c < 0) break;
    }
    return buf.toString();
  }

  public List readAllLines()
  {
    try
    {
      List list = new List(Sys.StrType);
      String line;
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
      String line;
      while ((line = readLine()) != null)
        f.call(line);
    }
    finally
    {
      try { close(); } catch (Exception e) { e.printStackTrace(); }
    }
  }

  public String readAllStr() { return readAllStr(true); }
  public String readAllStr(boolean normalizeNewlines)
  {
    try
    {
      char[] buf  = new char[4096];
      int n = 0;
      boolean normalize = normalizeNewlines;

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

      return new String(buf, 0, n);
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

  public Map readProps() { return readProps(false); }
  public Map readPropsListVals() { return readProps(true); }

  private Map readProps(boolean listVals)  // listVals is Str:Str[]
  {
    Charset origCharset = charset();
    charset(Charset.utf8());
    try
    {
      Map props = new Map(Sys.StrType, listVals ? Sys.StrType.toListOf() : Sys.StrType);
      props.ordered(true);

      StringBuilder name = new StringBuilder();
      StringBuilder val = null;
      int inBlockComment = 0;
      boolean inEndOfLineComment = false;
      int c =  ' ', last = ' ';
      int lineNum = 1;
      int colNum = 0;

      while (true)
      {
        last = c;
        c = rChar();
        ++colNum;
        if (c < 0) break;

        // end of line
        if (c == '\n' || c == '\r')
        {
          colNum = 0;
          inEndOfLineComment = false;
          if (last == '\r' && c == '\n') continue;
          String n = FanStr.makeTrim(name);
          if (val != null)
          {
            addProp(props, n, FanStr.makeTrim(val), listVals);
            name = new StringBuilder();
            val = null;
          }
          else if (n.length() > 0)
            throw IOErr.make("Invalid name/value pair [Line " + lineNum + "]");
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

        // line comment
        if (c == '#' && colNum == 1)
        {
          inEndOfLineComment = true;
          continue;
        }

        // end of line comment
        if (c == '/' && FanInt.isSpace(last))
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
            if (n3 < 0 || n2 < 0 || n1 < 0 || n0 < 0) throw IOErr.make("Invalid hex value for \\uxxxx [Line " +  lineNum + "]");
            c = ((n3 << 12) | (n2 << 8) | (n1 << 4) | n0);
          }
          else throw IOErr.make("Invalid escape sequence [Line " + lineNum + "]");
        }

        // normal character
        if (val == null)
          name.append((char)c);
        else
          val.append((char)c);
      }

      String n = FanStr.makeTrim(name);
      if (val != null)
        addProp(props, n, FanStr.makeTrim(val), listVals);
      else if (n.length() > 0)
        throw IOErr.make("Invalid name/value pair [Line " + lineNum + "]");

      return props;
    }
    finally
    {
      try { close(); } catch (Exception e) { e.printStackTrace(); }
      charset(origCharset);
    }
  }

  static void addProp(Map props, String n, String v, boolean listVals)
  {
    if (listVals)
    {
      List list =(List)props.get(n);
      if (list == null) props.add(n, list = new List(Sys.StrType));
      list.add(v);
    }
    else
    {
      props.add(n, v);
    }
  }

  static int hex(int c)
  {
    if ('0' <= c && c <= '9') return c - '0';
    if ('a' <= c && c <= 'f') return c - 'a' + 10;
    if ('A' <= c && c <= 'F') return c - 'A' + 10;
    return -1;
  }

  public long pipe(OutStream out) { return pipe(out, null, true); }
  public long pipe(OutStream out, Long n) { return pipe(out, n, true); }
  public long pipe(OutStream out, Long toPipe, boolean close)
  {
    try
    {
      long bufSize = FanInt.Chunk;
      Buf buf = Buf.make(bufSize);
      long total = 0;
      if (toPipe == null)
      {
        while (true)
        {
          Long n = readBuf(buf.clear(), bufSize);
          if (n == null) break;
          out.writeBuf(buf.flip(), buf.remaining());
          total += n;
        }
      }
      else
      {
        long toPipeVal = toPipe;
        while (total < toPipeVal)
        {
          if (toPipeVal - total < bufSize) bufSize = toPipeVal - total;
          Long n = readBuf(buf.clear(), bufSize);
          if (n == null) throw IOErr.make("Unexpected end of stream");
          out.writeBuf(buf.flip(), buf.remaining());
          total += n;
        }
      }
      return total;
    }
    finally
    {
      if (close) close();
    }
  }

  public boolean close()
  {
    if (in != null) return in.close();
    bitsBuf = 0;
    return true;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  InStream in;
  InStream inChar;
  boolean bigEndian = true;
  Charset charset = Charset.utf8();
  Charset.Decoder charsetDecoder = charset.newDecoder();
  Charset.Encoder charsetEncoder = charset.newEncoder();
  int bitsBuf;

}
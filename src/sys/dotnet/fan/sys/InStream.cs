//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jan 07  Andy Frank  Creation
//

using System.Text;
using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// InStream interface.
  /// </summary>
  public class InStream : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static InStream make(InStream input)
    {
      InStream self = new InStream();
      make_(self, input);
      return self;
    }

    public static void make_(InStream self, InStream input)
    {
      self.m_in = input;
    }

    protected InStream()
    {
      m_charset = Charset.utf8();
      m_charsetDecoder = m_charset.newDecoder();
      m_charsetEncoder = m_charset.newEncoder();
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.InStreamType; }

  //////////////////////////////////////////////////////////////////////////
  // C# Stream
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Read a byte using a Java primitive int.  Most
    /// reads route to this method for efficient mapping to
    /// a java.io.InputStream.  If we aren't overriding this
    /// method, then route back to read() for the subclass
    /// to handle.
    /// </summary>
    public virtual int r()
    {
      Long n = read();
      if (n == null) return -1;
      return n.intValue();
    }

    /// <summary>
    /// Unread a byte using a .NET primitive int.  If we aren't
    /// overriding this method, then route back to read() for the
    /// subclass to handle.
    /// </summary>
    public virtual InStream unread(int b)
    {
      return unread((long)b);
    }

    /// <summary>
    /// Read char as primitive int.
    /// </summary>
    public virtual int rChar()
    {
      return m_charsetDecoder.decode(this);
    }

    /// <summary>
    /// Unread char as primitive int.
    /// </summary>
    public virtual InStream unreadChar(int b)
    {
      return unreadChar((long)b);
    }

  //////////////////////////////////////////////////////////////////////////
  // InStream
  //////////////////////////////////////////////////////////////////////////

    public virtual Long read()
    {
      try
      {
        return m_in.read();
      }
      catch (System.NullReferenceException e)
      {
        if (m_in == null)
          throw UnsupportedErr.make(@typeof().qname() + " wraps null InStream").val;
        else
          throw e;
      }
    }

    public virtual Long readBuf(Buf buf, long n)
    {
      try
      {
        return m_in.readBuf(buf, n);
      }
      catch (System.NullReferenceException e)
      {
        if (m_in == null)
          throw UnsupportedErr.make(@typeof().qname() + " wraps null InStream").val;
        else
          throw e;
      }
    }

    public virtual InStream unread(long n)
    {
      try
      {
        m_in.unread(n);
        return this;
      }
      catch (System.NullReferenceException e)
      {
        if (m_in == null)
          throw UnsupportedErr.make(@typeof().qname() + " wraps null InStream").val;
        else
          throw e;
      }
    }

    public virtual long skip(long n)
    {
      if (m_in != null) return m_in.skip(n);

      long nval = n;
      for (int i=0; i<nval; ++i)
        if (r() < 0) return i;
      return n;
    }

    public virtual Buf readAllBuf()
    {
      try
      {
        long size = FanInt.Chunk.longValue();
        Buf buf = Buf.make(size);
        while (readBuf(buf, size) != null);
        buf.flip();
        return buf;
      }
      finally
      {
        try { close(); } catch (System.Exception e) { Err.dumpStack(e); }
      }
    }

    public virtual Buf readBufFully(Buf buf, long n)
    {
      if (buf == null) buf = Buf.make(n);

      long total = n;
      long got = 0;
      while (got < total)
      {
        Long r = readBuf(buf, total-got);
        if (r == null || r.longValue() == 0) throw IOErr.make("Unexpected end of stream").val;
        got += r.longValue();
      }

      buf.flip();
      return buf;
    }

    public virtual Endian endian()
    {
      return m_bigEndian ? Endian.m_big : Endian.m_little;
    }

    public void endian(Endian endian)
    {
      m_bigEndian = endian == Endian.m_big;
    }

    public virtual Long peek()
    {
      Long x = read();
      if (x != null) unread(x.longValue());
      return x;
    }

    public virtual long readU1()
    {
      int c = r();
      if (c < 0) throw IOErr.make("Unexpected end of stream").val;
      return c;
    }

    public virtual long readS1()
    {
      int c = r();
      if (c < 0) throw IOErr.make("Unexpected end of stream").val;
      return (sbyte)c;
    }

    public virtual long readU2()
    {
      int c1 = r();
      int c2 = r();
      if ((c1 | c2) < 0) throw IOErr.make("Unexpected end of stream").val;
      if (m_bigEndian)
        return c1 << 8 | c2;
      else
        return c2 << 8 | c1;
    }

    public virtual long readS2()
    {
      int c1 = r();
      int c2 = r();
      if ((c1 | c2) < 0) throw IOErr.make("Unexpected end of stream").val;
      if (m_bigEndian)
        return (short)(c1 << 8 | c2);
      else
        return (short)(c2 << 8 | c1);
    }

    public virtual long readU4()
    {
      long c1 = r();
      long c2 = r();
      long c3 = r();
      long c4 = r();
      if ((c1 | c2 | c3 | c4) < 0) throw IOErr.make("Unexpected end of stream").val;
      if (m_bigEndian)
        return (c1 << 24) + (c2 << 16) + (c3 << 8) + c4;
      else
        return (c4 << 24) + (c3 << 16) + (c2 << 8) + c1;
    }

    public virtual long readS4()
    {
      int c1 = r();
      int c2 = r();
      int c3 = r();
      int c4 = r();
      if ((c1 | c2 | c3 | c4) < 0) throw IOErr.make("Unexpected end of stream").val;
      if (m_bigEndian)
        return ((c1 << 24) + (c2 << 16) + (c3 << 8) + c4);
      else
        return ((c4 << 24) + (c3 << 16) + (c2 << 8) + c1);
    }

    public virtual long readS8()
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
      if (m_bigEndian)
        return ((c1 << 56) + (c2 << 48) + (c3 << 40) + (c4 << 32) +
                (c5 << 24) + (c6 << 16) + (c7 << 8) + c8);
      else
        return ((c8 << 56) + (c7 << 48) + (c6 << 40) + (c5 << 32) +
                (c4 << 24) + (c3 << 16) + (c2 << 8) + c1);
    }

    public virtual double readF4()
    {
      return System.BitConverter.ToSingle(System.BitConverter.GetBytes(readS4()), 0);
    }

    public virtual double readF8()
    {
      return System.BitConverter.Int64BitsToDouble(readS8());
    }

    public virtual BigDecimal readDecimal()
    {
      return FanDecimal.fromStr(readUtfString(), true);
    }

    public virtual bool readBool()
    {
      int n = r();
      if (n < 0) throw IOErr.make("Unexpected end of stream").val;
      return n == 0 ? false : true;
    }

    public virtual string readUtf() { return readUtfString(); }
    private string readUtfString()
    {
      // read two-byte Length
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

      // allocate as string
      return new string(buf, 0, cnum);
    }

    public virtual Charset charset()
    {
      return m_charset;
    }

    public virtual void charset(Charset charset)
    {
      m_charsetDecoder = charset.newDecoder();
      m_charsetEncoder = charset.newEncoder();
      m_charset = charset;
    }

    public virtual Long readChar()
    {
      int ch = m_charsetDecoder.decode(this);
      return ch < 0 ? null : Long.valueOf(ch);
    }

    public virtual InStream unreadChar(long c)
    {
      m_charsetEncoder.encode((char)c, this);
      return this;
    }

    public virtual Long peekChar()
    {
      Long x = readChar();
      if (x != null) unreadChar(x.longValue());
      return x;
    }

    public virtual string readChars(long n)
    {
      if (n < 0) throw ArgErr.make("readChars n < 0: " + n).val;
      if (n == 0) return "";
      StringBuilder buf = new StringBuilder(256);
      for (int i=(int)n; i>0; --i)
      {
        int ch = rChar();
        if (ch < 0) throw IOErr.make("Unexpected end of stream").val;
        buf.Append((char)ch);
      }
      return buf.ToString();
    }

    public virtual string readLine() { return readLine(FanInt.Chunk); }
    public virtual string readLine(Long max)
    {
      // max limit
      int maxChars = (max != null) ? max.intValue() : System.Int32.MaxValue;
      if (maxChars <= 0) return string.Empty;

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

        // Append to working buffer
        buf.Append((char)c);
        if (buf.Length >= maxChars) break;

        // read next char
        c = rChar();
        if (c < 0) break;
      }
      return buf.ToString();
    }

    public virtual string readStrToken() { return readStrToken(FanInt.Chunk, null); }
    public virtual string readStrToken(Long max) { return readStrToken(max, null); }
    public virtual string readStrToken(Long max, Func f)
    {
      // max limit
      int maxChars = (max != null) ? max.intValue() : System.Int32.MaxValue;
      if (maxChars <= 0) return string.Empty;

      // read first char, if at end of file bail
      int c = rChar();
      if (c < 0) return null;

      // loop reading chars until our closure returns false
      StringBuilder buf = new StringBuilder();
      while (true)
      {
        // check for \n, \r\n, or \r
        bool terminate;
        if (f == null)
          terminate = FanInt.isSpace(c);
        else
          terminate = ((Boolean)f.call(c)).booleanValue();
        if (terminate)
        {
          unreadChar(c);
          break;
        }

        // Append to working buffer
        buf.Append((char)c);
        if (buf.Length >= maxChars) break;

        // read next char
        c = rChar();
        if (c < 0) break;
      }
      return buf.ToString();
    }

    public virtual List readAllLines()
    {
      try
      {
        List list = new List(Sys.StrType);
        string line;
        while ((line = readLine()) != null)
          list.add(line);
        return list;
      }
      finally
      {
        try { close(); } catch (System.Exception e) { Err.dumpStack(e); }
      }
    }

    public virtual void eachLine(Func f)
    {
      try
      {
        string line;
        while ((line = readLine()) != null)
          f.call(line);
      }
      finally
      {
        try { close(); } catch (System.Exception e) { Err.dumpStack(e); }
      }
    }

    public virtual string readAllStr() { return readAllStr(true); }
    public virtual string readAllStr(bool normalizeNewlines)
    {
      try
      {
        char[] buf  = new char[4096];
        int n = 0;
        bool normalize = normalizeNewlines;

        // read characters
        int last = -1;
        while (true)
        {
          int c = rChar();
          if (c < 0) break;

          // grow buffer if needed
          if (n >= buf.Length)
          {
            char[] temp = new char[buf.Length*2];
            System.Array.Copy(buf, 0, temp, 0, n);
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

        return new string(buf, 0, n);
      }
      finally
      {
        try { close(); } catch (System.Exception e) { Err.dumpStack(e); }
      }
    }

    public virtual object readObj() { return readObj(null); }
    public virtual object readObj(Map options)
    {
      return new ObjDecoder(this, options).readObj();
    }

    public virtual Map readProps() { return readProps(false); }
    public Map readPropsListVals() { return readProps(true); }

    private Map readProps(bool listVals)  // listVals is Str:Str[]
    {
      Charset origCharset = charset();
      charset(Charset.utf8());
      try
      {
        Map props = new Map(Sys.StrType, listVals ? Sys.StrType.toListOf() : Sys.StrType);

        StringBuilder name = new StringBuilder();
        StringBuilder val = null;
        int inBlockComment = 0;
        bool inEndOfLineComment = false;
        int c = ' ', last = ' ';
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
            string n = FanStr.makeTrim(name);
            if (val != null)
            {
              addProp(props, n, FanStr.makeTrim(val), listVals);
              name = new StringBuilder();
              val = null;
            }
            else if (n.Length > 0)
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
              if (n3 < 0 || n2 < 0 || n1 < 0 || n0 < 0) throw IOErr.make("Invalid hex value for \\uxxxx [Line " +  lineNum + "]").val;
              c = ((n3 << 12) | (n2 << 8) | (n1 << 4) | n0);
            }
            else throw IOErr.make("Invalid escape sequence [Line " + lineNum + "]").val;
          }

          // normal character
          if (val == null)
            name.Append((char)c);
          else
            val.Append((char)c);
        }

        string nm = FanStr.makeTrim(name);
        if (val != null)
          addProp(props, nm, FanStr.makeTrim(val), listVals);
        else if (nm.Length > 0)
          throw IOErr.make("Invalid name/value pair [Line " + lineNum + "]").val;

        return props;
      }
      finally
      {
        try { close(); } catch (System.Exception e) { Err.dumpStack(e); }
        charset(origCharset);
      }
    }

    static void addProp(Map props, string n, string v, bool listVals)
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

    public virtual long pipe(OutStream output) { return pipe(output, null, true); }
    public virtual long pipe(OutStream output, Long n) { return pipe(output, n, true); }
    public virtual long pipe(OutStream output, Long toPipe, bool cls)
    {
      try
      {
        long bufSize = FanInt.Chunk.longValue();
        Buf buf = Buf.make(bufSize);
        long total = 0;
        if (toPipe == null)
        {
          while (true)
          {
            Long n = readBuf(buf.clear(), bufSize);
            if (n == null) break;
            output.writeBuf(buf.flip(), buf.remaining());
            total += n.longValue();
          }
        }
        else
        {
          long toPipeVal = toPipe.longValue();
          while (total < toPipeVal)
          {
            if (toPipeVal - total < bufSize) bufSize = toPipeVal - total;
            Long n = readBuf(buf.clear(), bufSize);
            if (n == null) throw IOErr.make("Unexpected end of stream").val;
            output.writeBuf(buf.flip(), buf.remaining());
            total += n.longValue();
          }
        }
        return total;
      }
      finally
      {
        if (cls) close();
      }
    }

    public virtual bool close()
    {
      if (m_in != null) return m_in.close();
      return true;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal InStream m_in;
    internal bool m_bigEndian = true;
    internal Charset m_charset;
    internal Charset.Decoder m_charsetDecoder;
    internal Charset.Encoder m_charsetEncoder;

  }
}
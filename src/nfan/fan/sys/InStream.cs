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

    public static InStream makeForStr(Str s)
    {
      return new StrInStream(s);
    }

    public static InStream makeForStr(string s)
    {
      return new StrInStream(s);
    }

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

    public override Type type() { return Sys.InStreamType; }

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
      Int n = read();
      if (n == null) return -1;
      return (int)n.val;
    }

    /// <summary>
    /// Unread a byte using a Java primitive int.  If we aren't
    /// overriding this method, then route back to read() for the
    /// subclass to handle.
    /// </summary>
    public virtual InStream unread(int b)
    {
      return unread(Int.make(b));
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
      return unreadChar(Int.make(b));
    }

  //////////////////////////////////////////////////////////////////////////
  // InStream
  //////////////////////////////////////////////////////////////////////////

    public virtual Int read()
    {
      try
      {
        return m_in.read();
      }
      catch (System.NullReferenceException e)
      {
        if (m_in == null)
          throw UnsupportedErr.make(type().qname() + " wraps null InStream").val;
        else
          throw e;
      }
    }

    public virtual Int readBuf(Buf buf, Int n)
    {
      try
      {
        return m_in.readBuf(buf, n);
      }
      catch (System.NullReferenceException e)
      {
        if (m_in == null)
          throw UnsupportedErr.make(type().qname() + " wraps null InStream").val;
        else
          throw e;
      }
    }

    public virtual InStream unread(Int n)
    {
      try
      {
        m_in.unread(n);
        return this;
      }
      catch (System.NullReferenceException e)
      {
        if (m_in == null)
          throw UnsupportedErr.make(type().qname() + " wraps null InStream").val;
        else
          throw e;
      }
    }

    public virtual Int skip(Int n)
    {
      if (m_in != null) return m_in.skip(n);

      long nval = n.val;
      for (int i=0; i<nval; ++i)
        if (r() < 0) return Int.pos(i);
      return n;
    }

    public virtual Buf readAllBuf()
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
        try { close(); } catch (System.Exception e) { Err.dumpStack(e); }
      }
    }

    public virtual Buf readBufFully(Buf buf, Int n)
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

    public virtual Int peek()
    {
      Int x = read();
      if (x != null) unread(x);
      return x;
    }

    public virtual Int readU1()
    {
      int c = r();
      if (c < 0) throw IOErr.make("Unexpected end of stream").val;
      return Int.make(c);
    }

    public virtual Int readS1()
    {
      int c = r();
      if (c < 0) throw IOErr.make("Unexpected end of stream").val;
      return Int.make((sbyte)c);
    }

    public virtual Int readU2()
    {
      int c1 = r();
      int c2 = r();
      if ((c1 | c2) < 0) throw IOErr.make("Unexpected end of stream").val;
      return Int.make(c1 << 8 | c2);
    }

    public virtual Int readS2()
    {
      int c1 = r();
      int c2 = r();
      if ((c1 | c2) < 0) throw IOErr.make("Unexpected end of stream").val;
      return Int.make((short)(c1 << 8 | c2));
    }

    public virtual Int readU4()
    {
      long c1 = r();
      long c2 = r();
      long c3 = r();
      long c4 = r();
      if ((c1 | c2 | c3 | c4) < 0) throw IOErr.make("Unexpected end of stream").val;
      return Int.make((c1 << 24) + (c2 << 16) + (c3 << 8) + c4);
    }

    public virtual Int readS4() { return Int.make(readInt()); }
    public virtual int readInt()
    {
      int c1 = r();
      int c2 = r();
      int c3 = r();
      int c4 = r();
      if ((c1 | c2 | c3 | c4) < 0) throw IOErr.make("Unexpected end of stream").val;
      return ((c1 << 24) + (c2 << 16) + (c3 << 8) + c4);
    }

    public virtual Int readS8() { return Int.make(readLong()); }
    public virtual long readLong()
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

    public virtual Float readF4()
    {
      return Float.make(System.BitConverter.ToSingle(System.BitConverter.GetBytes(readInt()), 0));
    }

    public virtual Float readF8()
    {
      return Float.make(System.BitConverter.Int64BitsToDouble(readLong()));
    }

    public virtual Decimal readDecimal()
    {
      return Decimal.fromStr(readUtfString(), true);
    }

    public virtual Bool readBool()
    {
      int n = r();
      if (n < 0) throw IOErr.make("Unexpected end of stream").val;
      return n == 0 ? Bool.False : Bool.True;
    }

    public virtual Str readUtf() { return Str.make(readUtfString()); }
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

      // allocate as Str
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

    public virtual Int readChar()
    {
      int ch = m_charsetDecoder.decode(this);
      return ch < 0 ? null : Int.pos(ch);
    }

    public virtual InStream unreadChar(Int c)
    {
      m_charsetEncoder.encode((char)c.val, this);
      return this;
    }

    public virtual Int peekChar()
    {
      Int x = readChar();
      if (x != null) unreadChar(x);
      return x;
    }

    public virtual Str readLine() { return readLine(Int.Chunk); }
    public virtual Str readLine(Int max)
    {
      // max limit
      int maxChars = (max != null) ? (int)max.val : System.Int32.MaxValue;
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

        // Append to working buffer
        buf.Append((char)c);
        if (buf.Length >= maxChars) break;

        // read next char
        c = rChar();
        if (c < 0) break;
      }
      return Str.make(buf.ToString());
    }

    public virtual Str readStrToken() { return readStrToken(Int.Chunk, null); }
    public virtual Str readStrToken(Int max) { return readStrToken(max, null); }
    public virtual Str readStrToken(Int max, Func f)
    {
      // max limit
      int maxChars = (max != null) ? (int)max.val : System.Int32.MaxValue;
      if (maxChars <= 0) return Str.Empty;

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
          terminate = Int.isSpace(c);
        else
          terminate = ((Bool)f.call1(Int.pos(c))).val;
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
      return Str.make(buf.ToString());
    }

    public virtual List readAllLines()
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
        try { close(); } catch (System.Exception e) { Err.dumpStack(e); }
      }
    }

    public virtual void eachLine(Func f)
    {
      try
      {
        Str line;
        while ((line = readLine()) != null)
          f.call1(line);
      }
      finally
      {
        try { close(); } catch (System.Exception e) { Err.dumpStack(e); }
      }
    }

    public virtual Str readAllStr() { return readAllStr(Bool.True); }
    public virtual Str readAllStr(Bool normalizeNewlines)
    {
      try
      {
        char[] buf  = new char[4096];
        int n = 0;
        bool normalize = normalizeNewlines.val;

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

        return Str.make(new string(buf, 0, n));
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

    public virtual Map readProps()
    {
      Charset origCharset = charset();
      charset(Charset.utf8());
      try
      {
        Map props = new Map(Sys.StrType, Sys.StrType);

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
            Str n = Str.makeTrim(name);
            if (val != null)
            {
              props.add(n, Str.makeTrim(val));
              name = new StringBuilder();
              val = null;
            }
            else if (n.val.Length > 0)
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
            name.Append((char)c);
          else
            val.Append((char)c);
        }

        Str nm = Str.makeTrim(name);
        if (val != null)
          props.add(nm, Str.makeTrim(val));
        else if (nm.val.Length > 0)
          throw IOErr.make("Invalid name/value pair [Line " + lineNum + "]").val;

        return props;
      }
      finally
      {
        try { close(); } catch (System.Exception e) { Err.dumpStack(e); }
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

    public virtual Int pipe(OutStream output) { return pipe(output, null, Bool.True); }
    public virtual Int pipe(OutStream output, Int n) { return pipe(output, n, Bool.True); }
    public virtual Int pipe(OutStream output, Int toPipe, Bool cls)
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
            output.writeBuf(buf.flip(), buf.remaining());
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
            output.writeBuf(buf.flip(), buf.remaining());
            total += n.val;
          }
        }
        return Int.make(total);
      }
      finally
      {
        if (cls.val) close();
      }
    }

    public virtual Bool close()
    {
      if (m_in != null) return m_in.close();
      return Bool.True;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal InStream m_in;
    internal Charset m_charset;
    internal Charset.Decoder m_charsetDecoder;
    internal Charset.Encoder m_charsetEncoder;

  }
}

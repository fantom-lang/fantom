//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jan 07  Andy Frank  Creation
//

using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// OutStream.
  /// </summary>
  public class OutStream : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static OutStream make(OutStream output)
    {
      OutStream self = new OutStream();
      make_(self, output);
      return self;
    }

    public static void make_(OutStream self, OutStream output)
    {
      self.m_out = output;
    }

    protected OutStream()
    {
      m_charset = Charset.utf8();
      m_charsetEncoder = m_charset.newEncoder();
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.OutStreamType; }

  //////////////////////////////////////////////////////////////////////////
  // C# OutputStream
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Write a byte using a Java primitive int.  Most
    /// writes route to this method for efficient mapping to
    /// a java.io.OutputStream.  If we aren't overriding this
    /// method, then route back to write(long) for the
    /// subclass to handle.
    /// <summary>
    public virtual OutStream w(int b)
    {
      return write(b);
    }

  //////////////////////////////////////////////////////////////////////////
  // OutStream
  //////////////////////////////////////////////////////////////////////////

    public virtual OutStream write(long x)
    {
      try
      {
        m_out.write(x);
        return this;
      }
      catch (System.NullReferenceException e)
      {
        if (m_out == null)
          throw UnsupportedErr.make(@typeof().qname() + " wraps null OutStream").val;
        else
          throw e;
      }
    }

    public virtual OutStream writeBuf(Buf buf) { return writeBuf(buf, buf.remaining()); }
    public virtual OutStream writeBuf(Buf buf, long n)
    {
      try
      {
        m_out.writeBuf(buf, n);
        return this;
      }
      catch (System.NullReferenceException e)
      {
        if (m_out == null)
          throw UnsupportedErr.make(@typeof().qname() + " wraps null OutStream").val;
        else
          throw e;
      }
    }

    public virtual Endian endian()
    {
      return m_bigEndian ? Endian.m_big : Endian.m_little;
    }

    public virtual void endian(Endian endian)
    {
      m_bigEndian = endian == Endian.m_big;
    }

    public virtual OutStream writeI2(long x)
    {
      int v = (int)x;
      if (m_bigEndian)
        return this.w((v >> 8) & 0xFF)
                   .w((v >> 0) & 0xFF);
      else
        return this.w((v >> 0) & 0xFF)
                   .w((v >> 8) & 0xFF);
    }

    public virtual OutStream writeI4(long x)
    {
      int v = (int)x;
      if (m_bigEndian)
        return this.w((v >> 24) & 0xFF)
                   .w((v >> 16) & 0xFF)
                   .w((v >> 8)  & 0xFF)
                   .w((v >> 0)  & 0xFF);
      else
        return this.w((v >> 0)  & 0xFF)
                   .w((v >> 8)  & 0xFF)
                   .w((v >> 16) & 0xFF)
                   .w((v >> 24) & 0xFF);
    }

    public virtual OutStream writeI8(long v)
    {
      if (m_bigEndian)
        return this.w((int)(v >> 56) & 0xFF)
                   .w((int)(v >> 48) & 0xFF)
                   .w((int)(v >> 40) & 0xFF)
                   .w((int)(v >> 32) & 0xFF)
                   .w((int)(v >> 24) & 0xFF)
                   .w((int)(v >> 16) & 0xFF)
                   .w((int)(v >> 8)  & 0xFF)
                   .w((int)(v >> 0)  & 0xFF);
      else
        return this.w((int)(v >> 0)  & 0xFF)
                   .w((int)(v >> 8)  & 0xFF)
                   .w((int)(v >> 16) & 0xFF)
                   .w((int)(v >> 24) & 0xFF)
                   .w((int)(v >> 32) & 0xFF)
                   .w((int)(v >> 40) & 0xFF)
                   .w((int)(v >> 48) & 0xFF)
                   .w((int)(v >> 56) & 0xFF);
    }

    public virtual OutStream writeF4(double x)
    {
      return writeI4(System.BitConverter.ToInt32(System.BitConverter.GetBytes((float)x), 0));
    }

    public virtual OutStream writeF8(double x)
    {
      return writeI8(System.BitConverter.DoubleToInt64Bits(x));
    }

    public virtual OutStream writeDecimal(BigDecimal x)
    {
      return writeUtfString(x.ToString());
    }

    public virtual OutStream writeBool(bool x)
    {
      return w(x ? 1 : 0);
    }

    public virtual OutStream writeUtf(string x) { return writeUtfString(x); }
    private OutStream writeUtfString(string s)
    {
      int slen = s.Length;
      int utflen = 0;

      // first we have to figure m_out the utf Length
      for (int i=0; i<slen; ++i)
      {
        int c = s[i];
        if (c <= 0x007F)
          utflen +=1;
        else if (c > 0x07FF)
          utflen += 3;
        else
          utflen += 2;
      }

      // sanity check
      if (utflen > 65536) throw IOErr.make("String too big").val;

      // write Length as 2 byte value
      w((utflen >> 8) & 0xFF);
      w((utflen >> 0) & 0xFF);

      // write characters
      for (int i=0; i<slen; ++i)
      {
        int c = s[i];
        if (c <= 0x007F)
        {
          w(c);
        }
        else if (c > 0x07FF)
        {
          w(0xE0 | ((c >> 12) & 0x0F));
          w(0x80 | ((c >>  6) & 0x3F));
          w(0x80 | ((c >>  0) & 0x3F));
        }
        else
        {
          w(0xC0 | ((c >>  6) & 0x1F));
          w(0x80 | ((c >>  0) & 0x3F));
        }
      }
      return this;
    }

    public virtual Charset charset()
    {
      return m_charset;
    }

    public virtual void charset(Charset charset)
    {
      m_charsetEncoder = charset.newEncoder();
      m_charset = charset;
    }

    public virtual OutStream writeChar(long c)
    {
      m_charsetEncoder.encode((char)c, this);
      return this;
    }

    public virtual OutStream writeChar(char c)
    {
      m_charsetEncoder.encode(c, this);
      return this;
    }

    public virtual OutStream writeChars(string s) { return writeChars(s, 0, s.Length); }
    public virtual OutStream writeChars(string s, long off) { return writeChars(s, (int)off, s.Length-(int)off); }
    public virtual OutStream writeChars(string s, long off, long len) { return writeChars(s, (int)off, (int)len); }
    public virtual OutStream writeChars(string s, int off, int len)
    {
      int end = off+len;
      for (int i=off; i<end; ++i)
        m_charsetEncoder.encode(s[i], this);
      return this;
    }

    public virtual OutStream print(object obj)
    {
      string s = obj == null ? "null" : toStr(obj);
      return writeChars(s, 0, s.Length);
    }

    public virtual OutStream printLine() { return printLine(""); }
    public virtual OutStream printLine(object obj)
    {
      string s = obj == null ? "null" : toStr(obj);
      writeChars(s, 0, s.Length);
      return writeChar('\n');
    }

    public virtual OutStream writeObj(object obj) { return writeObj(obj, null); }
    public virtual OutStream writeObj(object obj, Map options)
    {
      new ObjEncoder(this, options).writeObj(obj);
      return this;
    }

    public virtual OutStream writeProps(Map props) { return writeProps(props, true); }
    public virtual OutStream writeProps(Map props, bool cls)
    {
      Charset origCharset = charset();
      charset(Charset.utf8());
      try
      {
        List keys = props.keys().sort();
        int size = keys.sz();
        long eq = '=';
        long nl = '\n';
        for (int i=0; i<size; ++i)
        {
          string key = (string)keys.get(i);
          string val = (string)props.get(key);
          writePropStr(key);
          writeChar(eq);
          writePropStr(val);
          writeChar(nl);
        }
        return this;
      }
      finally
      {
        try { if (cls) close(); } catch (System.Exception e) { Err.dumpStack(e); }
        charset(origCharset);
      }
    }

    private void writePropStr(string s)
    {
      int len = s.Length;
      for (int i=0; i<len; ++i)
      {
        int ch = s[i];
        int peek = i+1<len ? s[i+1] : -1;

        // escape special chars
        switch (ch)
        {
          case '\n': writeChar('\\').writeChar('n'); continue;
          case '\r': writeChar('\\').writeChar('r'); continue;
          case '\t': writeChar('\\').writeChar('t'); continue;
          case '\\': writeChar('\\').writeChar('\\'); continue;
        }

        // escape control chars, comments, and =
        if ((ch < ' ') || (ch == '/' && (peek == '/' || peek == '*')) || (ch == '='))
        {
          long nib1 = FanInt.toDigit((ch>>4)&0xf, 16).longValue();
          long nib2 = FanInt.toDigit((ch>>0)&0xf, 16).longValue();

          this.writeChar('\\').writeChar('u')
              .writeChar('0').writeChar('0')
              .writeChar(nib1).writeChar(nib2);
          continue;
        }

        // normal character
        writeChar(ch);
      }
    }

    public OutStream writeXml(string s) { return writeXml(s, 0); }
    public OutStream writeXml(string s, long mask)
    {
      bool escNewlines  = (mask & m_xmlEscNewlines) != 0;
      bool escQuotes    = (mask & m_xmlEscQuotes) != 0;
      bool escUnicode   = (mask & m_xmlEscUnicode) != 0;
      Charset.Encoder enc  = m_charsetEncoder;
      int len = s.Length;

      for (int i=0; i<len; ++i)
      {
        int ch = s[i];
        switch (ch)
        {
          // table switch on control chars
          case  0: case  1: case  2: case  3: case  4: case  5: case  6:
          case  7: case  8: /*case  9: case 10:*/ case 11: case 12: /*case 13:*/
          case 14: case 15: case 16: case 17: case 18: case 19: case 20:
          case 21: case 22: case 23: case 24: case 25: case 26: case 27:
          case 28: case 29: case 30: case 31:
            writeXmlEsc(ch);
            break;

          // newlines
          case '\n': case '\r':
            if (!escNewlines)
              enc.encode((char)ch, this);
            else
              writeXmlEsc(ch);
            break;

          // space
          case ' ':
            enc.encode(' ', this);
            break;

          // table switch on common ASCII chars
          case '!': case '#': case '$': case '%': case '(': case ')': case '*':
          case '+': case ',': case '-': case '.': case '/': case '0': case '1':
          case '2': case '3': case '4': case '5': case '6': case '7': case '8':
          case '9': case ':': case ';': case '=': case '?': case '@': case 'A':
          case 'B': case 'C': case 'D': case 'E': case 'F': case 'G': case 'H':
          case 'I': case 'J': case 'K': case 'L': case 'M': case 'N': case 'O':
          case 'P': case 'Q': case 'R': case 'S': case 'T': case 'U': case 'V':
          case 'W': case 'X': case 'Y': case 'Z': case '[': case '\\': case ']':
          case '^': case '_': case '`': case 'a': case 'b': case 'c': case 'd':
          case 'e': case 'f': case 'g': case 'h': case 'i': case 'j': case 'k':
          case 'l': case 'm': case 'n': case 'o': case 'p': case 'q': case 'r':
          case 's': case 't': case 'u': case 'v': case 'w': case 'x': case 'y':
          case 'z': case '{': case '|': case '}': case '~':
            enc.encode((char)ch, this);
            break;

          // XML control characters
          case '<':
            enc.encode('&', this);
            enc.encode('l', this);
            enc.encode('t', this);
            enc.encode(';', this);
            break;
          case '>':
            if (i > 0 && s[i-1] != ']') enc.encode('>', this);
            else
            {
              enc.encode('&', this);
              enc.encode('g', this);
              enc.encode('t', this);
              enc.encode(';', this);
            }
            break;
          case '&':
            enc.encode('&', this);
            enc.encode('a', this);
            enc.encode('m', this);
            enc.encode('p', this);
            enc.encode(';', this);
            break;
          case '"':
            if (!escQuotes) enc.encode((char)ch, this);
            else
            {
              enc.encode('&', this);
              enc.encode('q', this);
              enc.encode('u', this);
              enc.encode('o', this);
              enc.encode('t', this);
              enc.encode(';', this);
            }
            break;
          case '\'':
            if (!escQuotes) enc.encode((char)ch, this);
            else
            {
              enc.encode('&', this);
              enc.encode('a', this);
              enc.encode('p', this);
              enc.encode('o', this);
              enc.encode('s', this);
              enc.encode(';', this);
            }
            break;

          // default
          default:
            if (ch <= 0xf7 || !escUnicode)
              enc.encode((char)ch, this);
            else
              writeXmlEsc(ch);
            break;
        }
      }
      return this;
    }

    private void writeXmlEsc(int ch)
    {
      Charset.Encoder enc = m_charsetEncoder;
      string hex = "0123456789abcdef";

      enc.encode('&', this);
      enc.encode('#', this);
      enc.encode('x', this);
      if (ch > 0xff)
      {
        enc.encode(hex[(ch >> 12) & 0xf], this);
        enc.encode(hex[(ch >> 8)  & 0xf], this);
      }
      enc.encode(hex[(ch >> 4) & 0xf], this);
      enc.encode(hex[(ch >> 0) & 0xf], this);
      enc.encode(';', this);
    }

    public static readonly long m_xmlEscNewlines = 0x01;
    public static readonly long m_xmlEscQuotes   = 0x02;
    public static readonly long m_xmlEscUnicode  = 0x04;

    public virtual OutStream flush()
    {
      if (m_out != null) m_out.flush();
      return this;
    }

    public virtual OutStream sync()
    {
      if (m_out != null) m_out.sync();
      return this;
    }

    public virtual bool close()
    {
      if (m_out != null) return m_out.close();
      return true;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal OutStream m_out;
    internal bool m_bigEndian = true;
    internal Charset m_charset;
    internal Charset.Encoder m_charsetEncoder;
  }
}
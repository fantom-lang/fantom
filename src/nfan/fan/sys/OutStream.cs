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

    public static OutStream makeForStrBuf(StrBuf buf)
    {
      return new StrBufOutStream(buf);
    }

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

    public override Type type() { return Sys.OutStreamType; }

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
          throw UnsupportedErr.make(type().qname() + " wraps null OutStream").val;
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
          throw UnsupportedErr.make(type().qname() + " wraps null OutStream").val;
        else
          throw e;
      }
    }

    public virtual OutStream writeI2(long x)
    {
      int v = (int)x;
      return this.w((v >> 8) & 0xFF)
                 .w((v >> 0) & 0xFF);
    }

    public virtual OutStream writeI4(long x) { return writeI4((int)x); }
    public virtual OutStream writeI4(int v)
    {
      return this.w((v >> 24) & 0xFF)
                 .w((v >> 16) & 0xFF)
                 .w((v >> 8)  & 0xFF)
                 .w((v >> 0)  & 0xFF);
    }

    public virtual OutStream writeI8(long v)
    {
      return this.w((int)(v >> 56) & 0xFF)
                 .w((int)(v >> 48) & 0xFF)
                 .w((int)(v >> 40) & 0xFF)
                 .w((int)(v >> 32) & 0xFF)
                 .w((int)(v >> 24) & 0xFF)
                 .w((int)(v >> 16) & 0xFF)
                 .w((int)(v >> 8)  & 0xFF)
                 .w((int)(v >> 0)  & 0xFF);
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

    public virtual OutStream writeBool(Boolean x)
    {
      return w(x.booleanValue() ? 1 : 0);
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
      string s = obj == null ? FanStr.nullStr : toStr(obj);
      return writeChars(s, 0, s.Length);
    }

    public virtual OutStream printLine() { return printLine(string.Empty); }
    public virtual OutStream printLine(object obj)
    {
      string s = obj == null ? FanStr.nullStr : toStr(obj);
      writeChars(s, 0, s.Length);
      return writeChar('\n');
    }

    public virtual OutStream writeObj(object obj) { return writeObj(obj, null); }
    public virtual OutStream writeObj(object obj, Map options)
    {
      new ObjEncoder(this, options).writeObj(obj);
      return this;
    }

    public virtual OutStream writeProps(Map props) { return writeProps(props, Boolean.True); }
    public virtual OutStream writeProps(Map props, Boolean cls)
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
        try { if (cls.booleanValue()) close(); } catch (System.Exception e) { Err.dumpStack(e); }
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

    public virtual OutStream flush()
    {
      if (m_out != null) m_out.flush();
      return this;
    }

    public virtual Boolean close()
    {
      if (m_out != null) return m_out.close();
      return Boolean.True;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal OutStream m_out;
    internal Charset m_charset;
    internal Charset.Encoder m_charsetEncoder;
  }
}
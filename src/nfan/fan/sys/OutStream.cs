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
    /// method, then route back to write(Int) for the
    /// subclass to handle.
    /// <summary>
    public virtual OutStream w(int b)
    {
      return write(Int.make(b));
    }

  //////////////////////////////////////////////////////////////////////////
  // OutStream
  //////////////////////////////////////////////////////////////////////////

    public virtual OutStream write(Int x)
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
    public virtual OutStream writeBuf(Buf buf, Int n)
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

    public virtual OutStream writeI2(Int x)
    {
      int v = (int)x.val;
      return this.w((v >> 8) & 0xFF)
                 .w((v >> 0) & 0xFF);
    }

    public virtual OutStream writeI4(Int x) { return writeI4((int)x.val); }
    public virtual OutStream writeI4(int v)
    {
      return this.w((v >> 24) & 0xFF)
                 .w((v >> 16) & 0xFF)
                 .w((v >> 8)  & 0xFF)
                 .w((v >> 0)  & 0xFF);
    }

    public virtual OutStream writeI8(Int x) { return writeI8(x.val); }
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

    public virtual OutStream writeF4(Double x)
    {
      return writeI4(System.BitConverter.ToInt32(System.BitConverter.GetBytes(x.floatValue()), 0));
    }

    public virtual OutStream writeF8(Double x)
    {
      return writeI8(System.BitConverter.DoubleToInt64Bits(x.doubleValue()));
    }

    public virtual OutStream writeDecimal(Decimal x)
    {
      return writeUtfString(x.val.ToString());
    }

    public virtual OutStream writeBool(Boolean x)
    {
      return w(x.booleanValue() ? 1 : 0);
    }

    public virtual OutStream writeUtf(Str x) { return writeUtfString(x.val); }
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

    public virtual OutStream writeChar(Int c)
    {
      m_charsetEncoder.encode((char)c.val, this);
      return this;
    }

    public virtual OutStream writeChar(char c)
    {
      m_charsetEncoder.encode(c, this);
      return this;
    }

    public virtual OutStream writeChars(Str s) { return writeChars(s.val, 0, s.val.Length); }
    public virtual OutStream writeChars(Str s, Int off) { return writeChars(s.val, (int)off.val, s.val.Length-(int)off.val); }
    public virtual OutStream writeChars(Str s, Int off, Int len) { return writeChars(s.val, (int)off.val, (int)len.val); }
    public virtual OutStream writeChars(string s, int off, int len)
    {
      int end = off+len;
      for (int i=off; i<end; ++i)
        m_charsetEncoder.encode(s[i], this);
      return this;
    }

    public virtual OutStream print(object obj)
    {
      Str s = obj == null ? Str.nullStr : toStr(obj);
      return writeChars(s, Int.Zero, s.size());
    }

    public virtual OutStream printLine() { return printLine(Str.Empty); }
    public virtual OutStream printLine(object obj)
    {
      Str s = obj == null ? Str.nullStr : toStr(obj);
      writeChars(s, Int.Zero, s.size());
      return writeChar(Int.m_pos['\n']);
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
        Int eq = Int.m_pos['='];
        Int nl = Int.m_pos['\n'];
        for (int i=0; i<size; ++i)
        {
          Str key = (Str)keys.get(i);
          Str val = (Str)props.get(key);
          writePropStr(key.val);
          writeChar(eq);
          writePropStr(val.val);
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
          case '\n': writeChar(Int.m_pos['\\']).writeChar(Int.m_pos['n']); continue;
          case '\r': writeChar(Int.m_pos['\\']).writeChar(Int.m_pos['r']); continue;
          case '\t': writeChar(Int.m_pos['\\']).writeChar(Int.m_pos['t']); continue;
          case '\\': writeChar(Int.m_pos['\\']).writeChar(Int.m_pos['\\']); continue;
        }

        // escape control chars, comments, and =
        if ((ch < ' ') || (ch == '/' && (peek == '/' || peek == '*')) || (ch == '='))
        {
          Int nib1 = Int.m_pos[(ch>>4)&0xf].toDigit(Int.m_pos[16]);
          Int nib2 = Int.m_pos[(ch>>0)&0xf].toDigit(Int.m_pos[16]);

          this.writeChar(Int.m_pos['\\']).writeChar(Int.m_pos['u'])
              .writeChar(Int.m_pos['0']).writeChar(Int.m_pos['0'])
              .writeChar(nib1).writeChar(nib2);
          continue;
        }

        // normal character
        writeChar(Int.pos(ch));
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
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Apr 07  Andy Frank  Creation
//

using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// Charset.
  /// </summary>
  public class Charset : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Charset fromStr(string name) { return fromStr(name, true); }
    public static Charset fromStr(string name, bool check)
    {
      try
      {
        // lookup charset, to ensure we get normlized name
        Encoding en = Encoding.GetEncoding(name);

        // check normalized name for predefined charsets
        string csName = en.WebName.ToUpper();
        if (csName == "UTF-8") return utf8();
        if (csName == "UTF-16") return utf16LE();
        if (csName == "UNICODEFFFE") return utf16BE();
        if (csName == "ISO-8859-1") return iso8859_1();

        // create new wrapper
        return new Charset(en);
      }
      catch (System.Exception e)
      {
        if (!check) return null;
        throw ParseErr.make("Charset", name, e.ToString()).val;
      }
    }

    private Charset(Encoding encoding)
    {
      this.m_encoding = encoding;
      this.m_name     = encoding.WebName.ToUpper();
    }

    private Charset(Encoding encoding, string name)
    {
      this.m_encoding = encoding;
      this.m_name     = name;
    }

    public static Charset defVal()
    {
      return utf8();
    }

  //////////////////////////////////////////////////////////////////////////
  // UTF-8
  //////////////////////////////////////////////////////////////////////////

    public static Charset utf8()
    {
      if (m_utf8 == null) m_utf8 = new Utf8Charset();
      return m_utf8;
    }

    internal class Utf8Charset : Charset
    {
      internal Utf8Charset() : base(new UTF8Encoding(), "UTF-8") {}
      public override Encoder newEncoder() { return encoder; }
      public override Decoder newDecoder() { return decoder; }
      readonly Encoder encoder = new Utf8Encoder();
      readonly Decoder decoder = new Utf8Decoder();
    }

    internal class Utf8Encoder : Encoder
    {
      public override void encode(char c, OutStream @out)
      {
        if (c <= 0x007F)
        {
          @out.w(c);
        }
        else if (c > 0x07FF)
        {
          @out.w(0xE0 | ((c >> 12) & 0x0F))
              .w(0x80 | ((c >>  6) & 0x3F))
              .w(0x80 | ((c >>  0) & 0x3F));
        }
        else
        {
          @out.w(0xC0 | ((c >>  6) & 0x1F))
              .w(0x80 | ((c >>  0) & 0x3F));
        }
      }

      public override void encode(char c, InStream @out)
      {
        if (c <= 0x007F)
        {
          @out.unread(c);
        }
        else if (c > 0x07FF)
        {
          @out.unread(0x80 | ((c >>  0) & 0x3F))
              .unread(0x80 | ((c >>  6) & 0x3F))
              .unread(0xE0 | ((c >> 12) & 0x0F));
        }
        else
        {
          @out.unread(0x80 | ((c >>  0) & 0x3F))
              .unread(0xC0 | ((c >>  6) & 0x1F));
        }
      }
    }

    internal class Utf8Decoder : Decoder
    {
      public override int decode(InStream @in)
      {
        int c = @in.r();
        if (c < 0) return -1;
        int c2, c3;
        switch (c >> 4)
        {
          case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
            /* 0xxxxxxx*/
            return c;
          case 12: case 13:
            /* 110x xxxx   10xx xxxx*/
            c2 = @in.r();
            if ((c2 & 0xC0) != 0x80)
              throw IOErr.make("Invalid UTF-8 encoding").val;
            return ((c & 0x1F) << 6) | (c2 & 0x3F);
          case 14:
            /* 1110 xxxx  10xx xxxx  10xx xxxx */
            c2 = @in.r();
            c3 = @in.r();
            if (((c2 & 0xC0) != 0x80) || ((c3 & 0xC0) != 0x80))
              throw IOErr.make("Invalid UTF-8 encoding").val;
            return (((c & 0x0F) << 12) | ((c2 & 0x3F) << 6) | ((c3 & 0x3F) << 0));
          default:
            throw IOErr.make("Invalid UTF-8 encoding").val;
        }
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // UTF-16BE
  //////////////////////////////////////////////////////////////////////////

    public static Charset utf16BE()
    {
      if (m_utf16BE == null) m_utf16BE = new Utf16BECharset();
      return m_utf16BE;
    }

    internal class Utf16BECharset : Charset
    {
      internal Utf16BECharset() : base(new UnicodeEncoding(true, true), "UTF-16BE") {}
      public override Encoder newEncoder() { return encoder; }
      public override Decoder newDecoder() { return decoder; }
      readonly Encoder encoder = new Utf16BEEncoder();
      readonly Decoder decoder = new Utf16BEDecoder();
    }

    internal class Utf16BEEncoder : Encoder
    {
      public override void encode(char c, OutStream @out)
      {
        @out.w((c >> 8) & 0xFF)
            .w((c >> 0) & 0xFF);
      }

      public override void encode(char c, InStream @out)
      {
        @out.unread((c >> 0) & 0xFF)
            .unread((c >> 8) & 0xFF);
      }
    }

    internal class Utf16BEDecoder : Decoder
    {
      public override int decode(InStream @in)
      {
        int c1 = @in.r();
        int c2 = @in.r();
        if ((c1 | c2) < 0) return -1;
        return ((c1 << 8) | c2);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // UTF-16LE
  //////////////////////////////////////////////////////////////////////////

    public static Charset utf16LE()
    {
      if (m_utf16LE == null) m_utf16LE = new Utf16LECharset();
      return m_utf16LE;
    }

    internal class Utf16LECharset : Charset
    {
      internal Utf16LECharset() : base(new UnicodeEncoding(false, true), "UTF-16LE") {}
      public override Encoder newEncoder() { return encoder; }
      public override Decoder newDecoder() { return decoder; }
      readonly Encoder encoder = new Utf16LEEncoder();
      readonly Decoder decoder = new Utf16LEDecoder();
    }

    internal class Utf16LEEncoder : Encoder
    {
      public override void encode(char c, OutStream @out)
      {
        @out.w((c >> 0) & 0xFF)
            .w((c >> 8) & 0xFF);
      }

      public override void encode(char c, InStream @out)
      {
        @out.unread((c >> 8) & 0xFF)
            .unread((c >> 0) & 0xFF);
      }
    }

    internal class Utf16LEDecoder : Decoder
    {
      public override int decode(InStream @in)
      {
        int c1 = @in.r();
        int c2 = @in.r();
        if ((c1 | c2) < 0) return -1;
        return (c1 | (c2 << 8));
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // ISO-8859-1
  //////////////////////////////////////////////////////////////////////////

    public static Charset iso8859_1()
    {
      if (m_iso8859_1 == null) m_iso8859_1 = new Iso8859Charset();
      return m_iso8859_1;
    }

    internal class Iso8859Charset : Charset
    {
      internal Iso8859Charset() : base(Encoding.GetEncoding("ISO-8859-1"), "ISO-8859-1") {}
      public override Encoder newEncoder() { return encoder; }
      public override Decoder newDecoder() { return decoder; }
      readonly Encoder encoder = new Iso8859Encoder();
      readonly Decoder decoder = new Iso8859Decoder();
    }

    internal class Iso8859Encoder : Encoder
    {
      public override void encode(char c, OutStream @out)
      {
        if (c > 0xFF) throw IOErr.make("Invalid ISO-8859-1 char").val;
        @out.w((c >> 0) & 0xFF);
      }

      public override void encode(char c, InStream @out)
      {
        @out.unread((c >> 0) & 0xFF);
      }
    }

    internal class Iso8859Decoder : Decoder
    {
      public override int decode(InStream @in)
      {
        return @in.r();
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.CharsetType; }

    public string name() { return m_name; }

    public override int GetHashCode() { return m_encoding.GetHashCode(); }

    public override long hash() { return m_encoding.GetHashCode(); }

    public override bool Equals(object obj)
    {
      if (obj is Charset)
      {
        return ((Charset)obj).m_encoding.Equals(this.m_encoding);
      }
      return false;
    }

    public override string toStr() { return m_name; }

  //////////////////////////////////////////////////////////////////////////
  // Encoder
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Create a new encoder - a separate encoder is needed for each stream.
    /// </summary>
    public virtual Encoder newEncoder()
    {
      return new DefaultEncoder(this);
    }

    /// <summary>
    /// Encoder is used to encode characters to bytes.
    /// </summary>
    public abstract class Encoder
    {
      public abstract void encode(char ch, OutStream @out);  // -> w(int)
      public abstract void encode(char ch, InStream @out);   // -> unread(int)
    }

    /// <summary>
    /// DefaultEncoder.
    /// </summary>
    internal class DefaultEncoder : Encoder
    {
      internal DefaultEncoder(Charset charset)
      {
        this.charset = charset;
      }

      public override void encode(char ch, OutStream @out)
      {
        cbuf[0] = ch;
        int len = charset.m_encoding.GetBytes(cbuf, 0, 1, bbuf, 0);
        for (int i=0; i<len; i++)
          @out.w(bbuf[i]);
      }

      public override void encode(char ch, InStream @out)
      {
        // TODO - how does this work?
      }

      Charset charset;
      char[] cbuf = new char[1];
      byte[] bbuf = new byte[16];
    }

  //////////////////////////////////////////////////////////////////////////
  // Decoder
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Create a new decoder - a separate encoder is needed for each stream.
    /// </summary>
    public virtual Decoder newDecoder()
    {
      return new DefaultDecoder(this);
    }

    /// <summary>
    /// Decoder is used to decode bytes to characters.
    /// </summary>
    public abstract class Decoder
    {
      public abstract int decode(InStream @in);
    }

    /// <summary>
    /// DefaultDecoder.
    /// <summary>
    internal class DefaultDecoder : Decoder
    {
      internal DefaultDecoder(Charset charset)
      {
        this.charset = charset;
      }

      public override int decode(InStream @in)
      {
        // TODO - well shit, how do we know how many bytes to read generically?

        int len = 1;
        int b = @in.r();
        if (b < 0) return -1;

        bbuf[0] = (byte)b;

        cbuf = charset.m_encoding.GetChars(bbuf, 0, len);
        return cbuf[0];
      }

      Charset charset;
      char[] cbuf = new char[1];
      byte[] bbuf = new byte[16];
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static Charset m_utf8, m_utf16BE, m_utf16LE, m_iso8859_1;

    internal readonly Encoding m_encoding;
    internal readonly string m_name;

  }
}
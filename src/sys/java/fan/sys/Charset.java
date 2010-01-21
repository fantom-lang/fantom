//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Mar 06  Brian Frank  Creation
//
package fan.sys;

import java.nio.*;
import java.nio.charset.CharsetEncoder;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CoderResult;

/**
 * Charset
 */
public class Charset
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Charset fromStr(String name) { return fromStr(name, true); }
  public static Charset fromStr(String name, boolean checked)
  {
    try
    {
      // lookup charset, to ensure we get normlized name
      java.nio.charset.Charset cs = java.nio.charset.Charset.forName(name);

      // check normalized name for predefined charsets
      String csName = cs.name().toUpperCase();
      if (csName.equals("UTF-8")) return utf8();
      if (csName.equals("UTF-16BE")) return utf16BE();
      if (csName.equals("UTF-16LE")) return utf16LE();
      if (csName.equals("ISO-8859-1")) return iso8859_1();

      // create new wrapper
      return new Charset(cs);
    }
    catch (Exception e)
    {
      if (!checked) return null;
      throw ParseErr.make("Charset", name, e.toString()).val;
    }
  }

  private Charset(java.nio.charset.Charset charset)
  {
    this.charset = charset;
    this.name    = charset.name();
  }

  public static Charset defVal() { return utf8(); }

//////////////////////////////////////////////////////////////////////////
// UTF-8
//////////////////////////////////////////////////////////////////////////

  public static Charset utf8()
  {
    if (utf8 == null) utf8 = new Charset(java.nio.charset.Charset.forName("UTF-8"))
    {
      public Encoder newEncoder() { return encoder; }
      public Decoder newDecoder() { return decoder; }
      final Encoder encoder = new Utf8Encoder();
      final Decoder decoder = new Utf8Decoder();
    };
    return utf8;
  }

  static class Utf8Encoder extends Encoder
  {
    public void encode(char c, OutStream out)
    {
      if (c <= 0x007F)
      {
        out.w(c);
      }
      else if (c > 0x07FF)
      {
        out.w(0xE0 | ((c >> 12) & 0x0F))
           .w(0x80 | ((c >>  6) & 0x3F))
           .w(0x80 | ((c >>  0) & 0x3F));
      }
      else
      {
        out.w(0xC0 | ((c >>  6) & 0x1F))
           .w(0x80 | ((c >>  0) & 0x3F));
      }
    }

    public void encode(char c, InStream out)
    {
      if (c <= 0x007F)
      {
        out.unread(c);
      }
      else if (c > 0x07FF)
      {
        out.unread(0x80 | ((c >>  0) & 0x3F))
           .unread(0x80 | ((c >>  6) & 0x3F))
           .unread(0xE0 | ((c >> 12) & 0x0F));
      }
      else
      {
        out.unread(0x80 | ((c >>  0) & 0x3F))
           .unread(0xC0 | ((c >>  6) & 0x1F));
      }
    }
  }

  static class Utf8Decoder extends Decoder
  {
    public int decode(InStream in)
    {
      int c = in.r();
      if (c < 0) return -1;
      int c2, c3;
      switch (c >> 4)
      {
        case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
          /* 0xxxxxxx*/
          return c;
        case 12: case 13:
          /* 110x xxxx   10xx xxxx*/
          c2 = in.r();
          if ((c2 & 0xC0) != 0x80)
            throw IOErr.make("Invalid UTF-8 encoding").val;
          return ((c & 0x1F) << 6) | (c2 & 0x3F);
        case 14:
          /* 1110 xxxx  10xx xxxx  10xx xxxx */
          c2 = in.r();
          c3 = in.r();
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
    if (utf16BE == null) utf16BE = new Charset(java.nio.charset.Charset.forName("UTF-16BE"))
    {
      public Encoder newEncoder() { return encoder; }
      public Decoder newDecoder() { return decoder; }
      final Encoder encoder = new Utf16BEEncoder();
      final Decoder decoder = new Utf16BEDecoder();
    };
    return utf16BE;
  }

  static class Utf16BEEncoder extends Encoder
  {
    public void encode(char c, OutStream out)
    {
      out.w((c >>> 8) & 0xFF)
         .w((c >>> 0) & 0xFF);
    }

    public void encode(char c, InStream out)
    {
      out.unread((c >>> 0) & 0xFF)
         .unread((c >>> 8) & 0xFF);
    }
  }

  static class Utf16BEDecoder extends Decoder
  {
    public int decode(InStream in)
    {
      int c1 = in.r();
      int c2 = in.r();
      if ((c1 | c2) < 0) return -1;
      return ((c1 << 8) | c2);
    }
  }

//////////////////////////////////////////////////////////////////////////
// UTF-16LE
//////////////////////////////////////////////////////////////////////////

  public static Charset utf16LE()
  {
    if (utf16LE == null) utf16LE = new Charset(java.nio.charset.Charset.forName("UTF-16LE"))
    {
      public Encoder newEncoder() { return encoder; }
      public Decoder newDecoder() { return decoder; }
      final Encoder encoder = new Utf16LEEncoder();
      final Decoder decoder = new Utf16LEDecoder();
    };
    return utf16LE;
  }

  static class Utf16LEEncoder extends Encoder
  {
    public void encode(char c, OutStream out)
    {
      out.w((c >>> 0) & 0xFF)
         .w((c >>> 8) & 0xFF);
    }

    public void encode(char c, InStream out)
    {
      out.unread((c >>> 8) & 0xFF)
         .unread((c >>> 0) & 0xFF);
    }
  }

  static class Utf16LEDecoder extends Decoder
  {
    public int decode(InStream in)
    {
      int c1 = in.r();
      int c2 = in.r();
      if ((c1 | c2) < 0) return -1;
      return (c1 | (c2 << 8));
    }
  }

//////////////////////////////////////////////////////////////////////////
// ISO-8859-1
//////////////////////////////////////////////////////////////////////////

  public static Charset iso8859_1()
  {
    if (iso8859_1 == null) iso8859_1 = new Charset(java.nio.charset.Charset.forName("ISO-8859-1"))
    {
      public Encoder newEncoder() { return encoder; }
      public Decoder newDecoder() { return decoder; }
      final Encoder encoder = new Iso8859Encoder();
      final Decoder decoder = new Iso8859Decoder();
    };
    return iso8859_1;
  }

  static class Iso8859Encoder extends Encoder
  {
    public void encode(char c, OutStream out)
    {
      if (c > 0xFF) throw IOErr.make("Invalid ISO-8859-1 char").val;
      out.w((c >>> 0) & 0xFF);
    }

    public void encode(char c, InStream out)
    {
      out.unread((c >>> 0) & 0xFF);
    }
  }

  static class Iso8859Decoder extends Decoder
  {
    public int decode(InStream in)
    {
      return in.r();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.CharsetType; }

  public String name() { return name; }

  public int hashCode() { return charset.hashCode(); }

  public long hash() { return charset.hashCode(); }

  public boolean equals(Object obj)
  {
    if (obj instanceof Charset)
    {
      return ((Charset)obj).charset.equals(this.charset);
    }
    return false;
  }

  public String toStr() { return name; }

//////////////////////////////////////////////////////////////////////////
// Encoder
//////////////////////////////////////////////////////////////////////////

  /**
   * Create a new encoder - a separate encoder is needed for each stream.
   */
  public Encoder newEncoder()
  {
    return new NioEncoder(this);
  }

  /**
   * Encoder is used to encode characters to bytes.
   */
  public static abstract class Encoder
  {
    public abstract void encode(char ch, OutStream out);  // -> w(int)
    public abstract void encode(char ch, InStream out);   // -> unread(int)
  }

  /**
   * NIO encoder uses the Java java.nio.charset APIs to encode characters.
   * But the over-engineered NIO APIs make it very difficult to perform
   * fast unbufferred IO.  So we just use this encoder as a last resort
   * fallback.  Testing shows that the custom encoders perform about twice
   * as fast as using NIO.
   */
  static class NioEncoder extends Encoder
  {
    NioEncoder(Charset charset)
    {
      this.charset = charset;
      this.encoder = charset.charset.newEncoder();
    }

    public void encode(char ch, OutStream out)
    {
      // ready input char buffer
      cbuf.clear();
      cbuf.put(ch);
      cbuf.flip();

      // ready output byte buffer
      bbuf.clear();

      // call into encoder
      CoderResult r;
      encoder.reset();
      r = encoder.encode(cbuf, bbuf, true);
      if (r.isError()) throw IOErr.make("Invalid " + charset.name + " encoding").val;
      r = encoder.flush(bbuf);
      if (r.isError()) throw IOErr.make("Invalid " + charset.name + " encoding").val;

      // drain from internal byte buffer to fan buf
      bbuf.flip();
      while (bbuf.hasRemaining())
        out.w(bbuf.get());
    }

    public void encode(char ch, InStream out)
    {
      // ready input char buffer
      cbuf.clear();
      cbuf.put(ch);
      cbuf.flip();

      // ready output byte buffer
      bbuf.clear();

      // call into encoder
      CoderResult r;
      encoder.reset();
      r = encoder.encode(cbuf, bbuf, true);
      if (r.isError()) throw IOErr.make("Invalid " + charset.name + " encoding").val;
      r = encoder.flush(bbuf);
      if (r.isError()) throw IOErr.make("Invalid " + charset.name + " encoding").val;

      // drain from internal byte buffer to fan buf
      bbuf.flip();
      while (bbuf.hasRemaining())
        out.unread(bbuf.get());
    }

    Charset charset;
    CharsetEncoder encoder;
    CharBuffer cbuf = CharBuffer.allocate(1);
    ByteBuffer bbuf = ByteBuffer.allocate(16);
  }

//////////////////////////////////////////////////////////////////////////
// Decoder
//////////////////////////////////////////////////////////////////////////

  /**
   * Create a new decoder - a separate encoder is needed for each stream.
   */
  public Decoder newDecoder()
  {
    return new NioDecoder(this);
  }

  /**
   * Decoder is used to decode bytes to characters.
   */
  public static abstract class Decoder
  {
    public abstract int decode(InStream in);
  }

  /**
   * NIO decoder uses the Java java.nio.charset APIs to decode characters.
   * But the over-engineered NIO APIs make it very difficult to perform
   * fast unbufferred IO.  So we just use this decoder as a last resort
   * fallback.  Testing shows that the custom encoders perform about twice
   * as fast as using NIO.
   */
  static class NioDecoder extends Decoder
  {
    NioDecoder(Charset charset)
    {
      this.charset = charset;
      this.decoder = charset.charset.newDecoder();
    }

    public int decode(InStream in)
    {
      // many thanks to Ron Hitchens (author of O'Reilly Java NIO)
      // for helping me figure out how to make this work - it's still
      // a bit of black magic to me - now I can go watch Battlestar
      // Galactica

      // reset buffers
      decoder.reset();
      bbuf.clear();

      // pass thru one byte at a time until we have a char
      while (true)
      {
        int b = in.r();
        if (b < 0) return -1;

        cbuf.clear();
        bbuf.put((byte)b);
        bbuf.flip();

        CoderResult r = decoder.decode(bbuf, cbuf, false);

        if (r.isError())
          throw IOErr.make("Invalid " + charset.name + " encoding").val;

        bbuf.compact();
        cbuf.flip();

        if (cbuf.hasRemaining())
          return cbuf.get();
      }
    }

    Charset charset;
    CharsetDecoder decoder;
    CharBuffer cbuf = CharBuffer.allocate(16);
    ByteBuffer bbuf = ByteBuffer.allocate(16);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static Charset utf8, utf16BE, utf16LE, iso8859_1;

  final java.nio.charset.Charset charset;
  final String name;

}
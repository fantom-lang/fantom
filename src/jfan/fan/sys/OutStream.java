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
 * OutStream.
 */
public class OutStream
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static OutStream makeForStrBuf(StrBuf buf)
  {
    return new StrBufOutStream(buf);
  }

  public static OutStream make(OutStream out)
  {
    OutStream self = new OutStream();
    make$(self, out);
    return self;
  }

  public static void make$(OutStream self, OutStream out)
  {
    self.out = out;
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.OutStreamType; }

//////////////////////////////////////////////////////////////////////////
// Java OutputStream
//////////////////////////////////////////////////////////////////////////

  /**
   * Write a byte using a Java primitive int.  Most
   * writes route to this method for efficient mapping to
   * a java.io.OutputStream.  If we aren't overriding this
   * method, then route back to write(Int) for the
   * subclass to handle.
   */
  public OutStream w(int b)
  {
    return write(Int.make(b));
  }

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

  public OutStream write(Int x)
  {
    try
    {
      out.write(x);
      return this;
    }
    catch (NullPointerException e)
    {
      if (out == null)
        throw UnsupportedErr.make(type().qname() + " wraps null OutStream").val;
      else
        throw e;
    }
  }

  public OutStream writeBuf(Buf buf) { return writeBuf(buf, buf.remaining()); }
  public OutStream writeBuf(Buf buf, Int n)
  {
    try
    {
      out.writeBuf(buf, n);
      return this;
    }
    catch (NullPointerException e)
    {
      if (out == null)
        throw UnsupportedErr.make(type().qname() + " wraps null OutStream").val;
      else
        throw e;
    }
  }

  public OutStream writeI2(Int x)
  {
    int v = (int)x.val;
    return this.w((v >>> 8) & 0xFF)
               .w((v >>> 0) & 0xFF);
  }

  public OutStream writeI4(Int x) { return writeI4((int)x.val); }
  public OutStream writeI4(int v)
  {
    return this.w((v >>> 24) & 0xFF)
               .w((v >>> 16) & 0xFF)
               .w((v >>> 8)  & 0xFF)
               .w((v >>> 0)  & 0xFF);
  }

  public OutStream writeI8(Int x) { return writeI8(x.val); }
  public OutStream writeI8(long v)
  {
    return this.w((int)(v >>> 56) & 0xFF)
               .w((int)(v >>> 48) & 0xFF)
               .w((int)(v >>> 40) & 0xFF)
               .w((int)(v >>> 32) & 0xFF)
               .w((int)(v >>> 24) & 0xFF)
               .w((int)(v >>> 16) & 0xFF)
               .w((int)(v >>> 8)  & 0xFF)
               .w((int)(v >>> 0)  & 0xFF);
  }

  public OutStream writeF4(Float x)
  {
    return writeI4(java.lang.Float.floatToIntBits((float)x.val));
  }

  public OutStream writeF8(Float x)
  {
    return writeI8(Double.doubleToLongBits(x.val));
  }

  public OutStream writeDecimal(Decimal x)
  {
    return writeUtfString(x.val.toString());
  }

  public OutStream writeBool(Bool x)
  {
    return w(x.val ? 1 : 0);
  }

  public OutStream writeUtf(Str x) { return writeUtfString(x.val); }
  private OutStream writeUtfString(String s)
  {
    int slen = s.length();
    int utflen = 0;

    // first we have to figure out the utf length
    for (int i=0; i<slen; ++i)
    {
      int c = s.charAt(i);
      if (c <= 0x007F)
        utflen +=1;
      else if (c > 0x07FF)
        utflen += 3;
      else
        utflen += 2;
    }

    // sanity check
    if (utflen > 65536) throw IOErr.make("String too big").val;

    // write length as 2 byte value
    w((utflen >>> 8) & 0xFF);
    w((utflen >>> 0) & 0xFF);

    // write characters
    for (int i=0; i<slen; ++i)
    {
      int c = s.charAt(i);
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

  public Charset charset()
  {
    return charset;
  }

  public void charset(Charset charset)
  {
    this.charsetEncoder = charset.newEncoder();
    this.charset = charset;
  }

  public OutStream writeChar(Int c)
  {
    charsetEncoder.encode((char)c.val, this);
    return this;
  }

  public OutStream writeChar(char c)
  {
    charsetEncoder.encode(c, this);
    return this;
  }

  public OutStream writeChars(Str s) { return writeChars(s.val, 0, s.val.length()); }
  public OutStream writeChars(Str s, Int off) { return writeChars(s.val, (int)off.val, s.val.length()-(int)off.val); }
  public OutStream writeChars(Str s, Int off, Int len) { return writeChars(s.val, (int)off.val, (int)len.val); }
  public OutStream writeChars(String s) { return writeChars(s, 0, s.length()); }
  public OutStream writeChars(String s, int off, int len)
  {
    int end = off+len;
    for (int i=off; i<end; ++i)
      charsetEncoder.encode(s.charAt(i), this);
    return this;
  }

  public OutStream print(Obj obj)
  {
    Str s = obj == null ? Str.nullStr : obj.toStr();
    return writeChars(s, Int.Zero, s.size());
  }

  public OutStream printLine() { return printLine(Str.Empty); }
  public OutStream printLine(Obj obj)
  {
    Str s = obj == null ? Str.nullStr : obj.toStr();
    writeChars(s, Int.Zero, s.size());
    return writeChar(Int.pos['\n']);
  }

  public OutStream writeObj(Obj obj) { return writeObj(obj, null); }
  public OutStream writeObj(Obj obj, Map options)
  {
    new ObjEncoder(this, options).writeObj(obj);
    return this;
  }

  public OutStream writeProps(Map props) { return writeProps(props, Bool.True); }
  public OutStream writeProps(Map props, Bool close)
  {
    Charset origCharset = charset();
    charset(Charset.utf8());
    try
    {
      List keys = props.keys().sort();
      int size = keys.sz();
      Int eq = Int.pos['='];
      Int nl = Int.pos['\n'];
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
      try { if (close.val) close(); } catch (Exception e) { e.printStackTrace(); }
      charset(origCharset);
    }
  }

  private void writePropStr(String s)
  {
    int len = s.length();
    for (int i=0; i<len; ++i)
    {
      int ch = s.charAt(i);
      int peek = i+1<len ? s.charAt(i+1) : -1;

      // escape special chars
      switch (ch)
      {
        case '\n': writeChar(Int.pos['\\']).writeChar(Int.pos['n']); continue;
        case '\r': writeChar(Int.pos['\\']).writeChar(Int.pos['r']); continue;
        case '\t': writeChar(Int.pos['\\']).writeChar(Int.pos['t']); continue;
        case '\\': writeChar(Int.pos['\\']).writeChar(Int.pos['\\']); continue;
      }

      // escape control chars, comments, and =
      if ((ch < ' ') || (ch == '/' && (peek == '/' || peek == '*')) || (ch == '='))
      {
        Int nib1 = Int.pos[(ch>>4)&0xf].toDigit(Int.pos[16]);
        Int nib2 = Int.pos[(ch>>0)&0xf].toDigit(Int.pos[16]);

        this.writeChar(Int.pos['\\']).writeChar(Int.pos['u'])
            .writeChar(Int.pos['0']).writeChar(Int.pos['0'])
            .writeChar(nib1).writeChar(nib2);
        continue;
      }

      // normal character
      writeChar(Int.pos(ch));
    }
  }

  public OutStream flush()
  {
    if (out != null) out.flush();
    return this;
  }

  public Bool close()
  {
    if (out != null) return out.close();
    return Bool.True;
  }

//////////////////////////////////////////////////////////////////////////
// Java Utils
//////////////////////////////////////////////////////////////////////////

  public OutStream indent(int num)
  {
    for (int i=0; i<num; ++i)
      charsetEncoder.encode(' ', this);
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  OutStream out;
  Charset charset = Charset.utf8();
  Charset.Encoder charsetEncoder = charset.newEncoder();

}
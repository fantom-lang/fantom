//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Feb 07  Andy Frank  Creation
//

using System;
using System.IO;
using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// Buf
  /// </summary>
  public abstract class Buf : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public static Buf make() { return new MemBuf(1024); }
    public static Buf make(Long capacity) { return new MemBuf((int)capacity.longValue()); }

    public static Buf random(Long s)
    {
      int size = s.intValue();
      byte[] buf = new byte[size];
      Random random = new Random();

      for (int i=0; i<size;)
      {
        int x = random.Next();
        buf[i++] = (byte)(x >> 24);
        if (i < size)
        {
          buf[i++] = (byte)(x >> 16);
          if (i < size)
          {
            buf[i++] = (byte)(x >> 8);
            if (i < size) buf[i++] = (byte)x;
          }
        }
      }

      return new MemBuf(buf);
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Boolean _equals(object that)
    {
      return this == that ? Boolean.True : Boolean.False;
    }

    public override Str toStr()
    {
      return Str.make(type().name().val + "(pos=" + getPos() + " size=" + getSize() + ")");
    }

    public override Type type() { return Sys.BufType; }

  //////////////////////////////////////////////////////////////////////////
  // Support
  //////////////////////////////////////////////////////////////////////////

    internal abstract long getSize();
    internal abstract void setSize(long x);
    internal abstract long getPos();
    internal abstract void setPos(long x);
    internal abstract int getByte(long pos);
    internal abstract void getBytes(long pos, byte[] dst, int off, int len);
    internal abstract void setByte(long pos, int x);

    internal abstract void pipeTo(byte[] dst, int dstPos, int len);
    internal abstract void pipeTo(Stream dst, long len);
    //internal abstract void pipeTo(ByteBuffer dst, int len);

    internal abstract void pipeFrom(byte[] src, int srcPos, int len);
    internal abstract long pipeFrom(Stream src, long len);
    //internal abstract void pipeTo(ByteBuffer dst, int len);

  //////////////////////////////////////////////////////////////////////////
  // Access
  //////////////////////////////////////////////////////////////////////////

    public Boolean empty()
    {
      return getSize() == 0 ? Boolean.True : Boolean.False;
    }

    public virtual Long capacity()
    {
      return FanInt.m_maxValue;
    }

    public virtual void capacity(Long c)
    {
    }

    public Long size()
    {
      return Long.valueOf(getSize());
    }

    public void size(Long s)
    {
      setSize(s.longValue());
    }

    public Long pos()
    {
      return Long.valueOf(getPos());
    }

    public Long remaining()
    {
      return Long.valueOf(getSize()-getPos());
    }

    public Boolean more()
    {
      return getSize()-getPos() > 0 ? Boolean.True : Boolean.False;
    }

    public Buf seek(Long pos)
    {
      long p = pos.longValue();
      long size = getSize();
      if (p < 0) p = size + p;
      if (p < 0 || p > size) throw IndexErr.make(pos).val;
      setPos(p);
      return this;
    }

    public Buf flip()
    {
      setSize(getPos());
      setPos(0);
      return this;
    }

    public Long get(Long pos)
    {
      long p = pos.longValue();
      long size = getSize();
      if (p < 0) p = size + p;
      if (p < 0 || p >= size) throw IndexErr.make(pos).val;
      return FanInt.m_pos[getByte(p)];
    }

    public Buf slice(Range range)
    {
      long size = getSize();
      long s = range.start(size);
      long e = range.end(size);
      int n = (int)(e - s + 1);
      if (n < 0) throw IndexErr.make(range).val;

      byte[] slice = new byte[n];
      getBytes(s, slice, 0, n);

      Buf result = new MemBuf(slice, n);
      result.charset(charset());
      return result;
    }

  //////////////////////////////////////////////////////////////////////////
  // Modification
  //////////////////////////////////////////////////////////////////////////

    public Buf set(Long pos, Long b)
    {
      long p = pos.longValue();
      long size = getSize();
      if (p < 0) p = size + p;
      if (p < 0 || p >= size) throw IndexErr.make(pos).val;
      setByte(p, b.intValue());
      return this;
    }

    public virtual Buf trim()
    {
      return this;
    }

    public Buf clear()
    {
      setPos(0);
      setSize(0);
      return this;
    }

    public virtual Buf flush()
    {
      return this;
    }

    public virtual Boolean close()
    {
      return Boolean.True;
    }

    public Charset charset()
    {
      return m_out.charset();
    }

    public void charset(Charset charset)
    {
      m_out.charset(charset);
      m_in.charset(charset);
    }

  //////////////////////////////////////////////////////////////////////////
  // OutStream
  //////////////////////////////////////////////////////////////////////////

    public OutStream @out() { return m_out; }

    public Buf write(Long b) { m_out.write(b); return this; }

    public Buf writeBuf(Buf other) { m_out.writeBuf(other); return this; }
    public Buf writeBuf(Buf other, Long n) { m_out.writeBuf(other, n); return this; }

    public Buf writeI2(Long x) { m_out.writeI2(x); return this; }

    public Buf writeI4(Long x) { m_out.writeI4(x); return this; }

    public Buf writeI8(Long x) { m_out.writeI8(x); return this; }

    public Buf writeF4(Double x) { m_out.writeF4(x); return this; }

    public Buf writeF8(Double x) { m_out.writeF8(x); return this; }

    public Buf writeDecimal(BigDecimal x) { m_out.writeDecimal(x); return this; }

    public Buf writeBool(Boolean x) { m_out.writeBool(x); return this; }

    public Buf writeUtf(Str x) { m_out.writeUtf(x); return this; }

    public Buf writeChar(Long c) { m_out.writeChar(c); return this; }

    public Buf writeChars(Str s) { m_out.writeChars(s); return this; }
    public Buf writeChars(Str s, Long off) { m_out.writeChars(s, off); return this; }
    public Buf writeChars(Str s, Long off, Long len) { m_out.writeChars(s, off, len); return this; }

    public Buf print(object obj) { m_out.print(obj); return this; }

    public Buf printLine() { m_out.printLine(); return this; }
    public Buf printLine(object obj) { m_out.printLine(obj); return this; }

    public Buf writeObj(object obj) { m_out.writeObj(obj); return this; }
    public Buf writeObj(object obj, Map opt) { m_out.writeObj(obj, opt); return this; }

  //////////////////////////////////////////////////////////////////////////
  // InStream
  //////////////////////////////////////////////////////////////////////////

    public InStream @in() { return m_in; }

    public Long read() {  return m_in.read(); }

    public Long readBuf(Buf other, Long n) { return m_in.readBuf(other, n); }

    public Buf unread(Long n) { m_in.unread(n); return this; }

    public Buf readBufFully(Buf buf, Long n) { return m_in.readBufFully(buf, n); }

    public Buf readAllBuf() { return m_in.readAllBuf(); }

    public Long peek() { return m_in.peek(); }

    public Long readU1() { return m_in.readU1(); }

    public Long readS1() { return m_in.readS1(); }

    public Long readU2() { return m_in.readU2(); }

    public Long readS2() { return m_in.readS2(); }

    public Long readU4() { return m_in.readU4(); }

    public Long readS4() { return m_in.readS4(); }

    public Long readS8() { return m_in.readS8(); }

    public Double readF4() { return m_in.readF4(); }

    public Double readF8() { return m_in.readF8(); }

    public BigDecimal readDecimal() { return m_in.readDecimal(); }

    public Boolean readBool() { return m_in.readBool(); }

    public Str readUtf() { return m_in.readUtf(); }

    public Long readChar() { return m_in.readChar(); }

    public Buf unreadChar(Long c) { m_in.unreadChar(c); return this; }

    public Long peekChar() { return m_in.peekChar(); }

    public Str readLine() { return m_in.readLine(); }
    public Str readLine(Long max) { return m_in.readLine(max); }

    public Str readStrToken() { return m_in.readStrToken(); }
    public Str readStrToken(Long max) { return m_in.readStrToken(max); }
    public Str readStrToken(Long max, Func f) { return m_in.readStrToken(FanInt.Chunk, f); }

    public List readAllLines() { return m_in.readAllLines(); }

    public void eachLine(Func f) { m_in.eachLine(f); }

    public Str readAllStr() { return m_in.readAllStr(); }
    public Str readAllStr(Boolean normalizeNewlines)  { return m_in.readAllStr(normalizeNewlines); }

    public object readObj() { return m_in.readObj(); }

  //////////////////////////////////////////////////////////////////////////
  // Hex
  //////////////////////////////////////////////////////////////////////////

    public virtual Str toHex()
    {
      throw UnsupportedErr.make(type()+".toHex").val;
    }

    public static Buf fromHex(Str str)
    {
      string s = str.val;
      int slen = s.Length;
      byte[] buf = new byte[slen/2];
      int[] hexInv = Buf.hexInv;
      int size = 0;

      for (int i=0; i<slen; ++i)
      {
        int c0 = s[i];
        int n0 = c0 < 128 ? hexInv[c0] : -1;
        if (n0 < 0) continue;

        int n1 = -1;
        if (++i < slen)
        {
          int c1 = s[i];
          n1 = c1 < 128 ? hexInv[c1] : -1;
        }
        if (n1 < 0) throw IOErr.make("Invalid hex str").val;

        buf[size++] = (byte)((n0 << 4) | n1);
      }

      return new MemBuf(buf, size);
    }

  //////////////////////////////////////////////////////////////////////////
  // Base64
  //////////////////////////////////////////////////////////////////////////

    public virtual Str toBase64()
    {
      throw UnsupportedErr.make(type()+".toBase64").val;
    }

    public static Buf fromBase64(Str str)
    {
      string s = str.val;
      int slen = s.Length;
      int si = 0;
      int max = slen * 6 / 8;
      byte[] buf = new byte[max];
      int size = 0;

      while (si < slen)
      {
        int n = 0;
        int v = 0;
        for (int j=0; j<4 && si<slen;)
        {
          int ch = s[si++];
          int c = ch < 128 ? base64inv[ch] : -1;
          if (c >= 0)
          {
            n |= c << (18 - j++ * 6);
            if (ch != '=') v++;
          }
        }

        if (v > 1) buf[size++] = (byte)(n >> 16);
        if (v > 2) buf[size++] = (byte)(n >> 8);
        if (v > 3) buf[size++] = (byte)n;
      }

      return new MemBuf(buf, size);
    }

  //////////////////////////////////////////////////////////////////////////
  // Digest
  //////////////////////////////////////////////////////////////////////////

    public virtual Buf toDigest(Str algorithm)
    {
      throw UnsupportedErr.make(type()+".toDigest").val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Static
  //////////////////////////////////////////////////////////////////////////

    internal static readonly char[] hexChars = "0123456789abcdef".ToCharArray();
    internal static readonly int[] hexInv    = new int[128];

    internal static readonly char[] base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".ToCharArray();
    internal static readonly int[] base64inv = new int[128];

    static Buf()
    {
      // base64
      for (int i=0; i<hexInv.Length; ++i) hexInv[i] = -1;
      for (int i=0; i<10; ++i)  hexInv['0'+i] = i;
      for (int i=10; i<16; ++i) hexInv['a'+i-10] = hexInv['A'+i-10] = i;

      // hex
      for (int i=0; i<base64inv.Length; ++i)   base64inv[i] = -1;
      for (int i=0; i<base64chars.Length; ++i) base64inv[base64chars[i]] = i;
      base64inv['='] = 0;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal OutStream m_out;
    internal InStream m_in;

  }
}
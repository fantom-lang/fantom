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
    public static Buf make(long capacity) { return new MemBuf((int)capacity); }

    public static Buf random(long s)
    {
      int size = (int)s;
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

    public override string toStr()
    {
      return @typeof().name() + "(pos=" + getPos() + " size=" + getSize() + ")";
    }

    public override Type @typeof() { return Sys.BufType; }

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

    public bool isEmpty()
    {
      return getSize() == 0;
    }

    public virtual long capacity()
    {
      return FanInt.m_maxVal;
    }

    public virtual void capacity(long c)
    {
    }

    public long size()
    {
      return getSize();
    }

    public void size(long s)
    {
      setSize(s);
    }

    public long pos()
    {
      return getPos();
    }

    public long remaining()
    {
      return getSize()-getPos();
    }

    public bool more()
    {
      return getSize()-getPos() > 0;
    }

    public Buf seek(long pos)
    {
      long p = pos;
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

    public long get(long pos)
    {
      long size = getSize();
      if (pos < 0) pos = size + pos;
      if (pos < 0 || pos >= size) throw IndexErr.make(pos).val;
      return getByte(pos);
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

    public Buf dup()
    {
      int size = (int)this.size();
      byte[] copy = new byte[size];
      getBytes(0, copy, 0, size);

      Buf result = new MemBuf(copy, size);
      result.charset(charset());
      return result;
    }

  //////////////////////////////////////////////////////////////////////////
  // Modification
  //////////////////////////////////////////////////////////////////////////

    public Buf set(long pos, long b)
    {
      long size = getSize();
      if (pos < 0) pos = size + pos;
      if (pos < 0 || pos >= size) throw IndexErr.make(pos).val;
      setByte(pos, (int)b);
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

    public virtual bool close()
    {
      return true;
    }

    public Endian endian()
    {
      return m_out.endian();
    }

    public void endian(Endian endian)
    {
      m_out.endian(endian);
      m_in.endian(endian);
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

    public Buf fill(long b, long times)
    {
      if (capacity() < size()+times) capacity(size()+times);
      int t = (int)times;
      for (int i=0; i<t; ++i) m_out.write(b);
      return this;
    }

  //////////////////////////////////////////////////////////////////////////
  // OutStream
  //////////////////////////////////////////////////////////////////////////

    public OutStream @out() { return m_out; }

    public Buf write(long b) { m_out.write(b); return this; }

    public Buf writeBuf(Buf other) { m_out.writeBuf(other); return this; }
    public Buf writeBuf(Buf other, long n) { m_out.writeBuf(other, n); return this; }

    public Buf writeI2(long x) { m_out.writeI2(x); return this; }

    public Buf writeI4(long x) { m_out.writeI4(x); return this; }

    public Buf writeI8(long x) { m_out.writeI8(x); return this; }

    public Buf writeF4(double x) { m_out.writeF4(x); return this; }

    public Buf writeF8(double x) { m_out.writeF8(x); return this; }

    public Buf writeDecimal(BigDecimal x) { m_out.writeDecimal(x); return this; }

    public Buf writeBool(bool x) { m_out.writeBool(x); return this; }

    public Buf writeUtf(string x) { m_out.writeUtf(x); return this; }

    public Buf writeChar(long c) { m_out.writeChar(c); return this; }

    public Buf writeChars(string s) { m_out.writeChars(s); return this; }
    public Buf writeChars(string s, long off) { m_out.writeChars(s, off); return this; }
    public Buf writeChars(string s, long off, long len) { m_out.writeChars(s, off, len); return this; }

    public Buf print(object obj) { m_out.print(obj); return this; }

    public Buf printLine() { m_out.printLine(); return this; }
    public Buf printLine(object obj) { m_out.printLine(obj); return this; }

    public Buf writeProps(Map props) { m_out.writeProps(props); return this; }

    public Buf writeObj(object obj) { m_out.writeObj(obj); return this; }
    public Buf writeObj(object obj, Map opt) { m_out.writeObj(obj, opt); return this; }

    public Buf writeXml(string s) { m_out.writeXml(s, 0); return this; }
    public Buf writeXml(string s, long flags) { m_out.writeXml(s, flags); return this; }

  //////////////////////////////////////////////////////////////////////////
  // InStream
  //////////////////////////////////////////////////////////////////////////

    public InStream @in() { return m_in; }

    public Long read() {  return m_in.read(); }

    public Long readBuf(Buf other, long n) { return m_in.readBuf(other, n); }

    public Buf unread(long n) { m_in.unread(n); return this; }

    public Buf readBufFully(Buf buf, long n) { return m_in.readBufFully(buf, n); }

    public Buf readAllBuf() { return m_in.readAllBuf(); }

    public Long peek() { return m_in.peek(); }

    public long readU1() { return m_in.readU1(); }

    public long readS1() { return m_in.readS1(); }

    public long readU2() { return m_in.readU2(); }

    public long readS2() { return m_in.readS2(); }

    public long readU4() { return m_in.readU4(); }

    public long readS4() { return m_in.readS4(); }

    public long readS8() { return m_in.readS8(); }

    public double readF4() { return m_in.readF4(); }

    public double readF8() { return m_in.readF8(); }

    public BigDecimal readDecimal() { return m_in.readDecimal(); }

    public bool readBool() { return m_in.readBool(); }

    public string readUtf() { return m_in.readUtf(); }

    public Long readChar() { return m_in.readChar(); }

    public Buf unreadChar(long c) { m_in.unreadChar(c); return this; }

    public Long peekChar() { return m_in.peekChar(); }

    public string readChars(long n) { return m_in.readChars(n); }

    public string readLine() { return m_in.readLine(); }
    public string readLine(Long max) { return m_in.readLine(max); }

    public string readStrToken() { return m_in.readStrToken(); }
    public string readStrToken(Long max) { return m_in.readStrToken(max); }
    public string readStrToken(Long max, Func f) { return m_in.readStrToken(FanInt.Chunk, f); }

    public List readAllLines() { return m_in.readAllLines(); }

    public void eachLine(Func f) { m_in.eachLine(f); }

    public string readAllStr() { return m_in.readAllStr(); }
    public string readAllStr(bool normalizeNewlines)  { return m_in.readAllStr(normalizeNewlines); }

    public Map readProps() { return m_in.readProps(); }

    public object readObj() { return m_in.readObj(); }
    public object readObj(Map opt) { return m_in.readObj(opt); }

  //////////////////////////////////////////////////////////////////////////
  // Hex
  //////////////////////////////////////////////////////////////////////////

    public virtual string toHex()
    {
      throw UnsupportedErr.make(@typeof()+".toHex").val;
    }

    public static Buf fromHex(string s)
    {
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

    public virtual string toBase64()
    {
      throw UnsupportedErr.make(@typeof()+".toBase64").val;
    }

    public static Buf fromBase64(string s)
    {
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

    public virtual Buf toDigest(string algorithm)
    {
      throw UnsupportedErr.make(@typeof()+".toDigest").val;
    }

    public virtual Buf hmac(String algorithm, Buf key)
    {
      throw UnsupportedErr.make(@typeof()+".hmac").val;
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
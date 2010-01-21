//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Feb 08  Andy Frank  Split out from Buf
//

using Math = System.Math;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// MemBuf.
  /// </summary>
  public sealed class MemBuf : Buf
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public MemBuf(int capacity)
      : this(new byte[capacity], 0)
    {
    }

    public MemBuf(byte[] bytes)
      : this(bytes, bytes.Length)
    {
    }

    public MemBuf(byte[] bytes, int size)
    {
      this.m_buf  = bytes;
      this.m_pos  = 0;
      this.m_size = size;
      this.m_out  = new MemBufOutStream(this);
      this.m_in   = new MemBufInStream(this);
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.MemBufType; }

  //////////////////////////////////////////////////////////////////////////
  // Buf Support
  //////////////////////////////////////////////////////////////////////////

    internal override long getSize()
    {
      return m_size;
    }

    internal override void setSize(long x)
    {
      int newSize = (int)x;
      if (newSize > m_buf.Length)
      {
        byte[] temp = new byte[newSize];
        System.Array.Copy(m_buf, 0, temp, 0, m_buf.Length);
        m_buf = temp;
      }
      m_size = newSize;
    }

    internal override long getPos()
    {
      return m_pos;
    }

    internal override void setPos(long x)
    {
      this.m_pos = (int)x;
    }

    internal override int getByte(long pos)
    {
      return m_buf[(int)pos] & 0xFF;
    }

    internal override void setByte(long pos, int x)
    {
      m_buf[(int)pos] = (byte)x;
    }

    internal override void getBytes(long pos, byte[] dest, int off, int len)
    {
      System.Array.Copy(m_buf, pos, dest, off, len);
    }

    internal override void pipeTo(byte[] dst, int dstPos, int len)
    {
      if (m_pos + len > m_size) throw IOErr.make("Not enough bytes to write").val;
      System.Array.Copy(m_buf, m_pos, dst, dstPos, len);
      m_pos += len;
    }

    internal override void pipeTo(Stream dst, long lenLong)
    {
      int len = (int)lenLong;
      if (m_pos + len > m_size) throw IOErr.make("Not enough bytes to write").val;
      dst.Write(m_buf, m_pos, len);
      m_pos += len;
    }

    /*
    internal override void pipeTo(ByteBuffer dst, int len)
    {
      if (pos + len > size) throw IOErr.make("Not enough bytes to write").val;
      dst.put(buf, pos, len);
      pos += len;
    }
    */

    internal override void pipeFrom(byte[] src, int srcPos, int len)
    {
      grow(m_pos+len);
      System.Array.Copy(src, srcPos, m_buf, m_pos, len);
      m_pos += len;
      m_size = m_pos;
    }

    internal override long pipeFrom(Stream src, long lenLong)
    {
      int len = (int)lenLong;
      grow(m_pos+len);
      int read = src.Read(m_buf, m_pos, len);
      if (read == 0) return -1;
      m_pos  += read;
      m_size = m_pos;
      return read;
    }

    /*
    internal override int pipeFrom(ByteBuffer src, int len)
    {
      grow(pos+len);
      src.get(buf, pos, len);
      pos += len;
      size = pos;
      return len;
    }
    */

  //////////////////////////////////////////////////////////////////////////
  // Buf API
  //////////////////////////////////////////////////////////////////////////

    public override sealed long capacity()
    {
      return m_buf.Length;
    }

    public override sealed void capacity(long c)
    {
      int newCapacity = (int)c;
      if (newCapacity < m_size) throw ArgErr.make("capacity < size").val;
      byte[] temp = new byte[newCapacity];
      System.Array.Copy(m_buf, 0, temp, 0, Math.Min(m_size, newCapacity));
      m_buf = temp;
    }

    public override Buf trim()
    {
      if (m_size == m_buf.Length) return this;
      byte[] temp = new byte[m_size];
      System.Array.Copy(m_buf, 0, temp, 0, m_size);
      m_buf = temp;
      return this;
    }

    public override string toHex()
    {
      char[] hexChars = Buf.hexChars;
      StringBuilder s = new StringBuilder(m_size*2);
      for (int i=0; i<m_size; ++i)
      {
        int b = m_buf[i] & 0xFF;
        s.Append(hexChars[b>>4]).Append(hexChars[b&0xf]);
      }
      return s.ToString();
    }

    public override string toBase64()
    {
      StringBuilder s = new StringBuilder(m_size*2);
      char[] base64chars = Buf.base64chars;
      int i = 0;

      // append full 24-bit chunks
      int end = m_size-2;
      for (; i<end; i += 3)
      {
        int c = m_buf[i];
        int n = ((m_buf[i] & 0xff) << 16) + ((m_buf[i+1] & 0xff) << 8) + (m_buf[i+2] & 0xff);
        s.Append(base64chars[(n >> 18) & 0x3f]);
        s.Append(base64chars[(n >> 12) & 0x3f]);
        s.Append(base64chars[(n >> 6) & 0x3f]);
        s.Append(base64chars[n & 0x3f]);
      }

      // pad and encode remaining bits
      int rem = m_size - i;
      if (rem > 0)
      {
        int n = ((m_buf[i] & 0xff) << 10) | (rem == 2 ? ((m_buf[m_size-1] & 0xff) << 2) : 0);
        s.Append(base64chars[(n >> 12) & 0x3f]);
        s.Append(base64chars[(n >> 6) & 0x3f]);
        s.Append(rem == 2 ? base64chars[n & 0x3f] : '=');
        s.Append('=');
      }

      return s.ToString();
    }

    public override Buf toDigest(string algorithm)
    {
      string alg = algorithm;
      if (alg == "SHA-1") alg = "SHA1";  // to make .NET happy
      HashAlgorithm ha = HashAlgorithm.Create(alg);
      if (ha == null)
        throw ArgErr.make("Unknown digest algorthm: " + algorithm).val;
      return new MemBuf(ha.ComputeHash(m_buf, 0, m_size));
    }

    public override Buf hmac(string algorithm, Buf keyBuf)
    {
      // get digest algorthim
      string alg = algorithm;
      if (alg == "SHA-1") alg = "SHA1";  // to make .NET happy
      HashAlgorithm ha = HashAlgorithm.Create(alg);
      if (ha == null)
        throw ArgErr.make("Unknown digest algorthm: " + algorithm).val;

      // get secret key bytes
      int blockSize = 64;
      byte[] keyBytes = null;
      int keySize = 0;
      try
      {
        // get key bytes
        MemBuf keyMemBuf = (MemBuf)keyBuf;
        keyBytes = keyMemBuf.m_buf;
        keySize  = keyMemBuf.m_size;

        // key is greater than block size we hash it first
        if (keySize > blockSize)
        {
          keyBytes = ha.ComputeHash(keyBytes, 0, keySize);
          keySize = keyBytes.Length;
        }
      }
      catch (System.InvalidCastException)
      {
        throw UnsupportedErr.make("key parameter must be memory buffer").val;
      }

      // RFC 2104:
      //   ipad = the byte 0x36 repeated B times
      //   opad = the byte 0x5C repeated B times
      //   H(K XOR opad, H(K XOR ipad, text))

      MemBuf acc = new MemBuf(1024);

      // inner digest: H(K XOR ipad, text)
      for (int i=0; i<blockSize; ++i)
      {
        if (i < keySize)
          acc.write((byte)(keyBytes[i] ^ 0x36));
        else
          acc.write((byte)0x36);
      }
      acc.pipeFrom(m_buf, 0, m_size);
      byte[] innerDigest = ha.ComputeHash(acc.m_buf, 0, acc.m_size);

      // outer digest: H(K XOR opad, innerDigest)
      acc.clear();
      for (int i=0; i<blockSize; ++i)
      {
        if (i < keySize)
          acc.write((byte)(keyBytes[i] ^ 0x5C));
        else
          acc.write((byte)0x5C);
      }
      acc.pipeFrom(innerDigest, 0, innerDigest.Length);

      // return result
      return new MemBuf(ha.ComputeHash(acc.m_buf, 0, acc.m_size));
    }

  //////////////////////////////////////////////////////////////////////////
  // Buf Optimizations
  //////////////////////////////////////////////////////////////////////////

    /*
    TODO: does String(byte[], ...) perform better than InStream impl?
    public void eachLine(Func f)
    {
      try
      {
        byte[] buf = this.buf;
        int size   = this.size;
        String charset = in.charset.name.val;
        int s = pos;
        for (int i=pos; i<size; ++i)
        {
          int c = buf[i];
          if (c != '\n') continue;
          String str = new String(buf, s, i-s, charset);
          f.call(string.make(str));
          s = i+1;
        }
      }
      catch (Exception e)
      {
        throw Err.make(e).val;
      }
    }

    public string readAllStr(bool normalizeNewline )
    */

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public byte[] bytes()
    {
      byte[] r = new byte[m_size];
      System.Array.Copy(m_buf, 0, r, 0, m_size);
      return r;
    }

    public void grow(int capacity)
    {
      if (m_buf.Length >= capacity) return;
      byte[] temp = new byte[Math.Max(capacity, m_size*2)];
      System.Array.Copy(m_buf, 0, temp, 0, m_size);
      m_buf = temp;
    }

  //////////////////////////////////////////////////////////////////////////
  // MemBufOutStream
  //////////////////////////////////////////////////////////////////////////

    internal class MemBufOutStream : OutStream
    {
      internal MemBufOutStream(MemBuf parent) { this.p = parent; }
      private MemBuf p;

      public override sealed OutStream write(long v) { return w((int)v); }
      public override sealed OutStream w(int v)
      {
        if (p.m_pos+1 >= p.m_buf.Length) p.grow(p.m_pos+1);
        p.m_buf[p.m_pos++] = (byte)v;
        if (p.m_pos > p.m_size) p.m_size = p.m_pos;
        return this;
      }

      public override OutStream writeBuf(Buf other, long n)
      {
        int len = (int)n;
        p.grow(p.m_pos+len);
        other.pipeTo(p.m_buf, p.m_pos, len);
        p.m_pos += len;
        if (p.m_pos > p.m_size) p.m_size = p.m_pos;
        return this;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // MemBufInStream
  //////////////////////////////////////////////////////////////////////////

    internal class MemBufInStream : InStream
    {
      internal MemBufInStream(MemBuf parent) { this.p = parent; }
      private MemBuf p;

      public override Long read() { int n = r(); return n < 0 ? null : Long.valueOf(n); }
      public override int r()
      {
        if (p.m_pos >= p.m_size) return -1;
        return p.m_buf[p.m_pos++] & 0xFF;
      }

      public override Long readBuf(Buf other, long n)
      {
        if (p.m_pos >= p.m_size) return null;
        int len = Math.Min(p.m_size-p.m_pos, (int)n);
        other.pipeFrom(p.m_buf, p.m_pos, len);
        p.m_pos += len;
        return Long.valueOf(len);
      }

      public override InStream unread(long n) { return unread((int)n); }
      public override InStream unread(int n)
      {
        // unreading a buffer is a bit weird - the typical case
        // is that we are pushing back the byte we just read in
        // which case we can just rewind the position; however
        // if we pushing back a different byte then we need
        // to shift the entire buffer and insert the byte
        if (p.m_pos > 0 && p.m_buf[p.m_pos-1] == (byte)n)
        {
          p.m_pos--;
        }
        else
        {
          if (p.m_size+1 >= p.m_buf.Length) p.grow(p.m_size+1);
          System.Array.Copy(p.m_buf, p.m_pos, p.m_buf, p.m_pos+1, p.m_size);
          p.m_buf[p.m_pos] = (byte)n;
          p.m_size++;
        }
        return this;
      }

      public override Long peek()
      {
        if (p.m_pos >= p.m_size) return null;
        return Long.valueOf(p.m_buf[p.m_pos] & 0xFF);
      }

      public override long skip(long n)
      {
        int oldPos = p.m_pos;
        p.m_pos += (int)n;
        if (p.m_pos < p.m_size) return n;
        p.m_pos = p.m_size;
        return p.m_pos-oldPos;
      }

    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public byte[] m_buf;
    public int m_pos;
    public int m_size;

  }
}
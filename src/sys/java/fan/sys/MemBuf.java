//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Feb 08  Brian Frank  Split out from Buf
//
package fan.sys;

import java.io.*;
import java.nio.*;

/**
 * MemBuf
 */
public final class MemBuf
  extends Buf
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public MemBuf(int capacity)
  {
    this(new byte[capacity], 0);
  }

  public MemBuf(byte[] bytes)
  {
    this(bytes, bytes.length);
  }

  public MemBuf(byte[] bytes, int size)
  {
    this.buf  = bytes;
    this.pos  = 0;
    this.size = size;
    this.out  = new MemBufOutStream();
    this.in   = new MemBufInStream();
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.MemBufType; }

  public final Object toImmutable()
  {
    byte[] buf = this.buf;
    int size = this.size;
    this.buf = emptyBytes;
    this.size = 0;
    return new ConstBuf(buf, size);
  }

//////////////////////////////////////////////////////////////////////////
// Buf Support
//////////////////////////////////////////////////////////////////////////

  public final long size()
  {
    return size;
  }

  public final void size(long x)
  {
    int newSize = (int)x;
    if (newSize > buf.length)
    {
      byte[] temp = new byte[newSize];
      System.arraycopy(buf, 0, temp, 0, buf.length);
      buf  = temp;
    }
    size = newSize;
  }

  public final long pos()
  {
    return pos;
  }

  final void pos(long x)
  {
    this.pos = (int)x;
  }

  public final int getByte(long pos)
  {
    return buf[(int)pos] & 0xFF;
  }

  public final void setByte(long pos, int x)
  {
    buf[(int)pos] = (byte)x;
  }

  public final void getBytes(long pos, byte[] dest, int off, int len)
  {
    System.arraycopy(this.buf, (int)pos, dest, off, len);
  }

  public final void pipeTo(byte[] dst, int dstPos, int len)
  {
    if (pos + len > size) throw IOErr.make("Not enough bytes to write");
    System.arraycopy(buf, pos, dst, dstPos, len);
    pos += len;
  }

  public final void pipeTo(OutputStream dst, long lenLong)
    throws IOException
  {
    int len = (int)lenLong;
    if (pos + len > size) throw IOErr.make("Not enough bytes to write");
    dst.write(buf, pos, len);
    pos += len;
  }

  public final void pipeTo(RandomAccessFile dst, long lenLong)
    throws IOException
  {
    int len = (int)lenLong;
    if (pos + len > size) throw IOErr.make("Not enough bytes to write");
    dst.write(buf, pos, len);
    pos += len;
  }

  public final void pipeTo(ByteBuffer dst, int len)
  {
    if (pos + len > size) throw IOErr.make("Not enough bytes to write");
    dst.put(buf, pos, len);
    pos += len;
  }

  public final void pipeFrom(byte[] src, int srcPos, int len)
  {
    grow(pos+len);
    System.arraycopy(src, srcPos, buf, pos, len);
    pos += len;
    size = pos;
  }

  public final long pipeFrom(InputStream src, long lenLong)
    throws IOException
  {
    int len = (int)lenLong;
    grow(pos+len);
    int read = src.read(buf, pos, len);
    if (read < 0) return -1;
    pos  += read;
    size = pos;
    return read;
  }

  public final long pipeFrom(RandomAccessFile src, long lenLong)
    throws IOException
  {
    int len = (int)lenLong;
    grow(pos+len);
    int read = src.read(buf, pos, len);
    if (read < 0) return -1;
    pos += read;
    size = pos;
    return read;
  }

  public final int pipeFrom(ByteBuffer src, int len)
  {
    grow(pos+len);
    src.get(buf, pos, len);
    pos += len;
    size = pos;
    return len;
  }

//////////////////////////////////////////////////////////////////////////
// Buf API
//////////////////////////////////////////////////////////////////////////

  public final long capacity()
  {
    return buf.length;
  }

  public final void capacity(long c)
  {
    int newCapacity = (int)c;
    if (newCapacity < size) throw ArgErr.make("capacity < size");
    byte[] temp = new byte[newCapacity];
    System.arraycopy(buf, 0, temp, 0, Math.min(size, newCapacity));
    buf = temp;
  }

  public Buf trim()
  {
    if (size == buf.length) return this;
    byte[] temp = new byte[size];
    System.arraycopy(buf, 0, temp, 0, size);
    this.buf = temp;
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public final byte[] bytes()
  {
    byte[] r = new byte[size];
    System.arraycopy(buf, 0, r, 0, size);
    return r;
  }

  public final void grow(int capacity)
  {
    if (buf.length >= capacity) return;
    byte[] temp = new byte[Math.max(capacity, size*2)];
    System.arraycopy(buf, 0, temp, 0, size);
    buf = temp;
  }

  public final int sz()
  {
    return this.size;
  }

  public final byte[] unsafeArray()
  {
    return this.buf;
  }

  public ByteBuffer toByteBuffer()
  {
    return ByteBuffer.wrap(buf, pos, size-pos);
  }

//////////////////////////////////////////////////////////////////////////
// MemBufOutStream
//////////////////////////////////////////////////////////////////////////

  class MemBufOutStream extends OutStream
  {
    public final OutStream write(long v) { return w((int)v); }
    public final OutStream w(int v)
    {
      if (pos+1 >= buf.length) grow(pos+1);
      buf[pos++] = (byte)v;
      if (pos > size) size = pos;
      return this;
    }

    public OutStream writeBuf(Buf other, long n)
    {
      int len = (int)n;
      grow(pos+len);
      other.pipeTo(buf, pos, len);
      pos += len;
      if (pos > size) size = pos;
      return this;
    }

    public OutStream writeChar(long c)
    {
      charsetEncoder.encode((char)c, this);
      return this;
    }

    public OutStream writeChar(char c)
    {
      charsetEncoder.encode(c, this);
      return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// MemBufInStream
//////////////////////////////////////////////////////////////////////////

  class MemBufInStream extends InStream
  {
    public Long read() { int n = r(); return n < 0 ? null : FanInt.pos[n]; }
    public int r()
    {
      if (pos >= size) return -1;
      return buf[pos++] & 0xFF;
    }

    public Long readBuf(Buf other, long n)
    {
      if (pos >= size) return null;
      int len = Math.min(size-pos, (int)n);
      other.pipeFrom(buf, pos, len);
      pos += len;
      return Long.valueOf(len);
    }

    public InStream unread(long n) { return unread((int)n); }
    public InStream unread(int n)
    {
      // unreading a buffer is a bit weird - the typical case
      // is that we are pushing back the byte we just read in
      // which case we can just rewind the position; however
      // if we pushing back a different byte then we need
      // to shift the entire buffer and insert the byte
      if (pos > 0 && buf[pos-1] == (byte)n)
      {
        pos--;
      }
      else
      {
        if (size+1 >= buf.length) grow(size+1);
        System.arraycopy(buf, pos, buf, pos+1, size);
        buf[pos] = (byte)n;
        size++;
      }
      return this;
    }

    public long avail()
    {
      return MemBuf.this.remaining();
    }

    public Long peek()
    {
      if (pos >= size) return null;
      return FanInt.pos[buf[pos] & 0xFF];
    }

    public long skip(long n)
    {
      int oldPos = pos;
      pos += n;
      if (pos < size) return n;
      pos = size;
      return pos-oldPos;
    }

  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static byte[] emptyBytes = new byte[0];

  public byte[] buf;
  public int pos;
  public int size;

}
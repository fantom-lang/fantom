//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Feb 08  Brian Frank  Creation
//
package fan.sys;

import java.io.*;
import java.security.*;
import java.nio.*;

/**
 * MmapBuf returned from File.mmap
 */
public class MmapBuf
  extends Buf
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  MmapBuf(File file, MappedByteBuffer mmap)
  {
    this.file = file;
    this.mmap = mmap;
    this.out  = new MmapBufOutStream();
    this.in   = new MmapBufInStream();
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.MmapBufType; }

//////////////////////////////////////////////////////////////////////////
// Buf Support
//////////////////////////////////////////////////////////////////////////

  public final long size()
  {
    return mmap.limit();
  }

  public final void size(long x)
  {
    mmap.limit((int)x);
  }

  public final long pos()
  {
    return mmap.position();
  }

  final void pos(long x)
  {
    mmap.position((int)x);
  }

  public final int getByte(long pos)
  {
    return mmap.get((int)pos) & 0xff;
  }

  public final void setByte(long pos, int x)
  {
    mmap.put((int)pos, (byte)x);
  }

  public final void getBytes(long pos, byte[] dst, int off, int len)
  {
    int oldPos = mmap.position();
    mmap.position((int)pos);
    mmap.get(dst, off, len);
    mmap.position(oldPos);
  }

  public final void pipeTo(byte[] dst, int dstPos, int len)
  {
    mmap.get(dst, dstPos, len);
  }

  public final void pipeTo(OutputStream dst, long lenLong)
    throws IOException
  {
    byte[] temp = temp();
    int len = (int)lenLong;
    int total = 0;
    while (total < len)
    {
      int n = Math.min(temp.length, len-total);
      mmap.get(temp, 0, n);
      dst.write(temp, 0, n);
      total += n;
    }
  }

  public final void pipeTo(RandomAccessFile dst, long lenLong)
    throws IOException
  {
    byte[] temp = temp();
    int len = (int)lenLong;
    int total = 0;
    while (total < len)
    {
      int n = Math.min(temp.length, len-total);
      mmap.get(temp, 0, n);
      dst.write(temp, 0, n);
      total += n;
    }
  }

  public final void pipeTo(ByteBuffer dst, int len)
  {
    pipe(mmap, dst, len);
  }

  void pipe(ByteBuffer src, ByteBuffer dst, int len)
  {
    // NIO has one lame method for bulk transfer
    // and it doesn't let us pass in a length
    byte[] temp = temp();
    int total = 0;
    while (total < len)
    {
      int n = Math.min(temp.length, len-total);
      src.get(temp, 0, n);
      dst.put(temp, 0, n);
      total += n;
    }
  }

  public final void pipeFrom(byte[] src, int srcPos, int len)
  {
    mmap.put(src, srcPos, len);
  }

  public final long pipeFrom(InputStream src, long lenLong)
    throws IOException
  {
    byte[] temp = temp();
    int len = (int)lenLong;
    int total = 0;
    while (total < len)
    {
      int n = src.read(temp, 0, Math.min(temp.length, len-total));
      if (n < 0) return total == 0 ? -1 : total;
      mmap.put(temp, 0, n);
      total += n;
    }
    return total;
  }

  public final long pipeFrom(RandomAccessFile src, long lenLong)
    throws IOException
  {
    byte[] temp = temp();
    int len = (int)lenLong;
    int total = 0;
    while (total < len)
    {
      int n = src.read(temp, 0, Math.min(temp.length, len-total));
      if (n < 0) return total == 0 ? -1 : total;
      mmap.put(temp, 0, n);
      total += n;
    }
    return total;
  }

  public final int pipeFrom(ByteBuffer src, int len)
  {
    pipe(src, mmap, len);
    return len;
  }

//////////////////////////////////////////////////////////////////////////
// Buf API
//////////////////////////////////////////////////////////////////////////

  public long capacity()
  {
    return size();
  }

  public void capacity(long x)
  {
    throw UnsupportedErr.make("mmap capacity fixed");
  }

  public final Buf flush()
  {
    mmap.force();
    return this;
  }

  public final boolean close()
  {
    // Java doesn't support closing mmap
    return true;
  }

  public final String toHex()
  {
    throw UnsupportedErr.make();
  }

  public Buf toDigest(String algorithm)
  {
    throw UnsupportedErr.make();
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  final byte[] temp()
  {
    if (temp == null) temp = new byte[1024];
    return temp;
  }

//////////////////////////////////////////////////////////////////////////
// MmapBufOutStream
//////////////////////////////////////////////////////////////////////////

  class MmapBufOutStream extends OutStream
  {
    public final OutStream write(long v) { return w((int)v); }
    public final OutStream w(int v)
    {
      mmap.put((byte)v);
      return this;
    }

    public OutStream writeBuf(Buf other, long n)
    {
      other.pipeTo(mmap, (int)n);
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

    public OutStream flush()
    {
      MmapBuf.this.flush();
      return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// MmapBufInStream
//////////////////////////////////////////////////////////////////////////

  class MmapBufInStream extends InStream
  {
    public Long read() { int n = r(); return n < 0 ? null : FanInt.pos[n]; }
    public int r()
    {
      if (mmap.remaining() <= 0) return -1;
      return mmap.get() & 0xff;
    }

    public Long readBuf(Buf other, long n)
    {
      int left = mmap.remaining();
      if (left <= 0) return null;
      if (left < n) n = left;
      int read = other.pipeFrom(mmap, (int)n);
      if (read < 0) return null;
      return Long.valueOf(read);
    }

    public InStream unread(long n) { return unread((int)n); }
    public InStream unread(int n)
    {
      mmap.put(mmap.position()-1, (byte)n);
      return this;
    }

    public Long peek()
    {
      return FanInt.pos[mmap.get(mmap.position())];
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private File file;
  private MappedByteBuffer mmap;
  private byte[] temp;

}
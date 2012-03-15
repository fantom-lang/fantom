//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Feb 08  Brian Frank  Creation
//   09 Mar 12  Brian Frank  MmapBuf => NioBuf
//
package fan.sys;

import java.io.*;
import java.security.*;
import java.nio.*;

/**
 * NioBuf used for File.mmap
 */
public class NioBuf
  extends Buf
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public NioBuf(ByteBuffer buf)
  {
    this.buf  = buf;
    this.out  = new NioBufOutStream();
    this.in   = new NioBufInStream();
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.NioBufType; }

//////////////////////////////////////////////////////////////////////////
// Buf Support
//////////////////////////////////////////////////////////////////////////

  public final long size()
  {
    return buf.limit();
  }

  public final void size(long x)
  {
    buf.limit((int)x);
  }

  public final long pos()
  {
    return buf.position();
  }

  final void pos(long x)
  {
    buf.position((int)x);
  }

  public final int getByte(long pos)
  {
    return buf.get((int)pos) & 0xff;
  }

  public final void setByte(long pos, int x)
  {
    buf.put((int)pos, (byte)x);
  }

  public final void getBytes(long pos, byte[] dst, int off, int len)
  {
    int oldPos = buf.position();
    buf.position((int)pos);
    buf.get(dst, off, len);
    buf.position(oldPos);
  }

  public final void pipeTo(byte[] dst, int dstPos, int len)
  {
    buf.get(dst, dstPos, len);
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
      buf.get(temp, 0, n);
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
      buf.get(temp, 0, n);
      dst.write(temp, 0, n);
      total += n;
    }
  }

  public final void pipeTo(ByteBuffer dst, int len)
  {
    pipe(buf, dst, len);
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
    buf.put(src, srcPos, len);
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
      buf.put(temp, 0, n);
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
      buf.put(temp, 0, n);
      total += n;
    }
    return total;
  }

  public final int pipeFrom(ByteBuffer src, int len)
  {
    pipe(src, buf, len);
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

  public Buf flush()
  {
    if (buf instanceof MappedByteBuffer)
      ((MappedByteBuffer)buf).force();
    return this;
  }

  public boolean close()
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

  public ByteBuffer toByteBuffer()
  {
    return buf.duplicate();
  }

//////////////////////////////////////////////////////////////////////////
// NioBufOutStream
//////////////////////////////////////////////////////////////////////////

  class NioBufOutStream extends OutStream
  {
    public final OutStream write(long v) { return w((int)v); }
    public final OutStream w(int v)
    {
      buf.put((byte)v);
      return this;
    }

    public OutStream writeBuf(Buf other, long n)
    {
      other.pipeTo(buf, (int)n);
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
      NioBuf.this.flush();
      return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// NioBufInStream
//////////////////////////////////////////////////////////////////////////

  class NioBufInStream extends InStream
  {
    public Long read() { int n = r(); return n < 0 ? null : FanInt.pos[n]; }
    public int r()
    {
      if (buf.remaining() <= 0) return -1;
      return buf.get() & 0xff;
    }

    public Long readBuf(Buf other, long n)
    {
      int left = buf.remaining();
      if (left <= 0) return null;
      if (left < n) n = left;
      int read = other.pipeFrom(buf, (int)n);
      if (read < 0) return null;
      return Long.valueOf(read);
    }

    public InStream unread(long n) { return unread((int)n); }
    public InStream unread(int n)
    {
      buf.put(buf.position()-1, (byte)n);
      return this;
    }

    public Long peek()
    {
      return FanInt.pos[buf.get(buf.position())];
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private ByteBuffer buf;
  private byte[] temp;

}
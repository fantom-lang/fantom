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

  public Type type() { return Sys.MmapBufType; }

//////////////////////////////////////////////////////////////////////////
// Buf Support
//////////////////////////////////////////////////////////////////////////

  final long getSize()
  {
    return mmap.limit();
  }

  final void setSize(long x)
  {
    mmap.limit((int)x);
  }

  final long getPos()
  {
    return mmap.position();
  }

  final void setPos(long x)
  {
    mmap.position((int)x);
  }

  final int getByte(long pos)
  {
    return mmap.get((int)pos) & 0xff;
  }

  final void setByte(long pos, int x)
  {
    mmap.put((int)pos, (byte)x);
  }

  final void getBytes(long pos, byte[] dst, int off, int len)
  {
    int oldPos = mmap.position();
    mmap.position((int)pos);
    mmap.get(dst, off, len);
    mmap.position(oldPos);
  }

  final void pipeTo(byte[] dst, int dstPos, int len)
  {
    mmap.get(dst, dstPos, len);
  }

  final void pipeTo(OutputStream dst, long lenLong)
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

  final void pipeTo(RandomAccessFile dst, long lenLong)
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

  final void pipeTo(ByteBuffer dst, int len)
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

  final void pipeFrom(byte[] src, int srcPos, int len)
  {
    mmap.put(src, srcPos, len);
  }

  final long pipeFrom(InputStream src, long lenLong)
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

  final long pipeFrom(RandomAccessFile src, long lenLong)
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

  final int pipeFrom(ByteBuffer src, int len)
  {
    pipe(src, mmap, len);
    return len;
  }

//////////////////////////////////////////////////////////////////////////
// Buf API
//////////////////////////////////////////////////////////////////////////

  public Long capacity()
  {
    return size();
  }

  public void capacity(Long x)
  {
    throw UnsupportedErr.make("mmap capacity fixed").val;
  }

  public final Buf flush()
  {
    mmap.force();
    return this;
  }

  public final Boolean close()
  {
    // Java doesn't support closing mmap
    return true;
  }

  public final Str toHex()
  {
    throw UnsupportedErr.make().val;
  }

  public Buf toDigest(Str algorithm)
  {
    throw UnsupportedErr.make().val;
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
    public final OutStream write(Long v) { return w(v.intValue()); }
    public final OutStream w(int v)
    {
      mmap.put((byte)v);
      return this;
    }

    public OutStream writeBuf(Buf other, Long n)
    {
      other.pipeTo(mmap, n.intValue());
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
      return mmap.get() & 0xff;
    }

    public Long readBuf(Buf other, Long n)
    {
      int read = other.pipeFrom(mmap, n.intValue());
      if (read < 0) return null;
      return Long.valueOf(read);
    }

    public InStream unread(Long n) { return unread(n.intValue()); }
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

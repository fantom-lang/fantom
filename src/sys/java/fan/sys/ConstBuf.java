//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Nov 15  Brian Frank  Creation
//
package fan.sys;

import java.io.*;
import java.nio.*;

/**
 * ConstBuf
 */
public final class ConstBuf
  extends Buf
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public ConstBuf(byte[] bytes, int off, int size)
  {
    this.buf  = bytes;
    this.off  = off;
    this.size = size;
  }

  public ConstBuf(byte[] bytes)
  {
    this(bytes, 0, bytes.length);
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public final Type typeof() { return Sys.ConstBufType; }

  public final boolean isImmutable() { return true; }

  public final Object toImmutable() { return this; }

//////////////////////////////////////////////////////////////////////////
// Buf Support
//////////////////////////////////////////////////////////////////////////

  public InStream in()
  {
    return new ConstBufInStream(buf, off, size);
  }

  public final long size()
  {
    return size;
  }

  public final void size(long x)
  {
    throw err();
  }

  public final long pos()
  {
    return 0;
  }

  final void pos(long x)
  {
    if (x != 0) throw err();
  }

  public final int getByte(long pos)
  {
    return buf[off+(int)pos] & 0xFF;
  }

  public final void setByte(long pos, int x)
  {
    throw err();
  }

  public final void getBytes(long pos, byte[] dst, int dstOff, int len)
  {
    System.arraycopy(this.buf, this.off+(int)pos, dst, dstOff, len);
  }

  public final void pipeTo(byte[] dst, int dstPos, int len)
  {
    if (len > size) throw IOErr.make("Not enough bytes to write");
    System.arraycopy(buf, off, dst, dstPos, len);
  }

  public final void pipeTo(OutputStream dst, long lenLong)
    throws IOException
  {
    int len = (int)lenLong;
    if (len > size) throw IOErr.make("Not enough bytes to write");
    dst.write(buf, off, len);
  }

  public final void pipeTo(RandomAccessFile dst, long lenLong)
    throws IOException
  {
    int len = (int)lenLong;
    if (len > size) throw IOErr.make("Not enough bytes to write");
    dst.write(buf, off, len);
  }

  public final void pipeTo(ByteBuffer dst, int len)
  {
    if (len > size) throw IOErr.make("Not enough bytes to write");
    dst.put(buf, off, len);
  }

  public final void pipeFrom(byte[] src, int srcPos, int len)
  {
    throw err();
  }

  public final long pipeFrom(InputStream src, long lenLong)
    throws IOException
  {
    throw err();
  }

  public final long pipeFrom(RandomAccessFile src, long lenLong)
    throws IOException
  {
    throw err();
  }

  public final int pipeFrom(ByteBuffer src, int len)
  {
    throw err();
  }

//////////////////////////////////////////////////////////////////////////
// Buf API
//////////////////////////////////////////////////////////////////////////

  public final long capacity() { throw err(); }

  public final void capacity(long c) { throw err(); }

  public final Buf sync() { throw err(); }

  public final Buf trim() { throw err(); }

  public Endian endian() { return Endian.big; }

  public void endian(Endian endian) { throw err(); }

  public Charset charset() { return Charset.utf8(); }

  public void charset(Charset charset) { throw err(); }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public final InStream i() { throw err(); }

  public final OutStream o() { throw err(); }

  public final byte[] constArray()
  {
    if (buf.length == size) return buf;
    return safeArray();
  }

  public final byte[] unsafeArray()
  {
    return buf;
  }

  public final int unsafeOffset()
  {
    return off;
  }

  public int sz()
  {
    return this.size;
  }

  public final ByteBuffer toByteBuffer()
  {
    return ByteBuffer.wrap(safeArray());
  }

  static final Err err()
  {
    return ReadonlyErr.make("Buf is immutable");
  }

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

  public File toFile(Uri uri)
  {
    return new MemFile(this, uri);
  }

  static class MemFile extends File
  {
    MemFile(ConstBuf buf, Uri uri) { super(uri); this.buf = buf; this.ts = DateTime.now(); }
    public Type typeof() { return Sys.MemFileType; }
    public boolean exists() { return true; }
    public Long size() { return Long.valueOf(buf.size); }
    public DateTime modified() { return ts; }
    public void modified(DateTime time) { throw err(); }
    public String osPath() { return null; }
    public File parent() { return null; }
    public List list(Regex pattern) { return new List(Sys.FileType, 0); }
    public File normalize() { return this; }
    public File plus(Uri uri, boolean checkSlash) { throw err(); }
    public File create() { throw err(); }
    public File moveTo(File to) { throw err(); }
    public void delete() { throw err(); }
    public File deleteOnExit() { throw err(); }
    public Buf open(String mode) { throw err(); }
    public Buf mmap(String mode, long pos, Long size) { throw err(); }
    public InStream in(Long bufSize) { return buf.in(); }
    public OutStream out(boolean append, Long bufSize) { throw err(); }
    Err err() { return UnsupportedErr.make("ConstBufFile"); }
    final ConstBuf buf;
    final DateTime ts;
  }

//////////////////////////////////////////////////////////////////////////
// ConstBufInStream
//////////////////////////////////////////////////////////////////////////

  static class ConstBufInStream extends InStream
  {
    ConstBufInStream(byte[] buf, int off, int size)
    {
      this.buf  = buf;
      this.off  = off;
      this.size = size;
    }

    public Long read() { int n = r(); return n < 0 ? null : FanInt.pos[n]; }
    public int r()
    {
      if (numRead >= size) return -1;
      return buf[off+(numRead++)] & 0xFF;
    }

    public Long readBuf(Buf other, long n)
    {
      if (numRead >= size) return null;
      int len = Math.min(size-numRead, (int)n);
      other.pipeFrom(buf, off+numRead, len);
      numRead += len;
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
      if (numRead > 0 && buf[off+numRead-1] == (byte)n)
      {
        numRead--;
      }
      else
      {
        throw err();
      }
      return this;
    }

    public Long peek()
    {
      if (numRead >= size) return null;
      return FanInt.pos[buf[off+numRead] & 0xFF];
    }

    public long skip(long n)
    {
      int oldNumRead = numRead;
      numRead += n;
      if (numRead < size) return n;
      numRead = size;
      return numRead-oldNumRead;
    }

    private final byte[] buf;
    private final int off;
    private final int size;
    private int numRead;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final byte[] buf;
  final int off;
  final int size;

}
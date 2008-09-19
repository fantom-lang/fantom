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
import java.security.*;

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

  public Type type() { return Sys.MemBufType; }

//////////////////////////////////////////////////////////////////////////
// Buf Support
//////////////////////////////////////////////////////////////////////////

  final long getSize()
  {
    return size;
  }

  final void setSize(long x)
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

  final long getPos()
  {
    return pos;
  }

  final void setPos(long x)
  {
    this.pos = (int)x;
  }

  final int getByte(long pos)
  {
    return buf[(int)pos] & 0xFF;
  }

  final void setByte(long pos, int x)
  {
    buf[(int)pos] = (byte)x;
  }

  final void getBytes(long pos, byte[] dest, int off, int len)
  {
    System.arraycopy(this.buf, (int)pos, dest, off, len);
  }

  final void pipeTo(byte[] dst, int dstPos, int len)
  {
    if (pos + len > size) throw IOErr.make("Not enough bytes to write").val;
    System.arraycopy(buf, pos, dst, dstPos, len);
    pos += len;
  }

  final void pipeTo(OutputStream dst, long lenLong)
    throws IOException
  {
    int len = (int)lenLong;
    if (pos + len > size) throw IOErr.make("Not enough bytes to write").val;
    dst.write(buf, pos, len);
    pos += len;
  }

  final void pipeTo(RandomAccessFile dst, long lenLong)
    throws IOException
  {
    int len = (int)lenLong;
    if (pos + len > size) throw IOErr.make("Not enough bytes to write").val;
    dst.write(buf, pos, len);
    pos += len;
  }

  final void pipeTo(ByteBuffer dst, int len)
  {
    if (pos + len > size) throw IOErr.make("Not enough bytes to write").val;
    dst.put(buf, pos, len);
    pos += len;
  }

  final void pipeFrom(byte[] src, int srcPos, int len)
  {
    grow(pos+len);
    System.arraycopy(src, srcPos, buf, pos, len);
    pos += len;
    size = pos;
  }

  final long pipeFrom(InputStream src, long lenLong)
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

  final long pipeFrom(RandomAccessFile src, long lenLong)
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

  final int pipeFrom(ByteBuffer src, int len)
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

  public final Int capacity()
  {
    return Int.pos(buf.length);
  }

  public final void capacity(Int c)
  {
    int newCapacity = (int)c.val;
    if (newCapacity < size) throw ArgErr.make("capacity < size").val;
    byte[] temp = new byte[newCapacity];
    System.arraycopy(buf, 0, temp, 0, newCapacity);
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

  public Str toHex()
  {
    byte[] buf = this.buf;
    int size = this.size;
    char[] hexChars = Buf.hexChars;
    StringBuilder s = new StringBuilder(size*2);
    for (int i=0; i<size; ++i)
    {
      int b = buf[i] & 0xFF;
      s.append(hexChars[b>>4]).append(hexChars[b&0xf]);
    }
    return Str.make(s.toString());
  }

  public Str toBase64()
  {
    byte[] buf = this.buf;
    int size = this.size;
    StringBuilder s = new StringBuilder(size*2);
    char[] base64chars = Buf.base64chars;
    int i = 0;

    // append full 24-bit chunks
    int end = size-2;
    for (; i<end; i += 3)
    {
      int n = ((buf[i] & 0xff) << 16) + ((buf[i+1] & 0xff) << 8) + (buf[i+2] & 0xff);
      s.append(base64chars[(n >>> 18) & 0x3f]);
      s.append(base64chars[(n >>> 12) & 0x3f]);
      s.append(base64chars[(n >>> 6) & 0x3f]);
      s.append(base64chars[n & 0x3f]);
    }

    // pad and encode remaining bits
    int rem = size - i;
    if (rem > 0)
    {
      int n = ((buf[i] & 0xff) << 10) | (rem == 2 ? ((buf[size-1] & 0xff) << 2) : 0);
      s.append(base64chars[(n >>> 12) & 0x3f]);
      s.append(base64chars[(n >>> 6) & 0x3f]);
      s.append(rem == 2 ? base64chars[n & 0x3f] : '=');
      s.append('=');
    }

    return Str.make(s.toString());
  }

  public Buf toDigest(Str algorithm)
  {
    try
    {
      MessageDigest md = MessageDigest.getInstance(algorithm.val);
      md.update(buf, 0, size);
      return new MemBuf(md.digest());
    }
    catch (NoSuchAlgorithmException e)
    {
      throw ArgErr.make("Unknown digest algorthm: " + algorithm.val).val;
    }
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
        f.call1(Str.make(str));
        s = i+1;
      }
    }
    catch (Exception e)
    {
      throw Err.make(e).val;
    }
  }

  public Str readAllStr(Bool normalizeNewline )
  */

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

//////////////////////////////////////////////////////////////////////////
// MemBufOutStream
//////////////////////////////////////////////////////////////////////////

  class MemBufOutStream extends OutStream
  {
    public final OutStream write(Int v) { return w((int)v.val); }
    public final OutStream w(int v)
    {
      if (pos+1 >= buf.length) grow(pos+1);
      buf[pos++] = (byte)v;
      if (pos > size) size = pos;
      return this;
    }

    public OutStream writeBuf(Buf other, Int n)
    {
      int len = (int)n.val;
      grow(pos+len);
      other.pipeTo(buf, pos, len);
      pos += len;
      if (pos > size) size = pos;
      return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// MemBufInStream
//////////////////////////////////////////////////////////////////////////

  class MemBufInStream extends InStream
  {
    public Int read() { int n = r(); return n < 0 ? null : Int.pos[n]; }
    public int r()
    {
      if (pos >= size) return -1;
      return buf[pos++] & 0xFF;
    }

    public Int readBuf(Buf other, Int n)
    {
      if (pos >= size) return null;
      int len = Math.min(size-pos, (int)n.val);
      other.pipeFrom(buf, pos, len);
      pos += len;
      return Int.pos(len);
    }

    public InStream unread(Int n) { return unread((int)n.val); }
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

    public Int peek()
    {
      if (pos >= size) return null;
      return Int.pos[buf[pos] & 0xFF];
    }

    public Int skip(Int n)
    {
      int oldPos = pos;
      pos += n.val;
      if (pos < size) return n;
      pos = size;
      return Int.pos(pos-oldPos);
    }

  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public byte[] buf;
  public int pos;
  public int size;

}

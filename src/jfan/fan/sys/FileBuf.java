//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Feb 08  Brian Frank  Creation
//
package fan.sys;

import java.io.*;
import java.nio.*;
import java.security.*;

/**
 * FileBuf returned from File.open
 */
public class FileBuf
  extends Buf
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  FileBuf(File file, RandomAccessFile fp)
  {
    this.file = file;
    this.fp   = fp;
    this.out  = new FileBufOutStream();
    this.in   = new FileBufInStream();
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.FileBufType; }

//////////////////////////////////////////////////////////////////////////
// Buf Support
//////////////////////////////////////////////////////////////////////////

  final long getSize()
  {
    try
    {
      return fp.length();
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  final void setSize(long x)
  {
    try
    {
      fp.setLength(x);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  final long getPos()
  {
    try
    {
      return fp.getFilePointer();
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  final void setPos(long x)
  {
    try
    {
      fp.seek(x);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  final int getByte(long pos)
  {
    try
    {
      long oldPos = fp.getFilePointer();
      fp.seek(pos);
      int b = fp.read();
      fp.seek(oldPos);
      return b;
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  final void setByte(long pos, int x)
  {
    try
    {
      long oldPos = fp.getFilePointer();
      fp.seek(pos);
      fp.write(x);
      fp.seek(oldPos);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  final void getBytes(long pos, byte[] dst, int off, int len)
  {
    try
    {
      fp.seek(pos);
      fp.read(dst, off, len);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  final void pipeTo(byte[] dst, int dstPos, int len)
  {
    try
    {
      fp.read(dst, dstPos, len);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  final void pipeTo(OutputStream dst, long len)
    throws IOException
  {
    byte[] temp = temp();
    long total = 0;
    while (total < len)
    {
      int n = fp.read(temp, 0, (int)Math.min(temp.length, len-total));
      dst.write(temp, 0, n);
      total += n;
    }
  }

  final void pipeTo(RandomAccessFile dst, long len)
    throws IOException
  {
    byte[] temp = temp();
    long total = 0;
    while (total < len)
    {
      int n = fp.read(temp, 0, (int)Math.min(temp.length, len-total));
      dst.write(temp, 0, n);
      total += n;
    }
  }

  final void pipeTo(ByteBuffer dst, int len)
  {
    try
    {
      byte[] temp = temp();
      int total = 0;
      while (total < len)
      {
        int n = fp.read(temp, 0, Math.min(temp.length, len-total));
        dst.put(temp, 0, n);
        total += n;
      }
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  final void pipeFrom(byte[] src, int srcPos, int len)
  {
    try
    {
      fp.write(src, srcPos, len);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  final long pipeFrom(InputStream src, long len)
    throws IOException
  {
    byte[] temp = temp();
    long total = 0;
    while (total < len)
    {
      int n = src.read(temp, 0, (int)Math.min(temp.length, len-total));
      if (n < 0) return total == 0 ? -1 : total;
      fp.write(temp, 0, n);
      total += n;
    }
    return total;
  }

  final long pipeFrom(RandomAccessFile src, long len)
    throws IOException
  {
    byte[] temp = temp();
    long total = 0;
    while (total < len)
    {
      int n = src.read(temp, 0, (int)Math.min(temp.length, len-total));
      if (n < 0) return total == 0 ? -1 : total;
      fp.write(temp, 0, n);
      total += n;
    }
    return total;
  }

  final int pipeFrom(ByteBuffer src, int len)
  {
    try
    {
      byte[] temp = temp();
      int total = 0;
      while (total < len)
      {
        int n = Math.min(temp.length, len-total);
        src.get(temp, 0, n);
        fp.write(temp, 0, n);
        total += n;
      }
      return total;
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Buf API
//////////////////////////////////////////////////////////////////////////

  public final Buf flush()
  {
    try
    {
      fp.getFD().sync();
      return this;
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public final boolean close()
  {
    try
    {
      fp.close();
      return true;
    }
    catch (Exception e)
    {
      return false;
    }
  }

  public final String toHex()
  {
    try
    {
      long oldPos = getPos();
      int size = (int)getSize();
      byte[] temp = temp();
      char[] hexChars = Buf.hexChars;
      StringBuilder s = new StringBuilder(size*2);

      setPos(0);
      int total = 0;
      while (total < size)
      {
        int n = fp.read(temp, 0, Math.min(temp.length, size-total));
        for (int i=0; i<n; ++i)
        {
          int b = temp[i] & 0xFF;
          s.append(hexChars[b>>4]).append(hexChars[b&0xf]);
        }
        total += n;
      }

      setPos(oldPos);
      return s.toString();
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public Buf toDigest(String algorithm)
  {
    try
    {
      long oldPos = getPos();
      long size = getSize();
      byte[] temp = temp();
      MessageDigest md = MessageDigest.getInstance(algorithm);

      setPos(0);
      long total = 0;
      while (total < size)
      {
        int n = fp.read(temp, 0, (int)Math.min(temp.length, (int)size-total));
        md.update(temp, 0, n);
        total += n;
      }

      setPos(oldPos);
      return new MemBuf(md.digest());
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
    catch (NoSuchAlgorithmException e)
    {
      throw ArgErr.make("Unknown digest algorthm: " + algorithm).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  final byte[] temp()
  {
    byte[] temp = this.temp;
    if (temp == null) temp = this.temp = new byte[1024];
    return temp;
  }

//////////////////////////////////////////////////////////////////////////
// FileBufOutStream
//////////////////////////////////////////////////////////////////////////

  class FileBufOutStream extends OutStream
  {
    public final OutStream write(Long v) { return w(v.intValue()); }
    public final OutStream w(int v)
    {
      try
      {
        fp.write(v);
        return this;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public OutStream writeBuf(Buf other, Long n)
    {
      try
      {
        other.pipeTo(fp, n.longValue());
        return this;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public OutStream flush()
    {
      FileBuf.this.flush();
      return this;
    }
  }

//////////////////////////////////////////////////////////////////////////
// FileBufInStream
//////////////////////////////////////////////////////////////////////////

  class FileBufInStream extends InStream
  {
    public Long read() { int n = r(); return n < 0 ? null : FanInt.pos[n]; }
    public int r()
    {
      try
      {
        return fp.read();
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public Long readBuf(Buf other, Long n)
    {
      try
      {
        long read = other.pipeFrom(fp, n.longValue());
        if (read < 0) return null;
        return Long.valueOf(read);
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public InStream unread(Long n) { return unread(n.intValue()); }
    public InStream unread(int n)
    {
      try
      {
        long pos = getPos();
        fp.seek(pos-1);
        fp.write(n);
        fp.seek(pos-1);
        return this;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public Long peek()
    {
      try
      {
        long pos = getPos();
        int n = fp.read();
        setPos(pos);
        return n < 0 ? null : FanInt.pos[n];
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private File file;
  private RandomAccessFile fp;
  private byte[] temp;

}

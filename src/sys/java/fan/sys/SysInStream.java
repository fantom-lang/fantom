//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Mar 06  Brian Frank  Creation
//
package fan.sys;

import java.io.*;

/**
 * SysInStream implements InStream using a java.io.InputStream
 */
public class SysInStream
  extends InStream
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public static SysInStream make(java.io.InputStream in, Long bufSize)
  {
    if (bufSize == null || bufSize.longValue() == 0)
      return new SysInStream(in);
    else
      return new SysInStream(new java.io.BufferedInputStream(in, bufSize.intValue()));
  }

  public SysInStream(InputStream in)
  {
    this.in = in;
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.SysInStreamType; }

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

  public long avail()
  {
    try
    {
      return in.available();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public Long read() { int n = r(); return n < 0 ? null : FanInt.pos[n]; }
  public int r()
  {
    try
    {
      return in.read();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  /**
   * Bulk read the remaining bytes and decode them in one pass
   */
  public String readAllStr(boolean normalizeNewlines)
  {
    try
    {
      MemBuf buf = readAllBytes();
      String s = charsetDecoder.decodeAll(buf.buf, buf.size);
      if (normalizeNewlines && s.indexOf('\r') >= 0) s = s.replace("\r\n", "\n").replace('\r', '\n');
      return s;
    }
    finally
    {
      try { close(); } catch (Exception e) { e.printStackTrace(); }
    }
  }

  /**
   * Read remaining bytes, sized by available() so a file fits in one read
   */
  private MemBuf readAllBytes()
  {
    try
    {
      byte[] buf = new byte[Math.max(in.available() + 1, 1024)];
      int size = 0;
      while (true)
      {
        if (size == buf.length) buf = java.util.Arrays.copyOf(buf, size * 2);
        int n = in.read(buf, size, buf.length - size);
        if (n < 0) break;
        size += n;
      }
      return new MemBuf(buf, size);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public Long readBuf(Buf buf, long n)
  {
    try
    {
      long read = buf.pipeFrom(in, n);
      if (read < 0) return null;
      return Long.valueOf(read);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public InStream unread(long n) { return unread((int)n); }
  public InStream unread(int n)
  {
    try
    {
      // don't take the hit until we know we need to wrap
      // the raw input stream with a pushback stream
      if (!(in instanceof PushbackInputStream))
        in = new PushbackInputStream(in, 128);
      ((PushbackInputStream)in).unread(n);
      return this;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public long skip(long n)
  {
    try
    {
      long skipped = 0;
      while (skipped < n)
      {
        long x = in.skip(n-skipped);
        if (x < 0) break;
        skipped += x;
      }
      return skipped;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public boolean close()
  {
    try
    {
      if (in != null) in.close();
      return true;
    }
    catch (IOException e)
    {
      return false;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Java Conversion
//////////////////////////////////////////////////////////////////////////

  /**
   * Get a java.io.InputStream for the specified input stream.
   */
  public static InputStream java(InStream in)
  {
    if (in instanceof SysInStream)
      return ((SysInStream)in).in;
    else
      return new JavaInputStream(in);
  }

  static class JavaInputStream extends InputStream
  {
    JavaInputStream(InStream in) { this.in = in; }

    public int read()
    {
      return in.r();
    }

    public int read(byte[] b, int off, int len)
    {
      buf.buf = b;
      buf.pos = off;
      buf.size = b.length;
      Long n = in.readBuf(buf, len);
      buf.buf = null;
      if (n == null) return -1;
      return n.intValue();
    }

    public void close() { in.close(); }

    InStream in;
    MemBuf buf = new MemBuf(null, 0);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  InputStream in;

}


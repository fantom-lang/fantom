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
 * SysInStream
 */
public class SysInStream
  extends InStream
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public static SysInStream make(java.io.InputStream in, Int bufSize)
  {
    if (bufSize == null || bufSize.val == 0)
      return new SysInStream(in);
    else
      return new SysInStream(new java.io.BufferedInputStream(in, (int)bufSize.val));
  }

  public SysInStream(InputStream in)
  {
    this.in = in;
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.SysInStreamType; }

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

  public Int read() { int n = r(); return n < 0 ? null : Int.pos[n]; }
  public int r()
  {
    try
    {
      return in.read();
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public Int readBuf(Buf buf, Int n)
  {
    try
    {
      long read = buf.pipeFrom(in, n.val);
      if (read < 0) return null;
      return Int.pos(read);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public InStream unread(Int n) { return unread((int)n.val); }
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
      throw IOErr.make(e).val;
    }
  }

  public Int skip(Int n)
  {
    try
    {
      long skipped = in.skip(n.val);
      if (skipped < 0) return Int.Zero;
      return Int.pos(skipped);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public Bool close()
  {
    try
    {
      if (in != null) in.close();
      return Bool.True;
    }
    catch (IOException e)
    {
      return Bool.False;
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
      Int n = in.readBuf(buf, Int.make(len));
      buf.buf = null;
      if (n == null) return -1;
      return (int)n.val;
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

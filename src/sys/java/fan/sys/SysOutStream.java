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
 * SysOutStream is an Fantom sys::OutStream which
 * routes to a java.io.OutputStream.
 */
public class SysOutStream
  extends OutStream
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public static SysOutStream make(java.io.OutputStream out, Long bufSize)
  {
    return new SysOutStream(toBuffered(out, bufSize));
  }

  public static OutputStream toBuffered(java.io.OutputStream out, Long bufSize)
  {
    if (bufSize == null || bufSize.longValue() == 0)
      return out;
    else
      return new java.io.BufferedOutputStream(out, bufSize.intValue());
  }

  public SysOutStream(OutputStream out)
  {
    this.out = out;
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.SysOutStreamType; }

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

  public final OutStream write(long b) { return w((int)b); }
  public OutStream w(int v)
  {
    try
    {
      out.write(v);
      return this;
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public final OutStream writeBuf(Buf buf) { return writeBuf(buf, buf.remaining()); }
  public OutStream writeBuf(Buf buf, long n)
  {
    try
    {
      buf.pipeTo(out, n);
      return this;
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public OutStream writeChar(long c) { return writeChar((char)c); }
  public OutStream writeChar(char c)
  {
    charsetEncoder.encode(c, this);
    return this;
  }

  public OutStream flush()
  {
    try
    {
      out.flush();
      return this;
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public boolean close()
  {
    try
    {
      if (out != null) out.close();
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
   * Get a java.io.OutputStream for the specified output stream.
   */
  public static OutputStream java(OutStream out)
  {
    if (out instanceof SysOutStream)
      return ((SysOutStream)out).out;
    else
      return new JavaOutputStream(out);
  }

  static class JavaOutputStream extends OutputStream
  {
    JavaOutputStream(OutStream out) { this.out = out; }
    public void write(int b) { out.write((long)b); }
    public void write(byte[] b, int off, int len)
    {
      buf.buf = b;
      buf.pos = off;
      buf.size = b.length;
      out.writeBuf(buf, len);
      buf.buf = null;
    }
    public void close() { out.close(); }
    OutStream out;
    MemBuf buf = new MemBuf(null, 0);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  OutputStream out;

}
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Mar 06  Brian Frank  Creation
//
package fan.sys;

import java.io.*;
import sun.nio.cs.StreamEncoder;

/**
 * SysOutStream is an Fan sys::OutStream which
 * routes to a java.io.OutputStream.
 */
public class SysOutStream
  extends OutStream
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public static SysOutStream make(java.io.OutputStream out, Int bufSize)
  {
    if (bufSize == null || bufSize.val == 0)
      return new SysOutStream(out);
    else
      return new SysOutStream(new java.io.BufferedOutputStream(out, (int)bufSize.val));
  }

  public SysOutStream(OutputStream out)
  {
    this.out = out;
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.SysOutStreamType; }

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

  public final OutStream write(Int b) { return w((int)b.val); }
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
  public OutStream writeBuf(Buf buf, Int n)
  {
    try
    {
      buf.pipeTo(out, n.val);
      return this;
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
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

  public Bool close()
  {
    try
    {
      if (out != null) out.close();
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
    public void write(int b) { out.write(Int.make(b)); }
    public void write(byte[] b, int off, int len)
    {
      buf.buf = b;
      buf.pos = off;
      buf.size = b.length;
      out.writeBuf(buf, Int.make(len));
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

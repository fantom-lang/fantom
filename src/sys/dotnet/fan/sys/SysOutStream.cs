//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Mar 07  Andy Frank  Creation
//

using System.IO;
using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// SysOutStream.
  /// </summary>
  public class SysOutStream : OutStream
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public static SysOutStream make(Stream output, Long bufSize)
    {
      return new SysOutStream(toBuffered(output, bufSize));
    }

    public static Stream toBuffered(Stream output, Long bufSize)
    {
      if (bufSize == null || bufSize.longValue() == 0)
        return output;
      else
        return new BufferedStream(output, bufSize.intValue());
    }

    public SysOutStream(Stream output)
    {
      this.outStream = output;
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.SysOutStreamType; }

  //////////////////////////////////////////////////////////////////////////
  // OutStream
  //////////////////////////////////////////////////////////////////////////

    public override OutStream write(long b) { return w((int)b); }
    public override OutStream w(int v)
    {
      try
      {
        outStream.WriteByte((byte)v);
        return this;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public override OutStream writeBuf(Buf buf) { return writeBuf(buf, buf.remaining()); }
    public override OutStream writeBuf(Buf buf, long n)
    {
      try
      {
        buf.pipeTo(outStream, n);
        return this;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public override OutStream flush()
    {
      try
      {
        if (outStream != null) outStream.Flush();
        return this;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public override bool close()
    {
      try
      {
        if (outStream != null) outStream.Close();
        return true;
      }
      catch (IOException)
      {
        return false;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // .NET Conversion
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Get a System.IO.Stream for the specified output stream.
    /// </summary>
    public static Stream dotnet(OutStream outs)
    {
      if (outs is SysOutStream)
        return ((SysOutStream)outs).outStream;
      else
        return new DotnetOutputStream(outs);
    }

    internal class DotnetOutputStream : Stream
    {
      public DotnetOutputStream(OutStream outs) { this.outs = outs; }

      // Properties
      public override bool CanRead  { get { return false;  } }
      public override bool CanWrite { get { return true; } }
      public override bool CanSeek  { get { return false; } }
      public override long Length   { get { return -1; } }
      public override long Position { get { return -1; } set {} }

      // Methods
      public override int Read(byte[] buf, int off, int len) { return -1; }
      public override long Seek(long off, SeekOrigin origin) { return -1; }
      public override void SetLength(long val) {}
      public override void Flush() {}
      public override void Write(byte[] b, int off, int len)
      {
        buf.m_buf = b;
        buf.m_pos = off;
        buf.m_size = b.Length;
        outs.writeBuf(buf, len);
        buf.m_buf = null;
      }
      public override void Close() { outs.close(); }

      // Fields
      private OutStream outs;
      private MemBuf buf = new MemBuf(null, 0);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal Stream outStream;

  }
}
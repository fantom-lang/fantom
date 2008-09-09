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

    public static SysOutStream make(Stream output, Int bufSize)
    {
      if (bufSize == null || bufSize.val == 0)
        return new SysOutStream(output);
      else
        return new SysOutStream(new BufferedStream(output, (int)bufSize.val));
    }

    public SysOutStream(Stream output)
    {
      this.outStream = output;
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.SysOutStreamType; }

  //////////////////////////////////////////////////////////////////////////
  // OutStream
  //////////////////////////////////////////////////////////////////////////

    public override OutStream write(Int b) { return w((int)b.val); }
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
    public override OutStream writeBuf(Buf buf, Int n)
    {
      try
      {
        buf.pipeTo(outStream, n.val);
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

    public override Bool close()
    {
      try
      {
        if (outStream != null) outStream.Close();
        return Bool.True;
      }
      catch (IOException)
      {
        return Bool.False;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // .NET Conversion
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Get a System.IO.Stream for the specified output stream.
    /// </summary>
    public static Stream net(OutStream outs)
    {
      if (outs is SysOutStream)
        return ((SysOutStream)outs).outStream;
      else
        return new NetOutputStream(outs);
    }

    internal class NetOutputStream : Stream
    {
      public NetOutputStream(OutStream outs) { this.outs = outs; }

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
        outs.writeBuf(buf, Int.make(len));
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
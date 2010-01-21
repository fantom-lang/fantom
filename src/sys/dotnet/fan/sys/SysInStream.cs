//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Mar 07  Andy Frank  Creation
//

using System;
using System.IO;
using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// SysInStream.
  /// </summary>
  public class SysInStream : InStream
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public static SysInStream make(Stream input, Long bufSize)
    {
      if (bufSize == null || bufSize.longValue() == 0)
        return new SysInStream(input);
      else
        return new SysInStream(new BufferedStream(input, bufSize.intValue()));
    }

    public SysInStream(Stream input)
    {
      this.inStream = input;
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.SysInStreamType; }

  //////////////////////////////////////////////////////////////////////////
  // InStream
  //////////////////////////////////////////////////////////////////////////

    public override Long read() { int n = r(); return n < 0 ? null : Long.valueOf(n); }
    public override int r()
    {
      try
      {
        return inStream.ReadByte();
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public override Long readBuf(Buf buf, long n)
    {
      try
      {
        long read = buf.pipeFrom(inStream, n);
        if (read <= 0) return null;
        return Long.valueOf(read);
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public override InStream unread(long n) { return unread((int)n); }
    public override InStream unread(int n)
    {
      try
      {
        // don't take the hit until we know we need to wrap
        // the raw input stream with a pushback stream
        if (!(inStream is PushbackStream))
          inStream = new PushbackStream(inStream, 128);
        ((PushbackStream)inStream).Unread(n);
        return this;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public override long skip(long n)
    {
      try
      {
        for (int i=0; i<n; ++i)
          if (r() < 0) return i;
        return n;
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
        if (inStream != null) inStream.Close();
        return true;
      }
      catch (IOException)
      {
        return false;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // PushbackStream
  //////////////////////////////////////////////////////////////////////////

    internal class PushbackStream : Stream
    {
      public PushbackStream(Stream parent, int size)
      {
        this.parent = parent;
        this.pushback = new byte[size];
      }

      //
      // Properties
      //

      public override bool CanRead  { get { return parent.CanRead;  } }
      public override bool CanWrite { get { return parent.CanWrite; } }
      public override bool CanSeek  { get { return false; } } // don't allow seeking
      public override long Length   { get { return parent.Length; } }
      public override long Position
      {
        get { return parent.Position;  }
        set { parent.Position = value; }
      }

      //
      // Methods
      //

      public void Unread(int b)
      {
        if (pos >= pushback.Length)
          throw new IOException("Not enough room in pushback buffer");
        pushback[pos++] = (byte)b;
      }

      public override int Read(byte[] buf, int offset, int count)
      {
        // check pushback first
        if (pos > 0)
        {
          int len = Math.Min(pos, count);
          Array.Copy(pushback, pos-len, buf, offset, len);
          pos -= len;
          offset += len;
          count -= len;

          // short-circuit if buf filled with pushback
          if (count == 0) return len;
        }

        // grab remaining bytes
        return parent.Read(buf, offset, count);
      }

      public override void Write(byte[] buf, int offset, int count)
      {
        // This is purely an input stream, so Write not allowed
        throw new IOException("PushbackStream does not allow Write()");
      }

      public override long Seek(long offset, SeekOrigin origin)
      {
        // We don't allow seeking
        throw new IOException("PushbackStream does not allow Seek()");
      }

      public override void SetLength(long val)
      {
        // We don't allow seeking
        throw new IOException("PushbackStream does not allow SetLength()");
      }

      public override void Close() { parent.Close(); }
      public override void Flush() { parent.Flush(); }

      //
      // Fields
      //

      private Stream parent;
      private byte[] pushback;
      private int pos = 0;
    }

  //////////////////////////////////////////////////////////////////////////
  // .NET Conversion
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Get a System.IO.Stream for the specified input stream.
    /// </summary>
    public static Stream dotnet(InStream ins)
    {
      if (ins is SysInStream)
        return ((SysInStream)ins).inStream;
      else
        return new DotnetInputStream (ins);
    }

    internal class DotnetInputStream : Stream
    {
      public DotnetInputStream(InStream ins) { this.ins = ins; }

      // Properties
      public override bool CanRead  { get { return true;  } }
      public override bool CanWrite { get { return false; } }
      public override bool CanSeek  { get { return false; } }
      public override long Length   { get { return -1; } }
      public override long Position { get { return -1; } set {} }

      // Methods
      public override int Read(byte[] b, int off, int len)
      {
        buf.m_buf = b;
        buf.m_pos = off;
        buf.m_size = b.Length;
        Long n = ins.readBuf(buf, len);
        buf.m_buf = null;
        if (n == null) return -1;
        return n.intValue();
      }
      public override long Seek(long off, SeekOrigin origin) { return -1; }
      public override void SetLength(long val) {}
      public override void Flush() {}
      public override void Write(byte[] b, int off, int len) {}
      public override void Close() { ins.close(); }

      // Fields
      private InStream ins;
      private MemBuf buf = new MemBuf(null, 0);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal Stream inStream;

  }
}
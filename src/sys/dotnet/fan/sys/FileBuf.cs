//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Feb 08  Andy Frank  Split out from Buf
//

using Math = System.Math;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// FileBuf returned from File.open.
  /// </summary>
  public sealed class FileBuf : Buf
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    internal FileBuf(File file, FileStream stream)
    {
      this.m_file   = file;
      this.m_stream = stream;
      this.m_out = new FileBufOutStream(this);
      this.m_in  = new FileBufInStream(this);
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.FileBufType; }

  //////////////////////////////////////////////////////////////////////////
  // Buf Support
  //////////////////////////////////////////////////////////////////////////

    internal override long getSize()
    {
      try
      {
        return m_stream.Length;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    internal override void setSize(long x)
    {
      try
      {
        m_stream.SetLength(x);
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    internal override long getPos()
    {
      try
      {
        return m_stream.Position;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    internal override void setPos(long x)
    {
      try
      {
        m_stream.Position = x;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    internal override int getByte(long pos)
    {
      try
      {
        long oldPos = m_stream.Position;
        m_stream.Position = pos;
        int b = m_stream.ReadByte();
        m_stream.Position = oldPos;
        return b;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    internal override void setByte(long pos, int x)
    {
      try
      {
        long oldPos = m_stream.Position;
        m_stream.Position = pos;
        m_stream.WriteByte((byte)x);
        m_stream.Position = oldPos;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    internal override void getBytes(long pos, byte[] dst, int off, int len)
    {
      try
      {
        m_stream.Position = pos;
        m_stream.Read(dst, off, len);
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    internal override void pipeTo(byte[] dst, int dstPos, int len)
    {
      try
      {
        m_stream.Read(dst, dstPos, len);
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    internal override void pipeTo(Stream dst, long len)
    {
      byte[] temp = this.temp();
      long total = 0;
      while (total < len)
      {
        int n = m_stream.Read(temp, 0, (int)Math.Min(temp.Length, len-total));
        dst.Write(temp, 0, n);
        total += n;
      }
    }

    /*
    internal override void pipeTo(ByteBuffer dst, int len)
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
    */

    internal override void pipeFrom(byte[] src, int srcPos, int len)
    {
      try
      {
        m_stream.Write(src, srcPos, len);
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    internal override long pipeFrom(Stream src, long len)
    {
      byte[] temp = this.temp();
      long total = 0;
      while (total < len)
      {
        int n = src.Read(temp, 0, (int)Math.Min(temp.Length, len-total));
        if (n == 0) return total == 0 ? -1 : total;
        m_stream.Write(temp, 0, n);
        total += n;
      }
      return total;
    }

    /*
    internal override int pipeFrom(ByteBuffer src, int len)
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
    */

  //////////////////////////////////////////////////////////////////////////
  // Buf API
  //////////////////////////////////////////////////////////////////////////

    public override sealed Buf flush()
    {
      try
      {
        //fp.getFD().sync();
        m_stream.Flush();
        return this;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public override sealed bool close()
    {
      try
      {
        m_stream.Close();
        return true;
      }
      catch (System.Exception)
      {
        return false;
      }
    }

    public override sealed string toHex()
    {
      try
      {
        long oldPos = getPos();
        int size = (int)getSize();
        byte[] temp = this.temp();
        char[] hexChars = Buf.hexChars;
        StringBuilder s = new StringBuilder(size*2);

        setPos(0);
        int total = 0;
        while (total < size)
        {
          int n = m_stream.Read(temp, 0, Math.Min(temp.Length, size-total));
          for (int i=0; i<n; ++i)
          {
            int b = temp[i] & 0xFF;
            s.Append(hexChars[b>>4]).Append(hexChars[b&0xf]);
          }
          total += n;
        }

        setPos(oldPos);
        return s.ToString();
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public override Buf toDigest(string algorithm)
    {
      string alg = algorithm;
      if (alg == "SHA-1") alg = "SHA1";  // to make .NET happy
      HashAlgorithm ha = HashAlgorithm.Create(alg);
      if (ha == null)
        throw ArgErr.make("Unknown digest algorthm: " + algorithm).val;

      try
      {
        long oldPos = getPos();
        long size = getSize();
        byte[] temp = this.temp();

        setPos(0);
        long total = 0;
        while (total < size)
        {
          int n = m_stream.Read(temp, (int)total, (int)(size-total));
          total += n;
        }

        setPos(oldPos);
        return new MemBuf(ha.ComputeHash(temp, 0, (int)size));
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    internal byte[] temp()
    {
      byte[] temp = m_temp;
      if (temp == null) temp = m_temp = new byte[1024];
      return temp;
    }

  //////////////////////////////////////////////////////////////////////////
  // FileBufOutStream
  //////////////////////////////////////////////////////////////////////////

    internal class FileBufOutStream : OutStream
    {
      internal FileBufOutStream(FileBuf parent) { this.p = parent; }
      private FileBuf p;

      public override sealed OutStream write(long v) { return w((int)v); }
      public override sealed OutStream w(int v)
      {
        try
        {
          p.m_stream.WriteByte((byte)v);
          return this;
        }
        catch (IOException e) { throw IOErr.make(e).val; }
        catch (System.NotSupportedException e) { throw IOErr.make(e.Message, e).val; }
      }

      public override OutStream writeBuf(Buf other, long n)
      {
        try
        {
          other.pipeTo(p.m_stream, n);
          return this;
        }
        catch (IOException e) { throw IOErr.make(e).val; }
        catch (System.NotSupportedException e) { throw IOErr.make(e.Message, e).val; }
      }

      public override OutStream flush()
      {
        p.flush();
        return this;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // FileBufInStream
  //////////////////////////////////////////////////////////////////////////

    internal class FileBufInStream : InStream
    {
      internal FileBufInStream(FileBuf parent) { this.p = parent; }
      private FileBuf p;

      public override Long read() { int n = r(); return n < 0 ? null : Long.valueOf(n); }
      public override int r()
      {
        try
        {
          return p.m_stream.ReadByte();
        }
        catch (IOException e)
        {
          throw IOErr.make(e).val;
        }
      }

      public override Long readBuf(Buf other, long n)
      {
        try
        {
          long read = other.pipeFrom(p.m_stream, n);
          if (read < 0) return null;
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
          long pos = p.getPos();
          p.m_stream.Position = pos-1;
          p.m_stream.WriteByte((byte)n);
          p.m_stream.Position = pos-1;
          return this;
        }
        catch (IOException e)
        {
          throw IOErr.make(e).val;
        }
      }

      public override Long peek()
      {
        try
        {
          long pos = p.getPos();
          int n = p.m_stream.ReadByte();
          p.setPos(pos);
          return n < 0 ? null : Long.valueOf(n);
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

    private File m_file;
    private FileStream m_stream;
    private byte[] m_temp;

  }
}
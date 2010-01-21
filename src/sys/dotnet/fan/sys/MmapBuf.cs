//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Mar 08  Andy Frank  Creation
//

using System.IO;
using System.Runtime.InteropServices;
using IntPtr = System.IntPtr;

namespace Fan.Sys
{
  /*

  info for c#

  http://www.codeproject.com/KB/threads/csthreadmsg.aspx
  http://msmvps.com/blogs/manoj/archive/2003/12/05/973.aspx

  */

  /// <summary>
  /// MmapBuf returned from File.mmap
  /// </summary>
  public class MmapBuf : Buf
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    internal MmapBuf(File file, string mode, long pos, Long size)
    {
      this.m_file = file;

      // if size is null, use file size
      //if (size == null) size = size();

      //this.m_mmap = mmap;
      //this.m_out  = new MmapBufOutStream();
      //this.m_in   = new MmapBufInStream();
    }

    public void Dispose()
    {
      if (m_fileMap != IntPtr.Zero) UnmapViewOfFile(m_fileMap);
      if (m_fileHandle != IntPtr.Zero) CloseHandle(m_fileHandle);
      m_fileMap = m_fileHandle = IntPtr.Zero;
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.MmapBufType; }

  //////////////////////////////////////////////////////////////////////////
  // Buf Support
  //////////////////////////////////////////////////////////////////////////

    internal override sealed long getSize()
    {
      //return mmap.limit();
      return 0;
    }

    internal override sealed void setSize(long x)
    {
      //mmap.limit((int)x);
    }

    internal override sealed long getPos()
    {
      //return mmap.position();
      return 0;
    }

    internal override sealed void setPos(long x)
    {
      //mmap.position((int)x);
    }

    internal override sealed int getByte(long pos)
    {
      //return mmap.get((int)pos) & 0xff;
      return 0;
    }

    internal override sealed void setByte(long pos, int x)
    {
      //mmap.put((int)pos, (byte)x);
    }

    internal override sealed void getBytes(long pos, byte[] dst, int off, int len)
    {
      //int oldPos = mmap.position();
      //mmap.position((int)pos);
      //mmap.get(dst, off, len);
      //mmap.position(oldPos);
    }

    internal override sealed void pipeTo(byte[] dst, int dstPos, int len)
    {
      //mmap.get(dst, dstPos, len);
    }

    internal override sealed void pipeTo(Stream dst, long lenLong)
    {
      //byte[] temp = temp();
      //int len = (int)lenLong;
      //int total = 0;
      //while (total < len)
      //{
      //  int n = Math.min(temp.length, len-total);
      //  mmap.get(temp, 0, n);
      //  dst.write(temp, 0, n);
      //  total += n;
      //}
    }

    internal void pipeTo(FileStream dst, long lenLong)
    {
      //byte[] temp = temp();
      //int len = (int)lenLong;
      //int total = 0;
      //while (total < len)
      //{
      //  int n = Math.min(temp.length, len-total);
      //  mmap.get(temp, 0, n);
      //  dst.write(temp, 0, n);
      //  total += n;
      //}
    }

    /*
    internal override sealed void pipeTo(ByteBuffer dst, int len)
    {
      pipe(mmap, dst, len);
    }

    internal override void pipe(ByteBuffer src, ByteBuffer dst, int len)
    {
      // NIO has one lame method for bulk transfer
      // and it doesn't let us pass in a length
      byte[] temp = temp();
      int total = 0;
      while (total < len)
      {
        int n = Math.min(temp.length, len-total);
        src.get(temp, 0, n);
        dst.put(temp, 0, n);
        total += n;
      }
    }
    */

    internal override sealed void pipeFrom(byte[] src, int srcPos, int len)
    {
      //mmap.put(src, srcPos, len);
    }

    internal override sealed long pipeFrom(Stream src, long lenLong)
    {
      //byte[] temp = temp();
      //int len = (int)lenLong;
      //int total = 0;
      //while (total < len)
      //{
      //  int n = src.read(temp, 0, Math.min(temp.length, len-total));
      //  if (n < 0) return total == 0 ? -1 : total;
      //  mmap.put(temp, 0, n);
      //  total += n;
      //}
      //return total;
      return 0;
    }

    internal long pipeFrom(FileStream src, long lenLong)
    {
      //byte[] temp = temp();
      //int len = (int)lenLong;
      //int total = 0;
      //while (total < len)
      //{
      //  int n = src.read(temp, 0, Math.min(temp.length, len-total));
      //  if (n < 0) return total == 0 ? -1 : total;
      //  mmap.put(temp, 0, n);
      //  total += n;
      //}
      //return total;
      return 0;
    }

    /*
    internal override sealed int pipeFrom(ByteBuffer src, int len)
    {
      pipe(src, mmap, len);
      return len;
    }
    */

  //////////////////////////////////////////////////////////////////////////
  // Buf API
  //////////////////////////////////////////////////////////////////////////

    public override sealed long capacity()
    {
      return size();
    }

    public override void capacity(long x)
    {
      throw UnsupportedErr.make("mmap capacity fixed").val;
    }

    public override sealed Buf flush()
    {
      //mmap.force();
      return this;
    }

    public override sealed bool close()
    {
      // Java doesn't support closing mmap
      return true;
    }

    public override sealed string toHex()
    {
      throw UnsupportedErr.make().val;
    }

    public override Buf toDigest(string algorithm)
    {
      throw UnsupportedErr.make().val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    internal byte[] temp()
    {
      if (m_temp == null) m_temp = new byte[1024];
      return m_temp;
    }

  //////////////////////////////////////////////////////////////////////////
  // MmapBufOutStream
  //////////////////////////////////////////////////////////////////////////

    /*
    internal class MmapBufOutStream : OutStream
    {
      public override OutStream write(Long v) { return w((int)v.val); }
      public override OutStream w(int v)
      {
        mmap.put((byte)v);
        return this;
      }

      public OutStream writeBuf(Buf other, Long n)
      {
        other.pipeTo(mmap, (int)n.val);
        return this;
      }

      public OutStream flush()
      {
        MmapBuf.this.flush();
        return this;
      }
    }
    */

  //////////////////////////////////////////////////////////////////////////
  // MmapBufInStream
  //////////////////////////////////////////////////////////////////////////

    /*
    internal class MmapBufInStream : InStream
    {
      public Long read() { int n = r(); return n < 0 ? null : Long.valueOf[n]; }
      public int r()
      {
        return mmap.get() & 0xff;
      }

      public Long readBuf(Buf other, Long n)
      {
        int read = other.pipeFrom(mmap, (int)n.val);
        if (read < 0) return null;
        return Long.valueOf(read);
      }

      public InStream unread(Long n) { return unread((int)n.val); }
      public InStream unread(int n)
      {
        mmap.put(mmap.position()-1, (byte)n);
        return this;
      }

      public Long peek()
      {
        return Long.valueOf[mmap.get(mmap.position())];
      }
    }
    */

  //////////////////////////////////////////////////////////////////////////
  // Unmanaged
  //////////////////////////////////////////////////////////////////////////

    internal enum FileProtection : uint  // constants from winnt.h
    {
      ReadOnly = 2,
      ReadWrite = 4
    }

    internal enum FileRights : uint      // constants from WinBASE.h
    {
      Read = 4,
      Write = 2,
      ReadWrite = Read + Write
    }

    [DllImport ("kernel32.dll", SetLastError = true)]
    static extern IntPtr CreateFileMapping(IntPtr hFile,
      int lpAttributes, FileProtection flProtect, uint dwMaximumSizeHigh,
      uint dwMaximumSizeLow, string lpName);

    [DllImport ("kernel32.dll", SetLastError=true)]
    static extern IntPtr OpenFileMapping(FileRights dwDesiredAccess,
      bool bInheritHandle, string lpName);

    [DllImport ("kernel32.dll", SetLastError = true)]
    static extern IntPtr MapViewOfFile(IntPtr hFileMappingObject,
      FileRights dwDesiredAccess, uint dwFileOffsetHigh,
      uint dwFileOffsetLow, uint dwNumberOfBytesToMap);

    [DllImport ("Kernel32.dll")]
    static extern bool UnmapViewOfFile(IntPtr map);

    [DllImport ("kernel32.dll")]
    static extern int CloseHandle(IntPtr hObject);

    static readonly IntPtr NoFileHandle = new IntPtr(-1);

    internal void open(string name, string mode, bool existing, uint size)
    {
      // file mode
      FileRights fr; FileProtection fp;
      if (mode == "r")       { fr = FileRights.Read; fp = FileProtection.ReadOnly; }
      else if (mode == "rw") { fr = FileRights.ReadWrite; fp = FileProtection.ReadWrite; }
      else if (mode == "p") throw ArgErr.make("Private mode not supported.").val;
      else throw ArgErr.make("Invalid mode: " + mode).val;

      if (existing)
      {
        m_fileHandle = OpenFileMapping(fr, false, name);
        if (m_fileHandle == IntPtr.Zero)
          throw IOErr.make("Open error: " + Marshal.GetLastWin32Error()).val;
      }
      else
      {
        m_fileHandle = CreateFileMapping(NoFileHandle, 0, fp, 0, size, name);
        if (m_fileHandle == IntPtr.Zero)
          throw IOErr.make("Create error: " + Marshal.GetLastWin32Error()).val;
      }

      // Obtain a read/write map for the entire file
      m_fileMap = MapViewOfFile(m_fileHandle, fr, 0, 0, 0);

      if (m_fileMap == IntPtr.Zero)
        throw IOErr.make("MapViewOfFile error: " + Marshal.GetLastWin32Error()).val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private File m_file;
    private byte[] m_temp;
    private IntPtr m_fileHandle = IntPtr.Zero;
    private IntPtr m_fileMap = IntPtr.Zero;

  }
}
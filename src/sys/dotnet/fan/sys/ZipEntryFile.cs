//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Apr 07  Andy Frank  Creation
//

using ICSharpCode.SharpZipLib.Zip;

namespace Fan.Sys
{
  /// <summary>
  /// ZipEntryFile represents a file entry inside a zip file.
  /// </summary>
  public class ZipEntryFile : File
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public ZipEntryFile(ZipFile parent, ZipEntry entry, Uri uri)
      : base(uri)
    {
      this.m_parent = parent;
      this.m_entry  = entry;
    }

    public ZipEntryFile(ZipFile parent, ZipEntry entry)
      : base(Uri.fromStr("/" + LocalFile.fileNameToUriName(entry.Name)))
    {
      this.m_parent = parent;
      this.m_entry  = entry;
    }

    public ZipEntryFile(Zip parent, ZipEntry entry)
     : base(Uri.fromStr("/" + LocalFile.fileNameToUriName(entry.Name)))
    {

      this.m_parent = parent;
      this.m_entry  = entry;
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.ZipEntryFileType; }

  //////////////////////////////////////////////////////////////////////////
  // File
  //////////////////////////////////////////////////////////////////////////

    public override bool exists()
    {
      return true;
    }

    public override Long size()
    {
      if (isDir()) return null;
      long size = m_entry.Size;
      if (size < 0) return null;
      return Long.valueOf(size);
    }

    public override DateTime modified()
    {
       return DateTime.dotnet(m_entry.DateTime.Ticks);
    }

    public override void modified(DateTime time)
    {
      throw IOErr.make("ZipEntryFile is readonly").val;
    }

    public override string osPath()
    {
      return null;
    }

    public override File parent()
    {
      return null;
    }

    public override List list()
    {
      return new List(Sys.FileType, 0);
    }

    public override File normalize()
    {
      return this;
    }

    public override File plus(Uri uri, bool checkSlash)
    {
      // TODO
      throw UnsupportedErr.make("ZipEntryFile.plus").val;
    }

  //////////////////////////////////////////////////////////////////////////
  // File Management
  //////////////////////////////////////////////////////////////////////////

    public override File create()
    {
      throw IOErr.make("ZipEntryFile is readonly").val;
    }

    public override File moveTo(File to)
    {
      throw IOErr.make("ZipEntryFile is readonly").val;
    }

    public override void delete()
    {
      throw IOErr.make("ZipEntryFile is readonly").val;
    }

    public override File deleteOnExit()
    {
      throw IOErr.make("ZipEntryFile is readonly").val;
    }

  //////////////////////////////////////////////////////////////////////////
  // IO
  //////////////////////////////////////////////////////////////////////////

    public override Buf open(string mode)
    {
      throw IOErr.make("ZipEntryFile cannot be opened with random access").val;
    }

    public override Buf mmap(string mode, long pos, Long size)
    {
      throw UnsupportedErr.make("ZipEntryFile.mmap").val;
    }

    public override InStream @in(Long bufSize)
    {
      try
      {
        System.IO.Stream ins;
        if (m_parent is Zip)
        {
          // never buffer if using ZipInputStream
          ins = new ZipEntryInputStream((m_parent as Zip).m_zipIn);
        }
        else
        {
          ins = (m_parent as ZipFile).GetInputStream(m_entry);

          // buffer if specified
          if (bufSize != null && bufSize.longValue() != 0)
            ins = new System.IO.BufferedStream(ins, bufSize.intValue());
        }

        // return as fan stream
        return new SysInStream(ins);
      }
      catch (System.IO.IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public override OutStream @out(bool append, Long bufSize)
    {
      throw IOErr.make("ZipEntryFile is readonly").val;
    }

  //////////////////////////////////////////////////////////////////////////
  // ZipEntryInputStream
  //////////////////////////////////////////////////////////////////////////

    internal class ZipEntryInputStream : System.IO.Stream
    {
      public ZipEntryInputStream(System.IO.Stream parent) { this.parent = parent; }

      // Properties
      public override bool CanRead  { get { return parent.CanRead;  } }
      public override bool CanWrite { get { return parent.CanWrite; } }
      public override bool CanSeek  { get { return parent.CanSeek; } }
      public override long Length   { get { return parent.Length; } }
      public override long Position
      {
        get { return parent.Position;  }
        set { parent.Position = value; }
      }

      // Methods
      public override int Read(byte[] buf, int off, int count) { return parent.Read(buf, off, count); }
      public override void Write(byte[] buf, int off, int count) { parent.Write(buf, off, count); }
      public override long Seek(long off, System.IO.SeekOrigin origin) { return parent.Seek(off, origin); }
      public override void SetLength(long val) { parent.SetLength(val); }
      public override void Close() {} // don't do anything
      public override void Flush() { parent.Flush(); }

      // Fields
      private System.IO.Stream parent;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal readonly object m_parent;
    internal readonly ZipEntry m_entry;

  }
}
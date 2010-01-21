//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Apr 07  Andy Frank  Creation
//

using System.Collections;
using ICSharpCode.SharpZipLib.Zip;

namespace Fan.Sys
{
  /// <summary>
  /// Zip.
  /// </summary>
  public sealed class Zip : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Zip open(File file) { return new Zip(file); }

    private Zip(File f)
    {
      try
      {
        // only support local files
        if (!(f is LocalFile))
          throw IOErr.make("Only local files supported: " + f).val;

        // open the file
        this.m_file = (LocalFile)f;
        this.m_zipFile = new ZipFile(m_file.m_file.FullName);
      }
      catch (System.Exception e)
      {
        // NOTE: use ctor instead of make() to force type == IOErr
        throw new IOErr(e).val;
      }
    }

    public static Zip read(InStream ins) { return new Zip(ins); }

    private Zip(InStream ins)
    {
      this.m_zipIn = new ZipInputStream(SysInStream.dotnet(ins));
    }

    public static Zip write(OutStream outs) { return new Zip(outs); }

    private Zip(OutStream outs)
    {
      this.m_zipOut = new ZipOutputStream(SysOutStream.dotnet(outs));
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.ZipType; }

    public override string toStr()
    {
      if (m_file != null) return m_file.toStr();
      return base.toStr();
    }

  //////////////////////////////////////////////////////////////////////////
  // Access
  //////////////////////////////////////////////////////////////////////////

    public File file()
    {
      return m_file;
    }

    public Map contents()
    {
      if (m_contents == null)
      {
        if (m_zipFile == null) return null;
        m_contents = contents(m_zipFile);
      }
      return m_contents.ro();
    }

    public static Map contents(ZipFile zipFile)
    {
      Map c = new Map(Sys.UriType, Sys.FileType);
      IEnumerator e = zipFile.GetEnumerator();
      while (e.MoveNext())
      {
        ZipEntry entry = (ZipEntry)e.Current;
        ZipEntryFile f = new ZipEntryFile(zipFile, entry);
        c.set(f.m_uri, f);
      }
      return c;
    }

    public File readNext()
    {
      if (m_zipIn == null) throw UnsupportedErr.make("Zip not opened for reading").val;
      try
      {
        ZipEntry entry = m_zipIn.GetNextEntry();
        if (entry == null) return null;
        return new ZipEntryFile(this, entry);
      }
      catch (System.IO.IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public OutStream writeNext(Uri path) { return writeNext(path, DateTime.now()); }
    public OutStream writeNext(Uri path, DateTime modifyTime)
    {
      if (m_zipOut == null) throw UnsupportedErr.make("Zip not opened for writing").val;
      if (path.frag() != null) throw ArgErr.make("Path must not contain fragment: " + path).val;
      if (path.queryStr() != null) throw ArgErr.make("Path must not contain query: " + path).val;
      try
      {
        string zipPath = path.ToString();
        if (zipPath.StartsWith("/")) zipPath = zipPath.Substring(1);
        ZipEntry entry = new ZipEntry(zipPath);
        entry.DateTime = new System.DateTime(modifyTime.dotnet());
        m_zipOut.PutNextEntry(entry);
        return new ZipSysOutStream(m_zipOut);
      }
      catch (System.IO.IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public bool finish()
    {
      if (m_zipOut == null) throw UnsupportedErr.make("Zip not opened for writing").val;
      try
      {
        m_zipOut.Finish();
        return true;
      }
      catch (System.IO.IOException)
      {
        return false;
      }
    }

    public bool close()
    {
      try
      {
        if (m_zipFile != null) m_zipFile.Close();
        if (m_zipIn != null)   m_zipIn.Close();
        if (m_zipOut != null)  m_zipOut.Close();
        return true;
      }
      catch (System.IO.IOException)
      {
        return false;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // ZipSysOutStream
  //////////////////////////////////////////////////////////////////////////

    internal class ZipSysOutStream : SysOutStream
    {
      public ZipSysOutStream(ZipOutputStream zout) : base(zout)
      {
        this.zout = zout;
      }
      public override bool close()
      {
        try
        {
          zout.CloseEntry();
          return true;
        }
        catch (System.IO.IOException)
        {
          return false;
        }
      }
      private ZipOutputStream zout;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal LocalFile m_file;           // open only
    internal ZipFile m_zipFile;          // open only
    internal Map m_contents;             // open only
    internal ZipInputStream m_zipIn;     // read only
    internal ZipOutputStream m_zipOut;   // write only

  }
}
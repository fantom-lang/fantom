//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jan 07  Andy Frank  Creation
//

using System.Collections;
using System.Text;
using FileInfo = System.IO.FileInfo;
using FileStream = System.IO.FileStream;
using FileSystemInfo = System.IO.FileSystemInfo;
using DirectoryInfo  = System.IO.DirectoryInfo;

namespace Fan.Sys
{
  /// <summary>
  /// LocalFile represents a file or directory in the local file system.
  /// </summary>
  public class LocalFile : File
  {

  //////////////////////////////////////////////////////////////////////////
  // Conversions
  //////////////////////////////////////////////////////////////////////////

    public static Uri fileToUri(FileSystemInfo file, bool isDir)
    {
      return pathToUri(file.FullName, isDir);
    }

    public static Uri pathToUri(string path, bool isDir)
    {
      return pathToUri(path, isDir, null);
    }

    public static Uri pathToUri(string path, bool isDir, string scheme)
    {
      int len = path.Length;
      StringBuilder s = new StringBuilder(path.Length+2);

      // if scheme was specified
      if (scheme != null) s.Append(scheme).Append(':');

      // deal with Windoze drive name
      if (len > 2 && path[1] == ':' && path[0] != '\\')
        s.Append('/');

      // map characters
      for (int i=0; i<len; ++i)
      {
        int c = path[i];
        switch (c)
        {
          case '?':
          case '#':  s.Append('\\').Append((char)c); break;
          case '\\': s.Append('/'); break;
          default:   s.Append((char)c); break;
        }
      }

      // add trailing slash if not present
      if (isDir && (s.Length == 0 || s[s.Length-1] != '\\'))
        s.Append('/');

      return Uri.fromStr(s.ToString());
    }

    public static FileSystemInfo uriToFile(Uri uri)
    {
      if (uri.scheme() != null && uri.scheme() != "file")
        throw ArgErr.make("Invalid Uri scheme for local file: " + uri).val;
      string path = uriToPath(uri);
      if (System.IO.Directory.Exists(path)) return new DirectoryInfo(path);
      if (System.IO.File.Exists(path)) return new FileInfo(path);
      if (uri.isDir()) return new DirectoryInfo(path);
      return new FileInfo(path);
    }

    public static string uriToPath(Uri uri)
    {
      string path = uri.m_pathStr;
      bool dir = uri.isDir();
      int len = path.Length;
      StringBuilder s = new StringBuilder(path.Length);
      for (int i=0; i<len; ++i)
      {
        int c = path[i];
        if (i == 0 && c == '/') continue;  // skip abs
        if (i == len-1 && c == '/' && dir) continue;  // skip trailing slash
        switch (c)
        {
          case '\\': break;
          case '/':  s.Append('\\'); break;
          default:   s.Append((char)c); break;
        }
      }
      return s.ToString();
    }

    public static string fileNameToUriName(string name)
    {
      int len = name.Length;
      StringBuilder s = null;
      for (int i=0; i<len; ++i)
      {
        int c = name[i];
        switch (c)
        {
          case '?':
          case '#':
            if (s == null) { s = new StringBuilder(); s.Append(name, 0, i); }
            s.Append('\\').Append((char)c);
            break;
          default:
            if (s != null) s.Append((char)c);
            break;
        }
      }
      return s == null ? name: s.ToString();
    }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

    public static Uri toUri(FileSystemInfo file)
    {
      return fileToUri(file, file is DirectoryInfo);
    }

    public LocalFile(Uri uri)
      : this(uri, uriToFile(uri)) {}

    public LocalFile(FileSystemInfo file)
      : this(file, file is DirectoryInfo) {}

    public LocalFile(FileSystemInfo file, bool isDir)
      : this(fileToUri(file, isDir), file) {}

    public LocalFile(Uri uri, FileSystemInfo file)
      : base(uri)
    {
      this.m_file = file;
      if (System.IO.Directory.Exists(file.FullName))
      {
        if (!uri.isDir())
          throw IOErr.make("Must use trailing slash for dir: " + uri).val;
      }
      else if (System.IO.File.Exists(file.FullName))
      {
        if (uri.isDir())
          throw IOErr.make("Cannot use trailing slash for file: " + uri).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.LocalFileType; }

  //////////////////////////////////////////////////////////////////////////
  // File
  //////////////////////////////////////////////////////////////////////////

    public override bool exists()
    {
      return m_file.Exists;
    }

    public override Long size()
    {
      if (m_file is DirectoryInfo) return null;
      m_file.Refresh();
      return Long.valueOf((m_file as FileInfo).Length);
    }

    public override DateTime modified()
    {
      return m_file.Exists ? DateTime.dotnet(m_file.LastAccessTime.Ticks) : null;
    }

    public override void modified(DateTime time)
    {
      m_file.LastAccessTime = new System.DateTime(time.dotnet());
    }

    public override string osPath()
    {
      return uriToPath(m_uri);
    }

    public override File parent()
    {
      Uri parent = m_uri.parent();
      if (parent == null) return null;
      return new LocalFile(parent, uriToFile(parent));
    }

    public override List list()
    {
      int len = 0;
      FileSystemInfo[] list = null;
      if (m_file is DirectoryInfo)
      {
        list = (m_file as DirectoryInfo).GetFileSystemInfos();
        len = list.Length;
      }
      List acc = new List(Sys.FileType, len);
      for (int i=0; i<len; i++)
      {
        FileSystemInfo f = list[i];
        string name = fileNameToUriName(f.Name);
        acc.add(new LocalFile(m_uri.plusName(name, f is DirectoryInfo), f));
      }
      return acc;
    }

    public override File normalize()
    {
      // TODO - not sure how this should work in .NET
      bool isDir = m_file is DirectoryInfo;
      FileSystemInfo canonical;
      if (isDir)
        canonical = new DirectoryInfo(m_file.FullName);
      else
        canonical = new FileInfo(m_file.FullName);
      Uri uri = pathToUri(canonical.FullName, isDir, "file");
      return new LocalFile(uri, canonical);
    }

    public override File plus(Uri uri, bool checkSlash)
    {
      return make(m_uri.plus(uri), checkSlash);
    }

  //////////////////////////////////////////////////////////////////////////
  // File Management
  //////////////////////////////////////////////////////////////////////////

    public override File create()
    {
      if (isDir())
        createDir();
      else
        createFile();
      return this;
    }

    private void createFile()
    {
      if (m_file.Exists)
      {
        if (m_file is DirectoryInfo)
          throw IOErr.make("Already exists as dir: " + m_file).val;
      }
      else
      {
        DirectoryInfo parent = (m_file as FileInfo).Directory;
        if (!parent.Exists)
        {
          try
          {
            System.IO.Directory.CreateDirectory(parent.FullName);
          }
          catch (System.Exception e)
          {
            throw IOErr.make("Cannot create dir: " + parent, e).val;
          }
        }

        try
        {
          // TODO - not sure how this should work yet
          FileStream fs = (m_file as FileInfo).Create();
          fs.Close();
          m_file.Refresh();
        }
        catch (System.IO.IOException e)
        {
          throw IOErr.make(e).val;
        }
      }
    }

    private void createDir()
    {
      if (m_file.Exists)
      {
        if (!(m_file is DirectoryInfo))
          throw IOErr.make("Already exists as file: " + m_file).val;
      }
      else
      {
        try
        {
          System.IO.Directory.CreateDirectory(m_file.FullName);
          m_file.Refresh();
        }
        catch (System.Exception e)
        {
          throw IOErr.make("Cannot create dir: " + m_file, e).val;
        }
      }
    }

    public override File moveTo(File to)
    {
      if (isDir() != to.isDir())
      {
        if (isDir())
          throw ArgErr.make("moveTo must be dir `" + to + "`").val;
        else
          throw ArgErr.make("moveTo must not be dir `" + to + "`").val;
      }

      if (!(to is LocalFile))
        throw IOErr.make("Cannot move LocalFile to " + to.@typeof()).val;
      LocalFile dest = (LocalFile)to;

      if (dest.exists())
        throw IOErr.make("moveTo already exists: " + to).val;

      try
      {
        if (m_file is FileInfo)
          (m_file as FileInfo).MoveTo((dest.m_file as FileInfo).FullName);
        else
          (m_file as DirectoryInfo).MoveTo((dest.m_file as DirectoryInfo).FullName);
      }
      catch (System.IO.IOException)
      {
        throw IOErr.make("moveTo failed: " + to).val;
      }

      return to;
    }

    public override void delete()
    {
      if (!exists()) return;

      if (m_file is DirectoryInfo)
      {
        List kids = list();
        for (int i=0; i<kids.sz(); i++)
          (kids.get(i) as File).delete();
      }

      try
      {
        m_file.Delete();
        m_file.Refresh();
      }
      catch (System.Exception e)
      {
        throw IOErr.make("Cannot delete: " + m_file, e).val;
      }
    }

    public override File deleteOnExit()
    {
      m_deleteOnExit.Add(m_file);
      return this;
    }

  //////////////////////////////////////////////////////////////////////////
  // IO
  //////////////////////////////////////////////////////////////////////////

    public override Buf open(string mode)
    {
      try
      {
        System.IO.FileMode fm;
        System.IO.FileAccess fa;
        string s = mode;

        if (s == "r")
        {
          fm = System.IO.FileMode.Open;
          fa = System.IO.FileAccess.Read;
        }
        else if (s == "w")
        {
          fm = System.IO.FileMode.OpenOrCreate;
          fa = System.IO.FileAccess.Write;
        }
        else if (s == "rw")
        {
          fm = System.IO.FileMode.OpenOrCreate;
          fa = System.IO.FileAccess.ReadWrite;
        }
        else
        {
          throw new System.IO.IOException("Unsupported mode: " + mode);
        }

        return new FileBuf(this, (m_file as FileInfo).Open(fm, fa));
      }
      catch (System.IO.IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public override Buf mmap(string mode, long pos, Long size)
    {
      try
      {
        // map mode
        /*
        MmapBuf.FileRights mode;
        if (mode.val.equals("r"))       { mode = MmapBuff.FileRights.Read; }
        else if (mode.val.equals("rw")) { mode = MmapBuff.FileRights.ReadWrite; }
        else if (mode.val.equals("p")) throw ArgErr.make("Private mode not supported.").val;
        else throw ArgErr.make("Invalid mode: " + mode).val;

        // verify mode is 'r' or 'rw'
        if (mode.val.equals("p")) throw ArgErr.make("Private mode not supported.").val;
        if (!mode.val.equals("r") || !mode.val.equals("rw")) throw ArgErr.make("Invalid mode: " + mode).val;

        // if size is null, use file size
        if (size == null) size = size();

        // traverse the various Java APIs
        //RandomAccessFile fp = new RandomAccessFile(file, rw);
        //FileChannel chan = fp.getChannel();
        //MappedByteBuffer mmap = chan.map(mm, pos.val, size.val);
        */

        return new MmapBuf(this, mode, pos, size);
      }
      catch (System.IO.IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public override InStream @in(Long bufSize)
    {
      try
      {
        System.IO.Stream stream = (m_file as FileInfo).OpenRead();
        return SysInStream.make(stream, bufSize);
      }
      catch (System.IO.IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public override OutStream @out(bool append, Long bufSize)
    {
      try
      {
        FileInfo f = (FileInfo)m_file;
        System.IO.Directory.CreateDirectory(f.DirectoryName);

        System.IO.Stream fout = f.Open(
          append ? System.IO.FileMode.Append : System.IO.FileMode.Create,
          System.IO.FileAccess.Write);
        System.IO.Stream bout = SysOutStream.toBuffered(fout, bufSize);
        m_file.Refresh();
        return new LocalFileOutStream(bout/*, fout.getFD()*/);
      }
      catch (System.IO.IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    internal class LocalFileOutStream : SysOutStream
    {
      public LocalFileOutStream(System.IO.Stream @out/*, FileDescriptor fd*/)
        : base(@out)
      {
        /*this.fd = fd;*/
      }

      public override OutStream sync()
      {
        try
        {
          flush();
          /*fd.sync();*/
          return this;
        }
        catch (System.IO.IOException e)
        {
          throw IOErr.make(e).val;
        }
      }

      /*FileDescriptor fd;*/
    }

  //////////////////////////////////////////////////////////////////////////
  // ProcessExit
  //////////////////////////////////////////////////////////////////////////

    static ArrayList m_deleteOnExit = new ArrayList();

    static LocalFile()
    {
      System.AppDomain.CurrentDomain.ProcessExit
        += new System.EventHandler(handleProcessExit);
    }

    static void handleProcessExit(object sender, System.EventArgs args)
    {
      foreach (FileSystemInfo f in m_deleteOnExit)
      {
        try
        {
          if (f is DirectoryInfo)
            (f as DirectoryInfo).Delete(true);
          else
            f.Delete();
        }
        catch (System.IO.DirectoryNotFoundException) {}  // ok
        catch (System.IO.FileNotFoundException) {}       // ok
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // C#
  //////////////////////////////////////////////////////////////////////////

    public FileSystemInfo toDotnet() { return m_file; }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal FileSystemInfo m_file = null;

  }
}
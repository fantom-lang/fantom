//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jan 07  Andy Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// File represents a file or directory in a file system.
  /// <summary>
  public abstract class File : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static File make(Uri uri) { return make(uri, true); }
    public static File make(Uri uri, bool checkSlash)
    {
      System.IO.FileSystemInfo f = LocalFile.uriToFile(uri);
      if (f is System.IO.DirectoryInfo && !checkSlash && !uri.isDir())
        uri = uri.plusSlash();
      return new LocalFile(uri, f);
    }

    public static File os(string osPath)
    {
      System.IO.FileSystemInfo f = (System.IO.Directory.Exists(osPath))
        ? new System.IO.DirectoryInfo(osPath) as System.IO.FileSystemInfo
        : new System.IO.FileInfo(osPath) as System.IO.FileSystemInfo;
      Uri uri = LocalFile.pathToUri(osPath, f is System.IO.DirectoryInfo);
      return new LocalFile(uri, f);
    }

    public static List osRoots()
    {
      List list = new List(Sys.FileType);
      string[] drives = System.IO.Directory.GetLogicalDrives();
      for (int i=0; i<drives.Length; i++)
        list.add(new LocalFile(new System.IO.FileInfo(drives[i]), true));
      return list;
    }

    public static File createTemp() { return createTemp(null, null, null); }
    public static File createTemp(string prefix) { return createTemp(prefix, null, null); }
    public static File createTemp(string prefix, string suffix) { return createTemp(prefix, suffix, null); }
    public static File createTemp(string prefix, string suffix, File dir)
    {
      if (prefix == null || prefix.Length == 0) prefix = "fan";
      if (suffix == null) suffix = ".tmp";

      string parent = null;
      if (dir == null)
      {
        parent = System.IO.Path.GetTempPath();
      }
      else
      {
        if (!(dir is LocalFile)) throw IOErr.make("Dir is not on local file system: " + dir).val;
        parent = ((LocalFile)dir).m_file.FullName;
      }

      try
      {
        string name = parent + '\\' + prefix + suffix;
        int count = 1;
        while (System.IO.File.Exists(name))
          name = parent + '\\' + prefix + (count++) + suffix;
        LocalFile temp = new LocalFile(new System.IO.FileInfo(name));
        temp.create();
        return temp;
      }
      catch (System.IO.IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

    protected File(Uri uri)
    {
      this.m_uri = uri;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override sealed bool Equals(object obj)
    {
      if (obj is File)
      {
        return m_uri.Equals(((File)obj).m_uri);
      }
      return false;
    }

    public override sealed int GetHashCode() { return m_uri.GetHashCode(); }

    public override sealed long hash() { return m_uri.hash(); }

    public override sealed string toStr() { return m_uri.toStr(); }

    public override Type @typeof() { return Sys.FileType; }

  //////////////////////////////////////////////////////////////////////////
  // Uri
  //////////////////////////////////////////////////////////////////////////

    public Uri uri() { return m_uri; }

    public bool isDir() { return m_uri.isDir();   }

    public List path() { return m_uri.path(); }

    public string pathStr() { return m_uri.pathStr(); }

    public string name() { return m_uri.name(); }

    public string basename() { return m_uri.basename(); }

    public string ext() { return m_uri.ext(); }

    public MimeType mimeType() { return m_uri.mimeType(); }

  //////////////////////////////////////////////////////////////////////////
  // Access
  //////////////////////////////////////////////////////////////////////////

    public abstract bool exists();

    public abstract Long size();

    public abstract DateTime modified();
    public abstract void modified(DateTime time);

    public abstract string osPath();

    public abstract File parent();

    public abstract List list();

    public virtual List listDirs()
    {
      List x = list();
      for (int i=x.sz()-1; i>=0; --i)
        if (!((File)x.get(i)).isDir())
          x.removeAt(i);
      return x;
    }

    public virtual void walk(Func c)
    {
      c.call(this);
      if (isDir())
      {
        List x = list();
        for (int i=0; i<x.sz(); ++i)
          ((File)x.get(i)).walk(c);
      }
    }

    public virtual List listFiles()
    {
      List x = list();
      for (int i=x.sz()-1; i>=0; --i)
        if (((File)x.get(i)).isDir())
          x.removeAt(i);
      return x;
    }

    public abstract File normalize();

    public File plus(Uri uri) { return plus(uri, true); }
    public abstract File plus(Uri uri, bool checkSlash);

    internal File plus(string uri) { return plus(Uri.fromStr(uri)); }

    internal File plusNameOf(File x)
    {
      string name = x.name();
      if (x.isDir()) name += "/";
      return plus(name);
    }

  //////////////////////////////////////////////////////////////////////////
  // Management
  //////////////////////////////////////////////////////////////////////////

    public abstract File create();

    public File createFile(string name)
    {
      if (!isDir()) throw IOErr.make("Not a directory: " + this).val;
      return this.plus(FanStr.toUri(name)).create();
    }

    public File createDir(string name)
    {
      if (!isDir()) throw IOErr.make("Not a directory: " + this).val;
      if (!name.EndsWith("/")) name = name + "/";
      return this.plus(FanStr.toUri(name)).create();
    }

    public abstract void delete();

    public abstract File deleteOnExit();

  //////////////////////////////////////////////////////////////////////////
  // Copy
  //////////////////////////////////////////////////////////////////////////

    public File copyTo(File to) { return copyTo(to, null); }
    public virtual File copyTo(File to, Map options)
    {
      // sanity
      if (isDir() != to.isDir())
      {
        if (isDir())
          throw ArgErr.make("copyTo must be dir `" + to + "`").val;
        else
          throw ArgErr.make("copyTo must not be dir `" + to + "`").val;
      }

      // options
      object exclude = null, overwrite = null;
      if (options != null)
      {
        exclude = options.get(optExclude);
        overwrite = options.get(optOverwrite);
      }

      // recurse
      doCopyTo(to, exclude, overwrite);
      return to;
    }

    private void doCopyTo(File to, object exclude, object overwrite)
    {
      // check exclude
      if (exclude is Regex)
      {
        if (((Regex)exclude).matches(m_uri.toStr())) return;
      }
      else if (exclude is Func)
      {
        if (((Func)exclude).call(this) == Boolean.True) return;
      }

      // check for overwrite
      if (to.exists())
      {
        if (overwrite is Boolean)
        {
          if (overwrite == Boolean.False) return;
        }
        else if (overwrite is Func)
        {
          if (((Func)overwrite).call(this) == Boolean.False) return;
        }
        else
        {
          throw IOErr.make("No overwrite policy for `" + to + "`").val;
        }
      }

      // copy directory
      if (isDir())
      {
        to.create();
        List kids = list();
        for (int i=0; i<kids.sz(); ++i)
        {
          File kid = (File)kids.get(i);
          kid.doCopyTo(to.plusNameOf(kid), exclude, overwrite);
        }
      }

      // copy file contents
      else
      {
        OutStream @out = to.@out();
        try
        {
          @in().pipe(@out);
        }
        finally
        {
          @out.close();
        }
      }
    }

    public File copyInto(File dir) { return copyInto(dir, null); }
    public virtual File copyInto(File dir, Map options)
    {
      if (!dir.isDir())
        throw ArgErr.make("Not a dir: `" + dir + "`").val;

      return copyTo(dir.plusNameOf(this), options);
    }

  //////////////////////////////////////////////////////////////////////////
  // Move
  //////////////////////////////////////////////////////////////////////////

    public abstract File moveTo(File to);

    public virtual File moveInto(File dir)
    {
      if (!dir.isDir())
        throw ArgErr.make("Not a dir: `" + dir + "`").val;

      return moveTo(dir.plusNameOf(this));
    }

    public virtual File rename(string newName)
    {
      string n = newName;
      if (isDir()) n += "/";
      return moveTo(parent().plus(n));
    }

  //////////////////////////////////////////////////////////////////////////
  // IO
  //////////////////////////////////////////////////////////////////////////

    public Buf open() { return open(rwStr); }
    public abstract Buf open(string mode);

    public Buf mmap() { return mmap(rwStr, 0, null); }
    public Buf mmap(string mode) { return mmap(mode, 0, null); }
    public Buf mmap(string mode, long pos) { return mmap(mode, pos, null); }
    public abstract Buf mmap(string mode, long pos, Long size);

    public InStream @in() { return @in(defaultBufSize); }
    public abstract InStream @in(Long bufSize);

    public OutStream @out() { return @out(false, defaultBufSize); }
    public OutStream @out(bool append) { return @out(append, defaultBufSize); }
    public abstract OutStream @out(bool append, Long bufSize);

    private static readonly Long defaultBufSize = Long.valueOf(4096);

    public Buf readAllBuf()
    {
      return @in(defaultBufSize).readAllBuf();
    }

    public List readAllLines()
    {
      return @in(defaultBufSize).readAllLines();
    }

    public void eachLine(Func f)
    {
      @in(FanInt.Chunk).eachLine(f);
    }

    public string readAllStr() { return readAllStr(true); }
    public string readAllStr(bool normalizeNewlines)
    {
      return @in(defaultBufSize).readAllStr(normalizeNewlines);
    }

    public Map readProps()
    {
      return @in(defaultBufSize).readProps();
    }

    public void writeProps(Map props)
    {
      @out(false, defaultBufSize).writeProps(props, true);
    }

    public object readObj() { return readObj(null); }
    public object readObj(Map options)
    {
      InStream ins = @in();
      try
      {
        return ins.readObj(options);
      }
      finally
      {
        ins.close();
      }
    }

    public void writeObj(object obj) { writeObj(obj, null); }
    public void writeObj(object obj, Map options)
    {
      OutStream outs = @out();
      try
      {
        outs.writeObj(obj, options);
      }
      finally
      {
        outs.close();
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static readonly string m_sep = ""+System.IO.Path.DirectorySeparatorChar;
    public static readonly string m_pathSep = ""+System.IO.Path.PathSeparator;

    internal static readonly string rwStr        = "rw";
    internal static readonly string optOverwrite = "overwrite";
    internal static readonly string optExclude   = "exclude";

    internal readonly Uri m_uri;

  }
}
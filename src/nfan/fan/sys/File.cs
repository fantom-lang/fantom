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

    public static File make(Uri uri) { return make(uri, Bool.True); }
    public static File make(Uri uri, Bool checkSlash)
    {
      System.IO.FileSystemInfo f = LocalFile.uriToFile(uri);
      if (f is System.IO.DirectoryInfo && !checkSlash.val && !uri.isDir().val)
        uri = uri.plusSlash();
      return new LocalFile(uri, f);
    }

    public static File os(Str osPath)
    {
      System.IO.FileSystemInfo f = (System.IO.Directory.Exists(osPath.val))
        ? new System.IO.DirectoryInfo(osPath.val) as System.IO.FileSystemInfo
        : new System.IO.FileInfo(osPath.val) as System.IO.FileSystemInfo;
      Uri uri = LocalFile.pathToUri(osPath.val, f is System.IO.DirectoryInfo);
      return new LocalFile(uri, f);
    }

    public static List osRoots()
    {
      // TODO
      throw IOErr.make("osRoots not implemented yet!").val;
    }

    public static File createTemp() { return createTemp(null, null, null); }
    public static File createTemp(Str prefix) { return createTemp(prefix, null, null); }
    public static File createTemp(Str prefix, Str suffix) { return createTemp(prefix, suffix, null); }
    public static File createTemp(Str prefix, Str suffix, File dir)
    {
      if (prefix == null || prefix.val.Length == 0) prefix = Str.make("fan");
      if (suffix == null) suffix = Str.make(".tmp");

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
        string name = parent + '\\' + prefix.val + suffix.val;
        int count = 1;
        while (System.IO.File.Exists(name))
          name = parent + '\\' + prefix.val + (count++) + suffix.val;
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

    public override sealed Bool equals(Obj obj)
    {
      if (obj is File)
      {
        return m_uri.equals(((File)obj).m_uri);
      }
      return Bool.False;
    }

    public override sealed int GetHashCode() { return m_uri.GetHashCode(); }

    public override sealed Int hash() { return m_uri.hash(); }

    public override sealed Str toStr() { return m_uri.toStr(); }

    public override Type type() { return Sys.FileType; }

  //////////////////////////////////////////////////////////////////////////
  // Uri
  //////////////////////////////////////////////////////////////////////////

    public Uri uri() { return m_uri; }

    public Bool isDir() { return m_uri.isDir();   }

    public List path() { return m_uri.path(); }

    public Str pathStr() { return m_uri.pathStr(); }

    public Str name() { return m_uri.name(); }

    public Str basename() { return m_uri.basename(); }

    public Str ext() { return m_uri.ext(); }

    public MimeType mimeType() { return m_uri.mimeType(); }

  //////////////////////////////////////////////////////////////////////////
  // Access
  //////////////////////////////////////////////////////////////////////////

    public abstract Bool exists();

    public abstract Int size();

    public abstract DateTime modified();
    public abstract void modified(DateTime time);

    public abstract Str osPath();

    public abstract File parent();

    public abstract List list();

    public virtual List listDirs()
    {
      List x = list();
      for (int i=x.sz()-1; i>=0; --i)
        if (!((File)x.get(i)).isDir().val)
          x.removeAt(Int.make(i));
      return x;
    }

    public virtual void walk(Func c)
    {
      c.call1(this);
      if (isDir().val)
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
        if (((File)x.get(i)).isDir().val)
          x.removeAt(Int.make(i));
      return x;
    }

    public abstract File normalize();

    public File plus(Uri uri) { return plus(uri, Bool.True); }
    public abstract File plus(Uri uri, Bool checkSlash);

    internal File plus(string uri) { return plus(Uri.fromStr(uri)); }

    internal File plusNameOf(File x)
    {
      string name = x.name().val;
      if (x.isDir().val) name += "/";
      return plus(name);
    }

  //////////////////////////////////////////////////////////////////////////
  // Management
  //////////////////////////////////////////////////////////////////////////

    public abstract File create();

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
        if (isDir().val)
          throw ArgErr.make("copyTo must be dir `" + to + "`").val;
        else
          throw ArgErr.make("copyTo must not be dir `" + to + "`").val;
      }

      // options
      Obj exclude = null, overwrite = null;
      if (options != null)
      {
        exclude = options.get(optExclude);
        overwrite = options.get(optOverwrite);
      }

      // recurse
      doCopyTo(to, exclude, overwrite);
      return to;
    }

    private void doCopyTo(File to, Obj exclude, Obj overwrite)
    {
      // check exclude
      if (exclude is Regex)
      {
        if (((Regex)exclude).matches(m_uri.toStr()).val) return;
      }
      else if (exclude is Func)
      {
        if (((Func)exclude).call1(this) == Bool.True) return;
      }

      // check for overwrite
      if (to.exists().val)
      {
        if (overwrite is Bool)
        {
          if (overwrite == Bool.False) return;
        }
        else if (overwrite is Func)
        {
          if (((Func)overwrite).call1(this) == Bool.False) return;
        }
        else
        {
          throw IOErr.make("No overwrite policy for `" + to + "`").val;
        }
      }

      // copy directory
      if (isDir().val)
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
      if (!dir.isDir().val)
        throw ArgErr.make("Not a dir: `" + dir + "`").val;

      return copyTo(dir.plusNameOf(this), options);
    }

  //////////////////////////////////////////////////////////////////////////
  // Move
  //////////////////////////////////////////////////////////////////////////

    public abstract File moveTo(File to);

    public virtual File moveInto(File dir)
    {
      if (!dir.isDir().val)
        throw ArgErr.make("Not a dir: `" + dir + "`").val;

      return moveTo(dir.plusNameOf(this));
    }

    public virtual File rename(Str newName)
    {
      string n = newName.val;
      if (isDir().val) n += "/";
      return moveTo(parent().plus(n));
    }

  //////////////////////////////////////////////////////////////////////////
  // IO
  //////////////////////////////////////////////////////////////////////////

    public Buf open() { return open(rwStr); }
    public abstract Buf open(Str mode);

    public Buf mmap() { return mmap(rwStr, Int.Zero, null); }
    public Buf mmap(Str mode) { return mmap(mode, Int.Zero, null); }
    public Buf mmap(Str mode, Int pos) { return mmap(mode, pos, null); }
    public abstract Buf mmap(Str mode, Int pos, Int size);

    public InStream @in() { return @in(defaultBufSize); }
    public abstract InStream @in(Int bufSize);

    public OutStream @out() { return @out(Bool.False, defaultBufSize); }
    public OutStream @out(Bool append) { return @out(append, defaultBufSize); }
    public abstract OutStream @out(Bool append, Int bufSize);

    private static readonly Int defaultBufSize = Int.make(4096);

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
      @in(Int.Chunk).eachLine(f);
    }

    public Str readAllStr() { return readAllStr(Bool.True); }
    public Str readAllStr(Bool normalizeNewlines)
    {
      return @in(defaultBufSize).readAllStr(normalizeNewlines);
    }

    public Map readProps()
    {
      return @in(defaultBufSize).readProps();
    }

    public void writeProps(Map props)
    {
      @out(Bool.False, defaultBufSize).writeProps(props, Bool.True);
    }

    public Obj readObj() { return readObj(null); }
    public Obj readObj(Map options)
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

    public void writeObj(Obj obj) { writeObj(obj, null); }
    public void writeObj(Obj obj, Map options)
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

    public static readonly Str m_sep = Str.make(""+System.IO.Path.DirectorySeparatorChar);
    public static readonly Str m_pathSep = Str.make(""+System.IO.Path.PathSeparator);

    internal static readonly Str rwStr        = Str.make("rw");
    internal static readonly Str optOverwrite = Str.make("overwrite");
    internal static readonly Str optExclude   = Str.make("exclude");

    internal readonly Uri m_uri;

  }
}
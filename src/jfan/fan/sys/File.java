//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 06  Brian Frank  Creation
//
package fan.sys;

/**
 * File represents a file or directory in a file system.
 */
public abstract class File
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static File make(Uri uri) { return make(uri, true); }
  public static File make(Uri uri, Boolean checkSlash)
  {
    java.io.File f = LocalFile.uriToFile(uri);
    if (f.isDirectory() && !checkSlash && !uri.isDir())
      uri = uri.plusSlash();
    return new LocalFile(uri, f);
  }

  public static File os(Str osPath)
  {
    return new LocalFile(new java.io.File(osPath.val));
  }

  public static List osRoots()
  {
    List list = new List(Sys.FileType);
    java.io.File[] roots = java.io.File.listRoots();
    for (int i=0; i<roots.length; ++i)
      list.add(new LocalFile(roots[i], true));
    return list;
  }

  public static File createTemp() { return createTemp(null, null, null); }
  public static File createTemp(Str prefix) { return createTemp(prefix, null, null); }
  public static File createTemp(Str prefix, Str suffix) { return createTemp(prefix, suffix, null); }
  public static File createTemp(Str prefix, Str suffix, File dir)
  {
    if (prefix == null || prefix.val.length() == 0) prefix = Str.make("fan");
    if (prefix.val.length() == 1) prefix = Str.make(prefix.val + "xx");
    if (prefix.val.length() == 2) prefix = Str.make(prefix.val + "x");

    if (suffix == null) suffix = Str.make(".tmp");

    java.io.File d = null;
    if (dir != null)
    {
      if (!(dir instanceof LocalFile)) throw IOErr.make("Dir is not on local file system: " + dir).val;
      d = ((LocalFile)dir).file;
    }

    try
    {
      return new LocalFile(java.io.File.createTempFile(prefix.val, suffix.val, d));
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  protected File(Uri uri)
  {
    this.uri = uri;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final Boolean _equals(Object obj)
  {
    if (obj instanceof File)
    {
      return uri._equals(((File)obj).uri);
    }
    return false;
  }

  public final int hashCode() { return uri.hashCode(); }

  public final Int hash() { return uri.hash(); }

  public final Str toStr() { return uri.toStr(); }

  public Type type() { return Sys.FileType; }

//////////////////////////////////////////////////////////////////////////
// Uri
//////////////////////////////////////////////////////////////////////////

  public final Uri uri() { return uri; }

  public final Boolean isDir() { return uri.isDir();   }

  public final List path() { return uri.path(); }

  public final Str pathStr() { return uri.pathStr(); }

  public final Str name() { return uri.name(); }

  public final Str basename() { return uri.basename(); }

  public final Str ext() { return uri.ext(); }

  public final MimeType mimeType() { return uri.mimeType(); }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  public abstract Boolean exists();

  public abstract Int size();

  public abstract DateTime modified();
  public abstract void modified(DateTime time);

  public abstract Str osPath();

  public abstract File parent();

  public abstract List list();

  public List listDirs()
  {
    List list = list();
    for (int i=list.sz()-1; i>=0; --i)
      if (!((File)list.get(i)).isDir())
        list.removeAt(Int.make(i));
    return list;
  }

  public List listFiles()
  {
    List list = list();
    for (int i=list.sz()-1; i>=0; --i)
      if (((File)list.get(i)).isDir())
        list.removeAt(Int.make(i));
    return list;
  }

  public void walk(Func c)
  {
    c.call1(this);
    if (isDir())
    {
      List list = list();
      for (int i=0; i<list.sz(); ++i)
        ((File)list.get(i)).walk(c);
    }
  }

  public abstract File normalize();

  public File plus(Uri uri) { return plus(uri, true); }
  public abstract File plus(Uri uri, Boolean checkSlash);

  File plus(String uri) { return plus(Uri.fromStr(uri)); }

  File plusNameOf(File x)
  {
    String name = x.name().val;
    if (x.isDir()) name += "/";
    return plus(name);
  }

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

  public abstract File create();

  public File createFile(Str name)
  {
    if (!isDir()) throw IOErr.make("Not a directory: " + this).val;
    return this.plus(name.toUri()).create();
  }

  public File createDir(Str name)
  {
    if (!isDir()) throw IOErr.make("Not a directory: " + this).val;
    if (!name.val.endsWith("/")) name = Str.make(name.val + "/");
    return this.plus(name.toUri()).create();
  }

  public abstract void delete();

  public abstract File deleteOnExit();

//////////////////////////////////////////////////////////////////////////
// Copy
//////////////////////////////////////////////////////////////////////////

  public final File copyTo(File to) { return copyTo(to, null); }
  public File copyTo(File to, Map options)
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
    Object exclude = null, overwrite = null;
    if (options != null)
    {
      exclude = options.get(optExclude);
      overwrite = options.get(optOverwrite);
    }

    // recurse
    doCopyTo(to, exclude, overwrite);
    return to;
  }

  private void doCopyTo(File to, Object exclude, Object overwrite)
  {
    // check exclude
    if (exclude instanceof Regex)
    {
      if (((Regex)exclude).matches(uri.toStr())) return;
    }
    else if (exclude instanceof Func)
    {
      if (((Func)exclude).call1(this) == Boolean.TRUE) return;
    }

    // check for overwrite
    if (to.exists())
    {
      if (overwrite instanceof Boolean)
      {
        if (overwrite == Boolean.FALSE) return;
      }
      else if (overwrite instanceof Func)
      {
        if (((Func)overwrite).call1(this) == Boolean.FALSE) return;
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
      OutStream out = to.out();
      try
      {
        in().pipe(out);
      }
      finally
      {
        out.close();
      }
    }
  }

  public final File copyInto(File dir) { return copyInto(dir, null); }
  public File copyInto(File dir, Map options)
  {
    if (!dir.isDir())
      throw ArgErr.make("Not a dir: `" + dir + "`").val;

    return copyTo(dir.plusNameOf(this), options);
  }

//////////////////////////////////////////////////////////////////////////
// Move
//////////////////////////////////////////////////////////////////////////

  public abstract File moveTo(File to);

  public File moveInto(File dir)
  {
    if (!dir.isDir())
      throw ArgErr.make("Not a dir: `" + dir + "`").val;

    return moveTo(dir.plusNameOf(this));
  }

  public File rename(Str newName)
  {
    String n = newName.val;
    if (isDir()) n += "/";
    return moveTo(parent().plus(n));
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  public final Buf open() { return open(rwStr); }
  public abstract Buf open(Str mode);

  public final Buf mmap() { return mmap(rwStr, Int.Zero, null); }
  public final Buf mmap(Str mode) { return mmap(mode, Int.Zero, null); }
  public final Buf mmap(Str mode, Int pos) { return mmap(mode, pos, null); }
  public abstract Buf mmap(Str mode, Int pos, Int size);

  public final InStream in() { return in(Int.Chunk); }
  public abstract InStream in(Int bufSize);

  public final OutStream out() { return out(false, Int.Chunk); }
  public final OutStream out(Boolean append) { return out(append, Int.Chunk); }
  public abstract OutStream out(Boolean append, Int bufSize);

  public final Buf readAllBuf()
  {
    return in(Int.Chunk).readAllBuf();
  }

  public final List readAllLines()
  {
    return in(Int.Chunk).readAllLines();
  }

  public final void eachLine(Func f)
  {
    in(Int.Chunk).eachLine(f);
  }

  public final Str readAllStr() { return readAllStr(true); }
  public final Str readAllStr(Boolean normalizeNewlines)
  {
    return in(Int.Chunk).readAllStr(normalizeNewlines);
  }

  public final Map readProps()
  {
    return in(Int.Chunk).readProps();
  }

  public final void writeProps(Map props)
  {
    out(false, Int.Chunk).writeProps(props, true);
  }

  public final Object readObj() { return readObj(null); }
  public final Object readObj(Map options)
  {
    InStream in = in();
    try
    {
      return in.readObj(options);
    }
    finally
    {
      in.close();
    }
  }

  public final void writeObj(Object obj) { writeObj(obj, null); }
  public final void writeObj(Object obj, Map options)
  {
    OutStream out = out();
    try
    {
      out.writeObj(obj, options);
    }
    finally
    {
      out.close();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final Str sep = Str.make(java.io.File.separator);
  public static final Str pathSep = Str.make(java.io.File.pathSeparator);

  static final Str rwStr        = Str.make("rw");
  static final Str optOverwrite = Str.make("overwrite");
  static final Str optExclude   = Str.make("exclude");

  final Uri uri;
}
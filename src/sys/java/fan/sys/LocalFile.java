//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 06  Brian Frank  Creation
//
package fan.sys;

import java.io.FileDescriptor;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.FileChannel.MapMode;

/**
 * LocalFile represents a file or directory in the local file system.
 */
public class LocalFile
  extends File
{

//////////////////////////////////////////////////////////////////////////
// Conversions
//////////////////////////////////////////////////////////////////////////

  public static Uri fileToUri(java.io.File file, boolean isDir, String scheme)
  {
    String path = file.getPath();
    int len = path.length();
    StringBuilder s = new StringBuilder(path.length()+2);

    // if scheme was specified
    if (scheme != null) s.append(scheme).append(':');

    // deal with Windoze drive name
    if (len > 2 && path.charAt(1) == ':' && path.charAt(0) != '/')
      s.append('/');

    // map characters
    for (int i=0; i<len; ++i)
    {
      int c = path.charAt(i);
      switch (c)
      {
        case '?':
        case '#':  s.append('\\').append((char)c); break;
        case '\\': s.append('/'); break;
        default:   s.append((char)c);
      }
    }

    // add trailing slash if not present
    if (isDir && (s.length() == 0 || s.charAt(s.length()-1) != '/'))
      s.append('/');

    return Uri.fromStr(s.toString());
  }

  public static java.io.File uriToFile(Uri uri)
  {
    if (uri.scheme() != null && !uri.scheme().equals("file"))
      throw ArgErr.make("Invalid Uri scheme for local file: " + uri);
    return new java.io.File(uriToPath(uri));
  }

  public static String uriToPath(Uri uri)
  {
    String path = uri.pathStr();
    int len = path.length();
    StringBuilder s = null;
    for (int i=0; i<len; ++i)
    {
      int c = path.charAt(i);
      if (c == '\\')
      {
        if (s == null) { s = new StringBuilder(); s.append(path, 0, i); }
      }
      else if (s != null) s.append((char)c);
    }
    return s == null ? path : s.toString();
  }

  public static String fileNameToUriName(String name)
  {
    int len = name.length();
    StringBuilder s = null;
    for (int i=0; i<len; ++i)
    {
      int c = name.charAt(i);
      switch (c)
      {
        case '?':
        case '#':
          if (s == null) { s = new StringBuilder(); s.append(name, 0, i); }
          s.append('\\').append((char)c);
          break;
        default:
          if (s != null) s.append((char)c);
      }
    }
    return s == null ? name: s.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public LocalFile(java.io.File file)
  {
    this(file, file.isDirectory());
  }

  public LocalFile(java.io.File file, boolean isDir)
  {
    this(fileToUri(file, isDir, null), file);
  }

  public LocalFile(Uri uri, java.io.File file)
  {
    super(uri);
    this.file = file;
    if (file.exists())
    {
      if (file.isDirectory())
      {
        if (!uri.isDir())
          throw IOErr.make("Must use trailing slash for dir: " + uri);
      }
      else
      {
        if (uri.isDir())
          throw IOErr.make("Cannot use trailing slash for file: " + uri);
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.LocalFileType; }

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

  public boolean exists()
  {
    return file.exists();
  }

  public Long size()
  {
    if (file.isDirectory()) return null;
    return Long.valueOf(file.length());
  }

  public DateTime modified()
  {
    return DateTime.fromJava(file.lastModified());
  }

  public void modified(DateTime time)
  {
    file.setLastModified(time.toJava());
  }

  public String osPath()
  {
    return file.getPath();
  }

  public File parent()
  {
    Uri parent = uri.parent();
    if (parent == null) return null;
    return new LocalFile(parent, uriToFile(parent));
  }

  public List list()
  {
    java.io.File[] list = file.listFiles();
    int len = list == null ? 0 : list.length;
    List acc = new List(Sys.FileType, len);
    for (int i=0; i<len; ++i)
    {
      java.io.File f = list[i];
      String name = fileNameToUriName(f.getName());
      acc.add(new LocalFile(uri.plusName(name, f.isDirectory()), f));
    }
    return acc;
  }

  public File normalize()
  {
    try
    {
      java.io.File canonical = file.getCanonicalFile();
      boolean isDir = canonical.exists() ? canonical.isDirectory() : this.uri.isDir();
      Uri uri = fileToUri(canonical, isDir, "file");
      return new LocalFile(uri, canonical);
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public File plus(Uri uri, boolean checkSlash)
  {
    return make(this.uri.plus(uri), checkSlash);
  }

//////////////////////////////////////////////////////////////////////////
// File Management
//////////////////////////////////////////////////////////////////////////

  public File create()
  {
    if (isDir())
      createDir();
    else
      createFile();
    return this;
  }

  private void createFile()
  {
    if (file.exists())
    {
      if (file.isDirectory())
        throw IOErr.make("Already exists as dir: " + file);
    }

    java.io.File parent = file.getParentFile();
    if (parent != null && !parent.exists())
    {
      if (!parent.mkdirs())
        throw IOErr.make("Cannot create dir: " + parent);
    }

    try
    {
      java.io.FileOutputStream out = new java.io.FileOutputStream(file);
      out.close();
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e);
    }
  }

  private void createDir()
  {
    if (file.exists())
    {
      if (!file.isDirectory())
        throw IOErr.make("Already exists as file: " + file);
    }
    else
    {
      if (!file.mkdirs())
        throw IOErr.make("Cannot create dir: " + file);
    }
  }

  public File moveTo(File to)
  {
    if (isDir() != to.isDir())
    {
      if (isDir())
        throw ArgErr.make("moveTo must be dir `" + to + "`");
      else
        throw ArgErr.make("moveTo must not be dir `" + to + "`");
    }

    if (!(to instanceof LocalFile))
      throw IOErr.make("Cannot move LocalFile to " + to.typeof());
    LocalFile dest = (LocalFile)to;

    if (dest.exists())
      throw IOErr.make("moveTo already exists: " + to);

    if (!file.isDirectory())
    {
      File destParent = dest.parent();
      if (destParent != null && !destParent.exists())
        destParent.create();
    }

    if (!file.renameTo(dest.file))
      throw IOErr.make("moveTo failed: " + to);

    return to;
  }

  public void delete()
  {
    if (!exists()) return;

    if (file.isDirectory())
    {
      List kids = list();
      for (int i=0; i<kids.sz(); ++i)
        ((File)kids.get(i)).delete();
    }

    if (!file.delete())
      throw IOErr.make("Cannot delete: " + file);
  }

  public File deleteOnExit()
  {
    file.deleteOnExit();
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  public Buf open(String mode)
  {
    try
    {
      return new FileBuf(this, new RandomAccessFile(file, mode));
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public Buf mmap(String mode, long pos, Long size)
  {
    try
    {
      // map mode
      String rw; MapMode mm;
      if (mode.equals("r"))       { rw = "r";  mm = MapMode.READ_ONLY; }
      else if (mode.equals("rw")) { rw = "rw"; mm = MapMode.READ_WRITE; }
      else if (mode.equals("p"))  { rw = "rw"; mm = MapMode.PRIVATE; }
      else throw ArgErr.make("Invalid mode: " + mode);

      // if size is null, use file size
      if (size == null) size = size();

      // traverse the various Java APIs
      RandomAccessFile fp = null;
      FileChannel chan = null;
      try
      {
        fp = new RandomAccessFile(file, rw);
        chan = fp.getChannel();
        return new MmapBuf(this, chan.map(mm, pos, size.longValue()));
      }
      finally
      {
        if (chan != null) chan.close();
        if (fp != null) fp.close();
      }
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public InStream in(Long bufSize)
  {
    try
    {
      return SysInStream.make(new java.io.FileInputStream(file), bufSize);
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public OutStream out(boolean append, Long bufSize)
  {
    try
    {
      java.io.File parent = file.getParentFile();
      if (parent != null && !parent.exists()) parent.mkdirs();
      java.io.FileOutputStream fout = new java.io.FileOutputStream(file, append);
      java.io.OutputStream bout = SysOutStream.toBuffered(fout, bufSize);
      return new LocalFileOutStream(bout, fout.getFD());
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e);
    }
  }

  static class LocalFileOutStream extends SysOutStream
  {
    LocalFileOutStream(java.io.OutputStream out, FileDescriptor fd)
    {
      super(out);
      this.fd = fd;
    }

    public OutStream sync()
    {
      try
      {
        flush();
        fd.sync();
        return this;
      }
      catch (java.io.IOException e)
      {
        throw IOErr.make(e);
      }
    }

    FileDescriptor fd;
  }

  public java.io.File toJava() { return file; }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final java.io.File file;

}
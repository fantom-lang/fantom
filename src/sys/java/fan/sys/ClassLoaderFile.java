//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Nov 10  Brian Frank  Creation
//
package fan.sys;

/**
 * ClassLoaderFile represents a file loaded as a resource from the class loader.
 */
public class ClassLoaderFile
  extends File
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public ClassLoaderFile(ClassLoader loader, String loaderPath, Uri uri)
  {
    super(uri);
    this.loader     = loader;
    this.loaderPath = loaderPath;
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.ClassLoaderFileType; }

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

  public boolean exists()
  {
    return true;
  }

  public Long size()
  {
    initMeta();
    if (size < 0) return null;
    return Long.valueOf(size);
  }

  public DateTime modified()
  {
    initMeta();
    if (modified <= 0) return null;
    return DateTime.fromJava(modified);
  }

  public void modified(DateTime time)
  {
    throw IOErr.make("ClassLoaderFile is readonly").val;
  }

  public String osPath()
  {
    return null;
  }

  public File parent()
  {
    return null;
  }

  public List list()
  {
    return new List(Sys.FileType, 0);
  }

  public File normalize()
  {
    return this;
  }

  public File plus(Uri uri, boolean checkSlash)
  {
    throw UnsupportedErr.make("ClassLoaderFile.plus").val;
  }

//////////////////////////////////////////////////////////////////////////
// File Management
//////////////////////////////////////////////////////////////////////////

  public File create()
  {
    throw IOErr.make("ClassLoaderFile is readonly").val;
  }

  public File moveTo(File to)
  {
    throw IOErr.make("ClassLoaderFile is readonly").val;
  }

  public void delete()
  {
    throw IOErr.make("ClassLoaderFile is readonly").val;
  }

  public File deleteOnExit()
  {
    throw IOErr.make("ClassLoaderFile is readonly").val;
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  public Buf open(String mode)
  {
    throw UnsupportedErr.make("ClassLoaderFile.open").val;
  }

  public Buf mmap(String mode, long pos, Long size)
  {
    throw UnsupportedErr.make("ClassLoaderFile.mmap").val;
  }

  public InStream in(Long bufSize)
  {
    // get stream from class loader
    java.io.InputStream in = loader.getResourceAsStream(loaderPath);

    // buffer if specified
    if (bufSize != null && bufSize.longValue() != 0)
      in = new java.io.BufferedInputStream(in, bufSize.intValue());

    // return as fan stream
    return new SysInStream(in);
  }

  public OutStream out(boolean append, Long bufSize)
  {
    throw IOErr.make("ClassLoaderFile is readonly").val;
  }

//////////////////////////////////////////////////////////////////////////
// InitMeta
//////////////////////////////////////////////////////////////////////////

  private void initMeta()
  {
    if (inited) return;
    try
    {
      java.net.URL url = loader.getResource(loaderPath);
      java.net.URLConnection conn = url.openConnection();
      size = conn.getContentLength();
      modified = conn.getLastModified();
    }
    catch (Exception e)
    {
      e.printStackTrace();
    }
    inited = true;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final ClassLoader loader;
  final String loaderPath;
  private boolean inited;
  private int size;
  private long modified;

}
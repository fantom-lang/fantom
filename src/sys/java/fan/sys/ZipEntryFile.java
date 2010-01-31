//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 06  Brian Frank  Creation
//
package fan.sys;

/**
 * ZipEntryFile represents a file entry inside a zip file.
 */
public class ZipEntryFile
  extends File
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public ZipEntryFile(java.util.zip.ZipFile parent, java.util.zip.ZipEntry entry, Uri uri)
  {
    super(uri);
    this.parent = parent;
    this.entry  = entry;
  }

  public ZipEntryFile(java.util.zip.ZipFile parent, java.util.zip.ZipEntry entry)
  {
    this(parent, entry, entryUri(entry));
  }

  public ZipEntryFile(Zip parent, java.util.zip.ZipEntry entry)
  {
    super(entryUri(entry));
    this.parent = parent;
    this.entry  = entry;
  }

  static Uri entryUri(java.util.zip.ZipEntry entry)
  {
    return Uri.fromStr("/" + LocalFile.fileNameToUriName(entry.getName()));
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.ZipEntryFileType; }

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

  public boolean exists()
  {
    return true;
  }

  public Long size()
  {
    if (isDir()) return null;
    long size = entry.getSize();
    if (size < 0) return null;
    return Long.valueOf(size);
  }

  public DateTime modified()
  {
    return DateTime.fromJava(entry.getTime());
  }

  public void modified(DateTime time)
  {
    throw IOErr.make("ZipEntryFile is readonly").val;
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
    // TODO
    throw UnsupportedErr.make("ZipEntryFile.plus").val;
  }

//////////////////////////////////////////////////////////////////////////
// File Management
//////////////////////////////////////////////////////////////////////////

  public File create()
  {
    throw IOErr.make("ZipEntryFile is readonly").val;
  }

  public File moveTo(File to)
  {
    throw IOErr.make("ZipEntryFile is readonly").val;
  }

  public void delete()
  {
    throw IOErr.make("ZipEntryFile is readonly").val;
  }

  public File deleteOnExit()
  {
    throw IOErr.make("ZipEntryFile is readonly").val;
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  public Buf open(String mode)
  {
    throw UnsupportedErr.make("ZipEntryFile.open").val;
  }

  public Buf mmap(String mode, long pos, Long size)
  {
    throw UnsupportedErr.make("ZipEntryFile.mmap").val;
  }

  public InStream in(Long bufSize)
  {
    try
    {
      java.io.InputStream in;
      if (parent instanceof Zip)
      {
        // never buffer if using ZipInputStream
        in = new java.io.FilterInputStream(((Zip)parent).zipIn) { public void close() {} };
      }
      else
      {
        in = ((java.util.zip.ZipFile)parent).getInputStream(entry);

        // buffer if specified
        if (bufSize != null && bufSize.longValue() != 0)
          in = new java.io.BufferedInputStream(in, bufSize.intValue());
      }

      // return as fan stream
      return new SysInStream(in);
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public OutStream out(boolean append, Long bufSize)
  {
    throw IOErr.make("ZipEntryFile is readonly").val;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final Object parent;
  final java.util.zip.ZipEntry entry;

}
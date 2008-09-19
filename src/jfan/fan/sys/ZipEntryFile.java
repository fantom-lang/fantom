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

  public ZipEntryFile(java.util.zip.ZipFile parent, java.util.zip.ZipEntry entry)
  {
    super(Uri.fromStr("/" + LocalFile.fileNameToUriName(entry.getName())));
    this.parent = parent;
    this.entry  = entry;
  }

  public ZipEntryFile(Zip parent, java.util.zip.ZipEntry entry)
  {
    super(Uri.fromStr("/" + LocalFile.fileNameToUriName(entry.getName())));
    this.parent = parent;
    this.entry  = entry;
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.ZipEntryFileType; }

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

  public Bool exists()
  {
    return Bool.True;
  }

  public Int size()
  {
    if (isDir().val) return null;
    long size = entry.getSize();
    if (size < 0) return null;
    return Int.pos(size);
  }

  public DateTime modified()
  {
    return DateTime.java(entry.getTime());
  }

  public void modified(DateTime time)
  {
    throw IOErr.make("ZipEntryFile is readonly").val;
  }

  public Str osPath()
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

  public File plus(Uri uri, Bool checkSlash)
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

  public Buf open(Str mode)
  {
    throw UnsupportedErr.make("ZipEntryFile.open").val;
  }

  public Buf mmap(Str mode, Int pos, Int size)
  {
    throw UnsupportedErr.make("ZipEntryFile.mmap").val;
  }

  public InStream in(Int bufSize)
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
        if (bufSize != null && bufSize.val != 0)
          in = new java.io.BufferedInputStream(in, (int)bufSize.val);
      }

      // return as fan stream
      return new SysInStream(in);
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public OutStream out(Bool append, Int bufSize)
  {
    throw IOErr.make("ZipEntryFile is readonly").val;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final Object parent;
  final java.util.zip.ZipEntry entry;

}

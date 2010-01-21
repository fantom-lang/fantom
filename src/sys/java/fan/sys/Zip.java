//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Aug 06  Brian Frank  Creation
//
package fan.sys;

import java.util.Enumeration;
import java.util.zip.ZipFile;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;

/**
 * Zip
 */
public final class Zip
  extends FanObj
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
      if (!(f instanceof LocalFile))
        throw IOErr.make("Only local files supported: " + f).val;

      // open the file
      this.file = (LocalFile)f;
      this.zipFile = new ZipFile(file.file);
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public static Zip read(InStream in) { return new Zip(in); }

  private Zip(InStream in)
  {
    this.zipIn = new ZipInputStream(SysInStream.java(in));
  }

  public static Zip write(OutStream out) { return new Zip(out); }

  private Zip(OutStream out)
  {
    this.zipOut = new ZipOutputStream(SysOutStream.java(out));
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.ZipType; }

  public String toStr()
  {
    if (file != null) return file.toStr();
    return super.toStr();
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  public File file()
  {
    return file;
  }

  public Map contents()
  {
    if (contents == null)
    {
      if (zipFile == null) return null;
      contents = contents(zipFile);
    }
    return contents.ro();
  }

  public static Map contents(ZipFile zipFile)
  {
    Map c = new Map(Sys.UriType, Sys.FileType);
    Enumeration e = zipFile.entries();
    while (e.hasMoreElements())
    {
      ZipEntry entry = (ZipEntry)e.nextElement();
      ZipEntryFile f = new ZipEntryFile(zipFile, entry);
      c.set(f.uri, f);
    }
    return c;
  }

  public File readNext()
  {
    if (zipIn == null) throw UnsupportedErr.make("Zip not opened for reading").val;
    try
    {
      ZipEntry entry = zipIn.getNextEntry();
      if (entry == null) return null;
      return new ZipEntryFile(this, entry);
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public OutStream writeNext(Uri path) { return writeNext(path, DateTime.now()); }
  public OutStream writeNext(Uri path, DateTime modifyTime)
  {
    if (zipOut == null) throw UnsupportedErr.make("Zip not opened for writing").val;
    if (path.frag() != null) throw ArgErr.make("Path must not contain fragment: " + path).val;
    if (path.queryStr() != null) throw ArgErr.make("Path must not contain query: " + path).val;
    try
    {
      String zipPath = path.toString();
      if (zipPath.startsWith("/")) zipPath = zipPath.substring(1);
      ZipEntry entry = new ZipEntry(zipPath);
      entry.setTime(modifyTime.toJava());
      zipOut.putNextEntry(entry);
      return new SysOutStream(zipOut)
      {
        public boolean close()
        {
          try
          {
            zipOut.closeEntry();
            return true;
          }
          catch (java.io.IOException e)
          {
            return false;
          }
        }
      };
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public boolean finish()
  {
    if (zipOut == null) throw UnsupportedErr.make("Zip not opened for writing").val;
    try
    {
      zipOut.finish();
      return true;
    }
    catch (java.io.IOException e)
    {
      return false;
    }
  }

  public boolean close()
  {
    try
    {
      if (zipFile != null) zipFile.close();
      if (zipIn != null)   zipIn.close();
      if (zipOut != null)  zipOut.close();
      return true;
    }
    catch (java.io.IOException e)
    {
      return false;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  LocalFile file;           // open only
  ZipFile zipFile;          // open only
  Map contents;             // open only
  ZipInputStream zipIn;     // read only
  ZipOutputStream zipOut;   // write only

}
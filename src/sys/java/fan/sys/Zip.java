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
import java.util.zip.GZIPOutputStream;
import java.util.zip.GZIPInputStream;
import java.util.zip.Deflater;
import java.util.zip.DeflaterOutputStream;
import java.util.zip.Inflater;
import java.util.zip.InflaterInputStream;

/**
 * Zip is used to read/write compressed zip files and streams.
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
        throw IOErr.make("Only local files supported: " + f);

      // open the file
      this.file = (LocalFile)f;
      this.zipFile = new ZipFile(file.file);
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e);
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

  public Map<Uri,File> contents()
  {
    if (contents == null)
    {
      if (zipFile == null) return null;
      contents = contents(zipFile);
    }
    return contents.ro();
  }

  public static Map<Uri,File> contents(ZipFile zipFile)
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
    if (zipIn == null) throw UnsupportedErr.make("Zip not opened for reading");
    try
    {
      ZipEntry entry = zipIn.getNextEntry();
      if (entry == null) return null;
      return new ZipEntryFile(this, entry);
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void readEach(Func f)
  {
    File file;
    while ((file = readNext()) != null)
    {
      f.call(file);
    }
  }

  public OutStream writeNext(Uri path) { return writeNext(path, DateTime.now(), null); }
  public OutStream writeNext(Uri path, DateTime modifyTime) { return writeNext(path, modifyTime, null); }
  public OutStream writeNext(Uri path, DateTime modifyTime, Map opts)
  {
    if (zipOut == null) throw UnsupportedErr.make("Zip not opened for writing");
    if (path.frag() != null) throw ArgErr.make("Path must not contain fragment: " + path);
    if (path.queryStr() != null) throw ArgErr.make("Path must not contain query: " + path);

    // Java 1.7+ supports ZIP64 which supports over 65,535 files, but
    // previous versions silently fail which is really bad; so add
    // Fantom specific sanity check here
    if (Sys.javaVersion < Sys.JAVA_1_7)
    {
      if (zipOutCount >= 65535) throw UnsupportedErr.make("Zip cannot handle more than 65535 files");
      zipOutCount++;
    }

    try
    {
      // init ZipEntry
      String zipPath = path.toString();
      if (zipPath.startsWith("/")) zipPath = zipPath.substring(1);
      ZipEntry entry = new ZipEntry(zipPath);

      // options
      entry.setTime(modifyTime.toJava());
      if (opts != null)
      {
        if (opts.get("level") != null)
        {
          int level = ((Long)opts.get("level")).intValue();
          zipOut.setLevel(level);
          zipOut.setMethod(level == 0 ? ZipOutputStream.STORED : ZipOutputStream.DEFLATED);
        }
        if (opts.get("comment")          != null) entry.setComment((String)opts.get("comment"));
        if (opts.get("crc")              != null) entry.setCrc((Long)opts.get("crc"));
        if (opts.get("extra")            != null) entry.setExtra(((Buf)opts.get("extra")).safeArray());
        if (opts.get("compressedSize")   != null) entry.setCompressedSize((Long)opts.get("compressedSize"));
        if (opts.get("uncompressedSize") != null) entry.setSize((Long)opts.get("uncompressedSize"));
      }

      // putNextEntry and return as SysOutStream
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
            e.printStackTrace();
            return false;
          }
        }
      };
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public boolean finish()
  {
    if (zipOut == null) throw UnsupportedErr.make("Zip not opened for writing");
    try
    {
      zipOut.finish();
      return true;
    }
    catch (java.io.IOException e)
    {
      e.printStackTrace();
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
      e.printStackTrace();
      return false;
    }
  }

  public static long unzipInto(File zipFile, File dir)
  {
    if (!dir.isDir()) throw ArgErr.make("Not dir: " + dir);
    Zip zip = null;
    try
    {
      int count = 0;
      zip = read(zipFile.in());
      File entry;
      while ((entry = zip.readNext()) != null)
      {
        String relUri = entry.uri().toStr().substring(1);
        File dest = dir.plus(Uri.fromStr(relUri));
        if (entry.isDir()) { dest.create(); continue; }
        OutStream out = dest.out();
        try
        {
          entry.in().pipe(out);
        }
        finally
        {
          out.close();
        }
        if (entry.modified() != null) dest.modified(entry.modified());
        count++;
      }
      return count;
    }
    finally
    {
      if (zip != null) zip.close();
    }
  }

//////////////////////////////////////////////////////////////////////////
// GZIP
//////////////////////////////////////////////////////////////////////////

  public static OutStream gzipOutStream(OutStream out)
  {
    try
    {
      return new SysOutStream(new GZIPOutputStream(SysOutStream.java(out)));
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public static InStream gzipInStream(InStream in)
  {
    try
    {
      return new SysInStream(new GZIPInputStream(SysInStream.java(in)));
    }
    catch (java.io.IOException e)
    {
      throw IOErr.make(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Deflate/Inflate
//////////////////////////////////////////////////////////////////////////

  public static OutStream deflateOutStream(OutStream out) { return deflateOutStream(out, null); }
  public static OutStream deflateOutStream(OutStream out, Map opts)
  {
    int level = Deflater.DEFAULT_COMPRESSION;
    boolean nowrap = false;
    if (opts != null)
    {
      if (opts.get("nowrap") != null) nowrap = ((Boolean)opts.get("nowrap")).booleanValue();
      if (opts.get("level") != null) level = ((Long)opts.get("level")).intValue();
    }
    Deflater d = new Deflater(level, nowrap);
    return new SysOutStream(new DeflaterOutputStream(SysOutStream.java(out), d));
  }

  public static InStream deflateInStream(InStream in) { return deflateInStream(in, null); }
  public static InStream deflateInStream(InStream in, Map opts)
  {
    boolean nowrap = false;
    if (opts != null)
    {
      if (opts.get("nowrap") != null) nowrap = ((Boolean)opts.get("nowrap")).booleanValue();
    }
    Inflater i = new Inflater(nowrap);
    return new SysInStream(new InflaterInputStream(SysInStream.java(in), i));
  }


//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  LocalFile file;           // open only
  ZipFile zipFile;          // open only
  Map contents;             // open only
  ZipInputStream zipIn;     // read only
  ZipOutputStream zipOut;   // write only
  int zipOutCount;          // write only

}


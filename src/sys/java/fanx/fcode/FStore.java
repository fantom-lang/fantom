//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 05  Brian Frank  Creation
//
package fanx.fcode;

import java.io.*;
import java.util.*;
import java.util.zip.*;
import fan.sys.*;
import fan.sys.File;
import fan.sys.Map;
import fanx.util.*;

/**
 * FStore models IO streams to use for reading and writing pod files.
 */
public class FStore
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  /**
   * Construct a FStore to read.
   */
  FStore(FPod fpod, java.util.zip.ZipFile zipFile)
  {
    this.fpod    = fpod;
    this.zipFile = zipFile;
    if (zipFile == null) throw new IllegalStateException();
  }

//////////////////////////////////////////////////////////////////////////
// File Access
//////////////////////////////////////////////////////////////////////////

  /**
   * List all the files available.
   */
  public String[] list()
  {
    ArrayList acc = new ArrayList();
    Enumeration en = zipFile.entries();
    while (en.hasMoreElements())
      acc.add(((ZipEntry)en.nextElement()).getName());
    return (String[])acc.toArray(new String[acc.size()]);
  }

  /**
   * Return a map to use for Pod.files()
   */
  public Map podFiles()
  {
    Map map = new Map(Sys.UriType, Sys.FileType);
    Enumeration en = zipFile.entries();
    while (en.hasMoreElements())
    {
      ZipEntry entry = (ZipEntry)en.nextElement();
      String name = entry.getName();
      if (name.endsWith(".fcode")) continue;
      if (name.endsWith(".class")) continue;
      fan.sys.ZipEntryFile file = new fan.sys.ZipEntryFile(zipFile, entry);
      map.set(file.uri(), file);
    }
    return map;
  }

  /**
   * Convenience for read(path, false).
   */
  public FStore.Input read(String path)
    throws IOException
  {
    return read(path, false);
  }

  /**
   * Open an input stream for the specified logical path.
   * Return null if not found.
   */
  public FStore.Input read(String path, boolean required)
    throws IOException
  {
    ZipEntry entry = zipFile.getEntry(path);
    if (entry == null)
    {
      if (required)
        throw new IOException("Missing required file \"" + path + "\" in pod zip");
      else
        return null;
    }
    return new FStore.Input(fpod, zipFile.getInputStream(entry));
  }

  /**
   * Read a file with the specified logical path into a memory
   * buffer.  Return null if not found.
   */
  public Box readToBox(String path)
    throws IOException
  {
    ZipEntry entry = zipFile.getEntry(path);
    if (entry == null) return null;

    int size = (int)entry.getSize();
    byte[] buf = new byte[size];
    int n = 0;

    InputStream in = zipFile.getInputStream(entry);
    try
    {
      while (n < size)
        n += in.read(buf, n, size-n);
    }
    finally
    {
      try { in.close(); } catch (Exception e) {}
    }

    return new Box(buf);
  }

  /**
   * Close underlying file.
   */
  public void close()
    throws IOException
  {
    zipFile.close();
  }

//////////////////////////////////////////////////////////////////////////
// FStore.Input
//////////////////////////////////////////////////////////////////////////

  /**
   * FStore.Input is used to read from a FStore file.
   */
  public static class Input
    extends DataInputStream
  {
    Input(FPod fpod, InputStream out) { super(out); this.fpod = fpod; }

    public final int    u1()  throws IOException { return readUnsignedByte(); }
    public final int    u2()  throws IOException { return readUnsignedShort(); }
    public final int    u4()  throws IOException { return readInt(); }
    public final long   u8()  throws IOException { return readLong(); }
    public final double f8()  throws IOException { return readDouble(); }
    public final String utf() throws IOException { return readUTF(); }
    public final String name() throws IOException { return fpod.name(u2()); }

    public final FPod fpod;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final FPod fpod;
  final java.util.zip.ZipFile zipFile;

}

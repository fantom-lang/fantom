//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 13  Brian Frank  Creation
//
package fan.sys;

/**
 * LocalFileStore is store for LocaleFile.
 */
public class LocalFileStore
  extends FileStore
{

  LocalFileStore(java.nio.file.FileStore fs)
  {
    this.fs = fs;
  }

  public Long totalSpace()
  {
    try
    {
      return fs.getTotalSpace();
    }
    catch (java.io.IOException e)
    {
      return null;
    }
  }

  public Long availSpace()
  {
    try
    {
      return fs.getUsableSpace();
    }
    catch (java.io.IOException e)
    {
      return null;
    }
  }

  public Long freeSpace()
  {
    try
    {
      return fs.getUnallocatedSpace();
    }
    catch (java.io.IOException e)
    {
      return null;
    }
  }

  public Type typeof() { return Sys.LocalFileStoreType; }

  final java.nio.file.FileStore fs;
}
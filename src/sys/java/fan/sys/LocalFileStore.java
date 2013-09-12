//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 13  Brian Frank  Creation
//
package fan.sys;

import java.io.*;

/**
 * LocalFileStore is store for LocaleFile.
 *
 * This implementation uses the java.io.File methods added in 1.6 rather
 * than new nio APIs added in 1.7 to avoid requiring 1.7
 */
public class LocalFileStore
  extends FileStore
{

  LocalFileStore(java.io.File file)
    throws IOException
  {
    this.file = file;
    this.spaceKnown = file.getTotalSpace() > 0;
  }

  public Long totalSpace()
  {
    return spaceKnown ? file.getTotalSpace() : null;
  }

  public Long availSpace()
  {
    return spaceKnown ? file.getUsableSpace() : null;
  }

  public Long freeSpace()
  {
    return spaceKnown ? file.getFreeSpace() : null;
  }

  public Type typeof() { return Sys.LocalFileStoreType; }

  final java.io.File file;
  final boolean spaceKnown;
}
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
 * FileStore represents the storage pool, device, partition, or volume
** used to store files.
 */
public abstract class FileStore
  extends FanObj
{

  protected static void make$() {}

  protected static void makeNew$(FileStore self)
  {
  }

  public abstract Long totalSpace();

  public abstract Long availSpace();

  public abstract Long freeSpace();

  public Type typeof() { return Sys.FileStoreType; }

}
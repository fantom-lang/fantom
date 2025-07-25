//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jun 25  Brian Frank  Creation
//
package fan.util;

import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.channels.FileLock;
import fan.sys.*;
import fanx.interop.*;

public final class LockFile extends FanObj
{

  public static LockFile make(File file)
  {
    return new LockFile(file);
  }

  private LockFile(File file) { this.file = file; }

  public Type typeof() { return typeof$(); }

  public static Type typeof$()
  {
    if (type == null) type = Type.find("util::LockFile");
    return type;
  }
  private static Type type;

  public File file() { return file; }

  public LockFile lock()
  {
    try
    {
      file.parent().create();
      RandomAccessFile fp = new RandomAccessFile(Interop.toJava(file), "rw");
      FileLock lock = null;
      try
      {
        lock = fp.getChannel().tryLock();
      }
      catch (Exception e)
      {
        // OverlappingFileLockException when doing locks within the same JVM
      }
      if (lock == null) throw CannotAcquireLockFileErr.make(file.osPath());

      // save away the fp
      this.fp = fp;

      // write info about who is creating this lock file
      fp.writeBytes(
         "locked="  + DateTime.now() + "\n" +
         "homeDir=" + Env.cur().homeDir().osPath() + "\n" +
         "version=" + typeof().pod().version());
      fp.getFD().sync();
      return this;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public LockFile unlock()
  {
    try
    {
      if (fp != null) fp.close();
      Interop.toJava(file).delete();
      return this;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  private final File file;
  private RandomAccessFile fp;

}


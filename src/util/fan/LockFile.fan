//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 16  Brian Frank  Creation
//

using concurrent
using [java] fanx.interop
using [java] java.io::RandomAccessFile

**
** LockFile is used to acquire an exclusive lock to prevent
** two different processes from using same files
**
@Js
native const final class LockFile
{
  ** Construct with given file
  new make(File file)

  ** Backing file we use to lock/acquire
  File file()

  ** Acquire the lock or raise CannotAcquireLockFileErr
  This lock()

  ** Release the lock if we are holding one
  This unlock()

}

**************************************************************************
** CannotAcquireLockFileErr
**************************************************************************

** When another process has var directory locked
@NoDoc
const class CannotAcquireLockFileErr : Err
{
  new make(Str msg, Err? cause := null) : super(msg, cause) {}

  /*
  @NoDoc static Void main(Str[] args)
  {
    file := `test.lock`.toFile.normalize
    echo
    echo("Acquiring: $file.osPath ...")
    x := LockFile(file).lock
    echo("Acquired!")
    echo
    echo("Run this program in another console and verify CannotAcquireLockFileErr")
    echo("Waiting, use Ctrl+C to end ...")
    Actor.sleep(10sec)
    x.unlock
    echo("Unlocked!")
    Actor.sleep(1day)
  }
  */
}


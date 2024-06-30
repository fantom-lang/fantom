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
const class LockFile
{
  ** Construct with given file
  new make(File file) { this.file = file }

  ** Backing file we use to lock/acquire
  const File file

  private const AtomicRef fpRef := AtomicRef()

  ** Acquire the lock or raise CannotAcquireLockFileErr
  This lock()
  {
    // use java.nio.LockFile
    file.parent.create
    jfile := Interop.toJava(file)
    fp := RandomAccessFile(jfile, "rw")
    lock := null
    try
      lock = fp.getChannel.tryLock
    catch (Err e) // OverlappingFileLockException when doing locks within the same JVM
      {}
    if (lock == null) throw CannotAcquireLockFileErr(file.osPath)

    // save away the fp
    fpRef.val = Unsafe(fp)

    // write info about who is creating this lock file
    fp.writeBytes(
       """locked=${DateTime.now}
          homeDir=${Env.cur.homeDir.osPath}
          version=${typeof.pod.version}""")
    fp.getFD.sync
    return this
  }

  ** Release the lock if we are holding one
  This unlock()
  {
    fp := (fpRef.val as Unsafe)?.val as RandomAccessFile
    if (fp != null) fp.close
    Interop.toJava(file).delete
    return this
  }

  ** Command line test program
  @NoDoc static Void main(Str[] args)
  {
    file := `test.lock`.toFile.normalize
    echo
    echo("Acquiring: $file.osPath ...")
    LockFile(file).lock
    echo("Acquired!")
    echo
    echo("Run this program in another console and verify CannotAcquireLockFileErr")
    echo("Waiting, use Ctrl+C to end ...")
    Actor.sleep(1day)
  }
}

**************************************************************************
** CannotAcquireLockFileErr
**************************************************************************

** When another process has var directory locked
@NoDoc
const class CannotAcquireLockFileErr : Err
{
  new make(Str msg, Err? cause := null) : super(msg, cause) {}
}


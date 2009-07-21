//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 09  Brian Frank  Creation
//

**
** Repo models a Fan repository which is a directory in the
** file system used to store library and configuration files.
**
final const class Repo
{

//////////////////////////////////////////////////////////////////////////
// Lookup
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the working repo used to launch this Fan VM.  If the
  ** enviroment specifies no repo, then this is the boot repo.
  **
  static Repo working()

  **
  ** Get the bootstrap repo used to launch this Fan VM.
  **
  static Repo boot()

  **
  ** List the full set of inherited repos used to launch this Fan VM.
  ** The repos are ordered from highest priority (working) to lowest
  ** priority (boot).
  **
  static Repo[] list()

  **
  ** Private constructor.
  **
  private new make()

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the name assigned to this repo.  The working
  ** repo is always named "working", and the bootstrap repo is
  ** always "boot".  If the working repo is the same as the
  ** boot repo, then name is "boot".
  **
  Str name()

  **
  ** Get the home directory of the repo.
  **
  File home()

  **
  ** Hashcode is based on reference.
  **
  override Int hash()

  **
  ** Two repos are equal by reference.
  **
  override Bool equals(Obj? that)

  **
  ** Return infomation about repo is unspecified string format.
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// Files
//////////////////////////////////////////////////////////////////////////

  **
  ** Find a file in the list of repos according to priority order.
  ** The Uri should be relative such as "etc/sys/log.fansym" or
  ** ArgErr is thrown.  If the file is not found in any of the current
  ** repos then throw IOErr or return null based on checked flag.
  **
  static File? findFile(Uri uri, Bool checked := true)

  **
  ** Find all the files in the list of repos according to priority order.
  ** The Uri should be relative such as "etc/sys/log.fansym" or
  ** ArgErr is thrown.  Return empty list if the file is not found
  ** in any of the current repos.
  **
  static File[] findAllFiles(Uri uri)

  **
  ** Find all the fansym files referenced by the uri via `findAllFiles`.
  ** Parse them into a merged map according to priority order via
  ** `InStream.readSymbols`.  If no files are found then return an
  ** empty map.  This method always parses the found files, see
  ** `readSymbolsCached` to cache the result for subsequent calls.
  **
  static Str:Obj? readSymbols(Uri uri)

  **
  ** Read a set of merge fansym files via `readSymbols`.  This
  ** version caches the resulting map so that subsequent calls for
  ** the same uri doesn't require accessing the file system again.  The
  ** maxAge parameter specifies the tolerance accepted before a cache
  ** refresh is performed to check if any of the fansym files have
  ** been modified.  Throw NotImmutableErr is any of the symbol
  ** values are mutable.
  **
  static Str:Obj? readSymbolsCached(Uri uri, Duration maxAge := 1sec)

}
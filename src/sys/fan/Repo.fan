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
  File dir()

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

}
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 06  Brian Frank  Creation
//

**
** Version is defined as a list of decimal digits separated
** by the dot.  Convention for Fan pods is a four part version
** format of 'major.minor.build.patch'.
**
@simple
const final class Version
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a string representation into a Version.
  ** If invalid format and checked is false return null,
  ** otherwise throw ParseErr.
  **
  static Version? fromStr(Str version, Bool checked := true)

  **
  ** Construct with list of integer segments.
  ** Throw ArgErr if segments is empty or contains negative numbers.
  **
  static Version make(Int[] segments)

  **
  ** Private constructor
  **
  private new privateMake()

//////////////////////////////////////////////////////////////////////////
// Obj Overrides
//////////////////////////////////////////////////////////////////////////

  **
  ** Return true if equal segments.
  **
  override Bool equals(Obj? obj)

  **
  ** Compare from from most significant segment to least significant
  ** segment.
  **
  ** Examples:
  **   1.6 > 1.4
  **   2.0 > 1.9
  **   1.2.3 > 1.2
  **   1.11 > 1.9.3
  **
  override Int compare(Obj obj)

  **
  ** Return toStr.hash
  **
  override Int hash()

  **
  ** The string format is equivalent to segments.join(".")
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Get a readonly list of the integer segments.
  **
  Int[] segments()

  **
  ** Get the first, most significant segment which represents the major version.
  **
  Int major()

  **
  ** Get the second segment which represents the minor version.
  ** If return null if less than two segments.
  **
  Int? minor()

  **
  ** Get the third segment which represents the build number.
  ** If return null if less than three segments.
  **
  Int? build()

  **
  ** Get the fourth segment which represents the patch number.
  ** If return null if less than four segments.
  **
  Int? patch()

}
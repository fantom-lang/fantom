//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Nov 06  Brian Frank  Creation
//

**
** Depend models a dependency as a pod name and a version
** constraint.  Convention for Fantom pods is a four part
** version format of 'major.minor.build.patch'.
**
** The string format for Depend:
**
**   <depend>        := <name> space* <constraints>
**   <constraints>   := <constraint> [space* "," space* <constraint>]*
**   <constraint>    := <versionSimple> | <versionPlus> | <versionRange>
**   <versionSimple> := <version>
**   <versionPlus>   := <version> space* "+"
**   <versionRange>  := <version> space* "-" space* <version>
**   <version>       := <digit> ["." <digit>]*
**   <digit>         := "0" - "9"
**
** Note a simple version constraint such as "foo 1.2" really means
** "1.2.*" - it  will match all build numbers and patch numbers
** within "1.2".  Likewise "foo 1.2.64" will match all patch numbers
** within the "1.2.64" build.  The "+" plus sign is used to specify a
** given version and anything greater.  The "-" dash is used to
** specify an inclusive range.  When using a range, then end version
** is matched using the same rules as a simple version - for example
** "4", "4.2", and "4.0.99" are all matches for "foo 1.2-4".  You may
** specify a list of potential constraints separated by commas - a match
** for the entire dependency is made if any one constraint is matched.
**
**  Examples:
**    "foo 1.2"      Any version of foo 1.2 with any build or patch number
**    "foo 1.2.64"   Any version of foo 1.2.64 with any patch number
**    "foo 0+"       Any version of foo - version wildcard
**    "foo 1.2+"     Any version of foo 1.2 or greater
**    "foo 1.2-1.4"  Any version between 1.2 and 1.4 inclusive
**    "foo 1.2,1.4"  Any version of 1.2 or 1.4
**
@Serializable { simple = true }
final const class Depend
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the string according into a dependency.  See class
  ** header for specification of the format.  If invalid format
  ** and checked is false return null, otherwise throw ParseErr.
  **
  static Depend? fromStr(Str s, Bool checked := true)

  **
  ** Private constructor
  **
  private new privateMake()

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Two Depends are equal if they have same normalized string representation.
  **
  override Bool equals(Obj? that)

  **
  ** Return a hash code based on the normalized string representation.
  **
  override Int hash()

  **
  ** Get the normalized string format of this dependency.  Normalized
  ** dependency strings do not contain any optional spaces.  See class
  ** header for specification of the format.
  **
  override Str toStr()

  **
  ** Get the pod name of the dependency.
  **
  Str name()

//////////////////////////////////////////////////////////////////////////
// Version Constraints
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the number of version constraints.  There is always
  ** at least one constraint.
  **
  Int size()

  **
  ** Get the version constraint at specified index:
  **   - versionSimple: returns the version
  **   - versionPlus:   returns the version
  **   - versionRange:  returns the start version
  **
  Version version(Int index := 0)

  **
  ** Return if the constraint at the specified index is a versionPlus:
  **   - versionSimple: returns false
  **   - versionPlus:   returns true
  **   - versionRange:  returns false
  **
  Bool isPlus(Int index := 0)

  **
  ** Return if the constraint at the specified index is a versionRange:
  **   - versionSimple: returns false
  **   - versionPlus:   returns false
  **   - versionRange:  returns true
  **
  Bool isRange(Int index := 0)

  **
  ** Return the ending version if versionRange:
  **   - versionSimple: returns null
  **   - versionPlus:   returns null
  **   - versionRange:  returns end version
  **
  Version endVersion(Int index := 0)

  **
  ** Return if the specified version is a match against
  ** this dependency's constraints.  See class header for
  ** matching rules.
  **
  Bool match(Version version)


}
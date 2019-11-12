//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 07  Brian Frank  Creation
//

**
** Regex represents a regular expression.
**
@Serializable { simple = true }
const final class Regex
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Compile a regular expression pattern string.  Flags is a string
  ** of ASCII chars.  In JavaScript the flags are passed directly to RegExp.
  ** In Java the flags are matched against known constants or ignored.
  ** The following cross-platform flags are supported:
  **   - 'i': case insensitive
  **   - 'm': multi-line support for start/end matching
  **   - 's': dot all to allow "." to match newlines
  **
  static new fromStr(Str pattern, Str flags := "")

  **
  ** Make a Regex which will match a glob pattern:
  **   - "?": match one unknown char (maps to "." in regex)
  **   - "*": match zero or more unknown char (maps to ".*" in regex)
  **   - any other character is matched exactly
  **
  static Regex glob(Str pattern)

  **
  ** Make a Regex that matches the given string exactly.
  ** All non-alpha numeric characters are escaped.
  **
  static Regex quote(Str str)

  **
  ** Private constructor.
  **
  private new make()

  **
  ** Default value is Regex("").
  **
  const static Regex defVal

//////////////////////////////////////////////////////////////////////////
// Obj Overrides
//////////////////////////////////////////////////////////////////////////

  **
  ** Equality is based on pattern string and flags.
  **
  override Bool equals(Obj? obj)

  **
  ** Return 'toStr.hash'.
  **
  override Int hash()

  **
  ** Return the regular expression pattern string.
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Return flags string
  **
  Str flags()

  **
  ** Convenience for [matcher(s).matches]`RegexMatcher.matches`.
  **
  Bool matches(Str s)

  **
  ** Return a 'RegexMatcher' instance to use for matching
  ** operations against the specified string.
  **
  RegexMatcher matcher(Str s)

  **
  ** Split the specified string around matches of this pattern.
  ** The 'limit' parameter specifies how many times to apply
  ** the pattern:
  **   - If 'limit' is greater than zero, the pattern is applied
  **     at most 'limit-1' times and any remaining input will
  **     be returned as the list's last item.
  **   - If 'limit' is less than zero, then the pattern is
  **     matched as many times as possible.
  **   - If 'limit' is zero, then the pattern is matched as many
  **     times as possible, but trailing empty strings are
  **     discarded.
  **
  Str[] split(Str s, Int limit := 0)

}
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Dec 05  Brian Frank  Creation
//

**
** Bool represents a boolean condition of true or false.
**
@Serializable { simple = true }
const final class Bool
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a Str into a Bool.  Valid formats are "true" or "false".
  ** If invalid format and checked is false return null, otherwise
  ** throw ParseErr.
  **
  static Bool? fromStr(Str s, Bool checked := true)

  **
  ** Private constructor.
  **
  private new privateMake()

  **
  ** Default value is false.
  **
  const static Bool defVal

//////////////////////////////////////////////////////////////////////////
// Obj Overrides
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if same boolean value.
  **
  override Bool equals(Obj? obj)

  **
  ** Return 1231 for true and 1237 for false.
  **
  override Int hash()

  **
  ** Return "true" or "false".
  **
  override Str toStr()

  **
  ** Return localized strings for "true" and "false" using current locale.
  **
  Str toLocale()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the logical not: if true return false; if false return true.
  **
  Bool not()

  **
  ** Bitwise "and" of this and b.  Shortcut is a&b.  Note boolean bitwise
  ** "and" does not short circuit like logical "and" (&& operator).
  **
  Bool and(Bool b)

  **
  ** Bitwise "or" of this and b.  Shortcut is a|b.  Note boolean bitwise
  ** "or" does not short circuit like logical "or" (|| operator).
  **
  Bool or(Bool b)

  **
  ** Bitwise "exclusive-or" of this and b.  Shortcut is a^b.  Note this
  ** operator does not short circuit like && or ||.
  **
  Bool xor(Bool b)

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  **
  ** Get this Bool as a Fantom code literal - returns `toStr`.
  **
  Str toCode()

}
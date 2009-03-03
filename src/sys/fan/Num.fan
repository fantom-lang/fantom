//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Mar 06  Brian Frank  Creation
//

**
** Num is the base class for number classes: `Int`, `Float`, and `Decimal`.
**
abstract const class Num
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** internal constructor.
  **
  internal new make()

//////////////////////////////////////////////////////////////////////////
// Virtuals
//////////////////////////////////////////////////////////////////////////

  **
  ** Convert this number to an Int.
  **
  Int toInt()

  **
  ** Convert this number to a Float.
  **
  Float toFloat()

  **
  ** Convert this number to a Decimal.
  **
  Decimal toDecimal()

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the current locale's decimal separator character.
  ** For example in the the US this is a dot.
  **
  static Int localeDecimal()

  **
  ** Get the current locale's separator character for grouping thousands
  ** together.  For example in the the US this is a comma.
  **
  static Int localeGrouping()

  **
  ** Get the current locale's minus sign used to represent a negative number.
  **
  static Int localeMinus()

  **
  ** Get the current locale's character for the percent sign.
  **
  static Int localePercent()

  **
  ** Get the current locale's string representation for infinity.
  **
  static Str localeInf()

  **
  ** Get the current locale's string representation for not-a-number.
  **
  static Str localeNaN()

}
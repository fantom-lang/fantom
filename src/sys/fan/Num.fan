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
  ** Protected constructor.
  **
  protected new make()

//////////////////////////////////////////////////////////////////////////
// Virtuals
//////////////////////////////////////////////////////////////////////////

  **
  ** Convert this number to an Int.
  **
  virtual Int toInt()

  **
  ** Convert this number to a Float.
  **
  virtual Float toFloat()

  **
  ** Convert this number to a Decimal.
  **
  virtual Decimal toDecimal()

}
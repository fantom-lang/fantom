//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 05  Brian Frank  Creation
//

**
** Range represents a contiguous range of integers from start to
** end.  Ranges may be represented as literals in Fantom source code as
** "start..end" for an inclusive end or "start..<end" for an exlusive
** range.
**
@Serializable { simple = true }
const final class Range
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Convenience for make(start, end, false).
  **
  new makeInclusive(Int start, Int end)

  **
  ** Convenience for make(start, end, true).
  **
  new makeExclusive(Int start, Int end)

  **
  ** Constructor with start, end, and exclusive flag (all must be non-null).
  **
  new make(Int start, Int end, Bool exclusive)

  **
  ** Parse from string format - inclusive is "start..end", or
  ** exclusive is "start..<end".  If invalid format then
  ** throw ParseErr or return null based on checked flag.
  **
  static Range? fromStr(Str s, Bool checked := true)

//////////////////////////////////////////////////////////////////////////
// Obj Overrides
//////////////////////////////////////////////////////////////////////////

  **
  ** Return true if same start, end, and exclusive.
  **
  override Bool equals(Obj? obj)

  **
  ** Return start ^ end.
  **
  override Int hash()

  **
  ** If inclusive return "start..end", if exclusive return "start..<end".
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Return start index.
  **
  ** Example:
  **   (1..3).start  =>  1
  **
  Int start()

  **
  ** Return end index.
  **
  ** Example:
  **   (1..3).end  =>  3
  **
  Int end()

  **
  ** Is the end index inclusive.
  **
  ** Example:
  **   (1..3).inclusive   =>  true
  **   (1..<3).inclusive  =>  false
  **
  Bool inclusive()

  **
  ** Is the end index exclusive.
  **
  ** Example:
  **   (1..3).exclusive   =>  false
  **   (1..<3).exclusive  =>  true
  **
  Bool exclusive()

  **
  ** Return if this range contains no integer values.
  ** Equivalent to 'toList.isEmpty'.
  **
  Bool isEmpty()

  **
  ** Get the minimum value of the range. If range contains
  ** no values then return null.  Equivalent to 'toList.min'.
  **
  Int? min()

  **
  ** Get the maximum value of the range. If range contains
  ** no values then return null.  Equivalent to 'toList.max'.
  **
  Int? max()

  **
  ** Get the first value of the range.   If range contains
  ** no values then return null.  Equivalent to 'toList.first'.
  **
  Int? first()

  **
  ** Get the last value of the range.   If range contains
  ** no values then return null.  Equivalent to 'toList.last'.
  **
  Int? last()

  **
  ** Return if this range contains the specified integer.
  **
  ** Example:
  **   (1..3).contains(2)  =>  true
  **   (1..3).contains(4)  =>  false
  **
  Bool contains(Int i)

  **
  ** Create a new range by adding offset to this range's
  ** start and end values.
  **
  ** Example:
  **   (3..5).offset(2)   =>  5..7
  **   (3..<5).offset(-2) =>  1..<3
  **
  Range offset(Int offset)

  **
  ** Call the specified function for each integer in the range.
  **
  ** Example:
  **   ('a'..'z').each |Int i| { echo(i) }
  **
  Void each(|Int i| c)

  **
  ** Create a new list which is the result of calling c for
  ** every integer in the range.  The new list is typed based on
  ** the return type of c.
  **
  ** Example:
  **   (10..15).map |i->Str| { i.toHex }  =>  Str[a, b, c, d, e, f]
  **
  Obj?[] map(|Int i->Obj?| c)

  **
  ** Convert this range into a list of Ints.
  **
  ** Example:
  **   (2..4).toList   =>  [2,3,4]
  **   (2..<4).toList  =>  [2,3]
  **   (10..8).toList  =>  [10,9,8]
  **
  Int[] toList()

  **
  ** Convenience for [Int.random(this)]`Int.random`.
  **
  Int random()

}
//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 11  Brian Frank  Creation
//

**
** Optimized fixed size array of booleans packed into words
** of 32-bits.  The array values default to false.
**
native final class BoolArray
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  ** Create a array of given size
  static new make(Int size)

  ** Private constructor
  private new privateMake()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  ** Get number of booleans in the array
  Int size()

  ** Get the boolean at the given index.
  ** Negative indices are *not* supported.
  @Operator Bool get(Int index)

  ** Set the boolean at the given index.
  ** Negative indices are *not* supported.
  @Operator Void set(Int index, Bool val)

  ** Fill this array with the given boolean value.  If range is null
  ** then the entire array is filled, otherwise just the specified range.
  ** Return this.
  This fill(Bool val, Range? range := null)
}
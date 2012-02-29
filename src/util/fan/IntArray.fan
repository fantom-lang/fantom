//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Oct 11  Brian Frank  Creation
//

**
** Optimized fixed size array of 1, 2, 4, or 8 byte unboxed integers.
** The array values default to zero.
**
native class IntArray
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  ** Create a signed 8-bit, 1-byte integer array (-128 to 127).
  static IntArray makeS1(Int size)

  ** Create a unsigned 8-bit, 1-byte integer array (0 to 255).
  static IntArray makeU1(Int size)

  ** Create a signed 16-bit, 2-byte integer array (-32_768 to 32_767).
  static IntArray makeS2(Int size)

  ** Create a unsigned 16-bit, 2-byte integer array (0 to 65_535).
  static IntArray makeU2(Int size)

  ** Create a signed 32-bit, 4-byte integer array (-2_147_483_648 to 2_147_483_647).
  static IntArray makeS4(Int size)

  ** Create a unsigned 32-bit, 4-byte integer array (0 to 4_294_967_295).
  static IntArray makeU4(Int size)

  ** Create a signed 64-bit, 8-byte integer array.
  static IntArray makeS8(Int size)

  ** Protected constructor for implementation classes
  internal new make()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  ** Get number of integers in the array
  Int size()

  ** Get the integer at the given index.
  ** Negative indices are *not* supported.
  @Operator Int get(Int index)

  ** Set the integer at the given index.
  ** Negative indices are *not* supported.
  @Operator Void set(Int index, Int val)

  ** Copy the integers from 'that' array into this array and return
  ** this.  The 'thatRange' parameter may be used to specify
  ** a specific range of integers from the 'that' parameter (negative
  ** indices *are* allowed) to copy.  If 'thatRange' is null then the entire
  ** range of 'that' is copied.  Or 'thisOffset' specifies the starting index
  ** of this index to copy the first integer.  Raise an exception if this
  ** array is not properly sized or is not of the same signed/byte count
  ** as the 'that' array.
  This copyFrom(IntArray that, Range? thatRange := null, Int thisOffset := 0)

  ** Fill this array with the given integer value.  If range is null
  ** then the entire array is filled, otherwise just the specified range.
  ** Return this.
  This fill(Int val, Range? range := null)

  ** Sort the integers in this array.  If range is null then the
  ** entire array is sorted, otherwise just the specified range.
  ** Return this.
  This sort(Range? range := null)
}
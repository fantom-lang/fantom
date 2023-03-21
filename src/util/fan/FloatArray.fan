//
// Copyright (c) 2012, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Feb 12  Brian Frank  Creation
//

**
** Optimized fixed size array of 4 or 8 byte unboxed floats.
** The array values default to zero.
**
@Js
native class FloatArray
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  ** Create a 32-bit float array.
  static FloatArray makeF4(Int size)

  ** Create a 64-bit float array.
  static FloatArray makeF8(Int size)

  ** Protected constructor for implementation classes
  internal new make()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  ** Get number of floats in the array
  Int size()

  ** Get the float at the given index.
  ** Negative indices are *not* supported.
  @Operator Float get(Int index)

  ** Set the float at the given index.
  ** Negative indices are *not* supported.
  @Operator Void set(Int index, Float val)

  ** Copy the floats from 'that' array into this array and return
  ** this.  The 'thatRange' parameter may be used to specify
  ** a specific range of floats from the 'that' parameter (negative
  ** indices *are* allowed) to copy.  If 'thatRange' is null then the entire
  ** range of 'that' is copied.  Or 'thisOffset' specifies the starting index
  ** of this index to copy the first float.  Raise an exception if this
  ** array is not properly sized or is not of the same signed/byte count
  ** as the 'that' array.
  This copyFrom(FloatArray that, Range? thatRange := null, Int thisOffset := 0)

  ** Fill this array with the given float value.  If range is null
  ** then the entire array is filled, otherwise just the specified range.
  ** Return this.
  This fill(Float val, Range? range := null)

  ** Sort the floats in this array.  If range is null then the
  ** entire array is sorted, otherwise just the specified range.
  ** Return this.
  This sort(Range? range := null)
}
//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Aug 2021 Matthew Giannini Creation
//

**
** Immutable arbitrary-precision integer.
**
native const class BigInt
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  static new fromStr(Str s, Int radix := 10, Bool checked := true)

  ** Default value is 0.
  static const BigInt defVal
  static const BigInt zero
  static const BigInt one

  new makeInt(Int val)
  new makeBuf(Buf bytes)

  private new privateMake()

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  override Bool equals(Obj? obj)

  override Int compare(Obj obj)

  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  ** -1, 0, 1 if the BigInt is negative, zero, or positive.
  Int signum()

  ** Convert the number to an Int.
  **
  ** If the value is out-of-range and checked is true, an Err is thrown.
  ** Otherwise the value is truncated, with possible loss of sign.
  Int toInt(Bool checked := true)

  Buf toBuf()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  ////////// unary //////////

  @Operator BigInt negate()

  @Operator BigInt increment()

  @Operator BigInt decrement()

//////////////////////////////////////////////////////////////////////////
// Bitwise
//////////////////////////////////////////////////////////////////////////

  BigInt setBit(Int b)

  BigInt clearBit(Int b)

  BigInt flipBit(Int b)

  Bool testBit(Int b)

  ** Returns the number of bits in the minimal two's-complement
  ** representation of this BigInteger, excluding a sign bit.
  Int bitLen()

  BigInt not()

  BigInt and(Obj b)

  BigInt or(Obj b)

  BigInt xor(Obj b)

  BigInt shiftl(Int b)

  BigInt shftr(Int b)

}
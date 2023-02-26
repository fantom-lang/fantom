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

  ** Parse a Str into a BigInt using the specified radix.
  ** If invalid format and checked is false return null,
  ** otherwise throw ParseErr.
  static new fromStr(Str s, Int radix := 10, Bool checked := true)

  ** Default value is 0.
  static const BigInt defVal
  static const BigInt zero
  static const BigInt one

  ** Returns a BigInt whose value is equal to that of
  ** the specified Int. 
  new makeInt(Int val)

  ** Translates a byte array containing the two's-complement binary
  ** representation of a BigInt into a BigInt.
  new makeBuf(Buf bytes)

  ** Private constructor.
  private new privateMake()

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  ** Return true if same both represent that same integer value.
  override Bool equals(Obj? obj)

  ** Compare based on integer value.
  override Int compare(Obj obj)

  ** Return decimal string representation.
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

  ** Returns a byte array containing the two's-complement representation
  ** of this BigInt.
  Buf toBuf()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  ////////// unary //////////

  ** Negative of this.  Shortcut is -a.
  @Operator BigInt negate()

  ** Increment by one.  Shortcut is ++a or a++.
  @Operator BigInt increment()

  ** Decrement by one.  Shortcut is --a or a--.
  @Operator BigInt decrement()

//////////////////////////////////////////////////////////////////////////
// Bitwise
//////////////////////////////////////////////////////////////////////////

  ** Set the given bit to 1.
  ** Equivalent to this.or(1.shiftl(b)).
  BigInt setBit(Int b)

  ** Set the given bit to 0.
  ** Equivalent to this.and(1.shiftl(b).not).
  BigInt clearBit(Int b)

  ** Flip the given bit between 0 and 1.
  ** Equivalent to this.xor(1.shiftl(b)).
  BigInt flipBit(Int b)

  ** Return true if given bit is 1.
  ** Equivalent to this.and(1.shiftl(b)) != 0.
  Bool testBit(Int b)

  ** Returns the number of bits in the minimal two's-complement
  ** representation of this BigInteger, excluding a sign bit.
  Int bitLen()

  ** Bitwise not/inverse of this.
  BigInt not()

  ** Bitwise-and of this and b.
  BigInt and(Obj b)

  ** Bitwise-or of this and b.
  BigInt or(Obj b)

  ** Bitwise-exclusive-or of this and b.
  BigInt xor(Obj b)

  ** Bitwise left shift of this by b.
  ** Negative values call shiftr instead.
  BigInt shiftl(Int b)

  ** Bitwise arithmetic right-shift of this by b.  Note that this is
  ** similar to Int.shifta, not Int.shiftr.  Sign extension is performed.
  ** Negative values call shiftl instead.
  BigInt shiftr(Int b)

}
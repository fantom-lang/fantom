//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Aug 2021 Matthew Giannini Creation
//   26 Feb 2023 Jeremy Criquet Added many of the common methods from java's BigInteger
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

  ** The hash for a BigInt is platform dependent.
  override Int hash()

//////////////////////////////////////////////////////////////////////////
// Operations
//////////////////////////////////////////////////////////////////////////

  ////////// unary //////////

  ** Negative of this.  Shortcut is -a.
  @Operator BigInt negate()

  ** Increment by one.  Shortcut is ++a or a++.
  @Operator BigInt increment()

  ** Decrement by one.  Shortcut is --a or a--.
  @Operator BigInt decrement()

  ////////// mult //////////

  ** Multiply this with b.  Shortcut is a*b.
  @Operator BigInt mult(BigInt b)

  ** Multiply this with b.  Shortcut is a*b.
  @Operator BigInt multInt(Int b)

  ////////// div //////////

  ** Divide this by b.  Shortcut is a/b.
  @Operator BigInt div(BigInt b)

  ** Divide this by b.  Shortcut is a/b.
  @Operator BigInt divInt(Int b)

  ////////// mod //////////

  ** Return remainder of this divided by b.  Shortcut is a%b.
  @Operator BigInt mod(BigInt b)

  ** Return remainder of this divided by b.  Shortcut is a%b.
  @Operator Int modInt(Int b)

  ////////// plus //////////

  ** Add this with b.  Shortcut is a+b.
  @Operator BigInt plus(BigInt b)

  ** Add this with b.  Shortcut is a+b.
  @Operator BigInt plusInt(Int b)

  ////////// minus //////////

  ** Subtract b from this.  Shortcut is a-b.
  @Operator BigInt minus(BigInt b)

  ** Subtract b from this.  Shortcut is a-b.
  @Operator BigInt minusInt(Int b)

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

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  ** -1, 0, 1 if the BigInt is negative, zero, or positive.
  Int signum()

  ** Return the absolute value of this integer.  If this value is
  ** positive then return this, otherwise return the negation.
  BigInt abs()

  ** Return the smaller of this and the specified BigInt values.
  BigInt min(BigInt that)

  ** Return the larger of this and the specified BigInt values.
  BigInt max(BigInt that)

  ** Return this value raised to the specified power.
  ** Throw ArgErr if pow is less than zero.
  BigInt pow(Int pow)

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  ** Convert the number to an Int.
  **
  ** If the value is out-of-range and checked is true, an Err is thrown.
  ** Otherwise the value is truncated, with possible loss of sign.
  Int toInt(Bool checked := true)

  ** Convert the number to an Float.
  **
  ** If the value is out-of-range, it will return Float.posInf
  ** or Float.negInf.  Possible loss of precision is still possible, even
  ** if the value is finite.
  Float toFloat()

  ** Convert the number to an Decimal.
  **
  ** This simply wraps the BigInt with Decimal with a 0 scale,
  ** equivilent mathematically to int * 2^0
  Decimal toDecimal()

  ** Returns a byte array containing the two's-complement representation
  ** of this BigInt.
  Buf toBuf()

  ** Return decimal string representation.
  override Str toStr()

  ** Return string representation in given radix.  If width is non-null,
  ** then leading zeros are prepended to ensure the specified width.
  Str toRadix(Int radix, Int? width := null)

}
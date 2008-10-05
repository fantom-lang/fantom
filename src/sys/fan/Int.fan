//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Dec 05  Brian Frank  Creation
//

**
** Int is used to represent a signed 64-bit integer.
**
const final class Int : Num
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a Str into a Int using the specified radix.
  ** If invalid format and checked is false return null,
  ** otherwise throw ParseErr.
  **
  static Int fromStr(Str s, Int radix := 10, Bool checked := true)

  **
  ** Generate a random number.  If range is null then all 2^64
  ** integer values (both negative and positive) are produced with
  ** equal probability.  If range is non-null, then the result
  ** is guaranteed to be inclusive of the range.
  **
  ** Examples:
  **   r := Int.random
  **   r := Int.random(0..100)
  **
  static Int random(Range r := null)

  **
  ** Private constructor.
  **
  private new make()

  **
  ** Maximum value which can be stored in a
  ** signed 64-bit Int: 9,223,372,036,854,775,807
  **
  const static Int maxValue

  **
  ** Minimum value which can be stored in a
  ** signed 64-bit Int: -9,223,372,036,854,775,808
  **
  const static Int minValue

//////////////////////////////////////////////////////////////////////////
// Obj Overrides
//////////////////////////////////////////////////////////////////////////

  **
  ** Return true if same integer value.
  **
  override Bool equals(Obj obj)

  **
  ** Compare based on integer value.
  **
  override Int compare(Obj obj)

  **
  ** Return this.
  **
  override Int hash()

//////////////////////////////////////////////////////////////////////////
// Operations
//////////////////////////////////////////////////////////////////////////

  **
  ** Negative of this.  Shortcut is -a.
  **
  Int negate()

  **
  ** Bitwise inverse of this.  Shortcut is  ~a.
  **
  Int inverse()

  **
  ** Multiply this with b.  Shortcut is a*b.
  **
  Int mult(Int b)

  **
  ** Divide this by b.  Shortcut is a/b.
  **
  Int div(Int b)

  **
  ** Return remainder of this divided by b.  Shortcut is a%b.
  **
  Int mod(Int b)

  **
  ** Add this with b.  Shortcut is a+b.
  **
  Int plus(Int b)

  **
  ** Subtract b from this.  Shortcut is a-b.
  **
  Int minus(Int b)

  **
  ** Bitwise-and of this and b.  Shortcut is a&b.
  **
  Int and(Int b)

  **
  ** Bitwise-or of this and b.  Shortcut is a|b.
  **
  Int or(Int b)

  **
  ** Bitwise-exclusive-or of this and b.  Shortcut is a^b.
  **
  Int xor(Int b)

  **
  ** Bitwise left shift of this by b.  Shortcut is a<<b.
  **
  Int lshift(Int b)

  **
  ** Bitwise right shift of this by b.  Shortcut is a>>b.
  **
  Int rshift(Int b)

  **
  ** Increment by one.  Shortcut is ++a or a++.
  **
  Int increment()

  **
  ** Decrement by one.  Shortcut is --a or a--.
  **
  Int decrement()

/////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the absolute value of this integer.  If this value is
  ** positive then return this, otherwise return the negation.
  **
  Int abs()

  **
  ** Return the smaller of this and the specified Int values.
  **
  Int min(Int that)

  **
  ** Return the larger of this and the specified Int values.
  **
  Int max(Int that)

  **
  ** Return if this integer is evenly divisible by two.
  **
  Bool isEven()

  **
  ** Return if this integer is not evenly divisible by two.
  **
  Bool isOdd()

/////////////////////////////////////////////////////////////////////////
// Char
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if this Unicode char is whitespace: space \t \n \r \f
  **
  Bool isSpace()

  **
  ** Return if this Unicode char is an ASCII alpha char: isUpper||isLower
  **
  Bool isAlpha()

  **
  ** Return if this Unicode char is an ASCII alpha-numeric char: isAlpha||isDigit
  **
  Bool isAlphaNum()

  **
  ** Return if this Unicode char is an ASCII uppercase alphabetic char: A-Z
  **
  Bool isUpper()

  **
  ** Return if this Unicode char is an ASCII lowercase alphabetic char: a-z
  **
  Bool isLower()

  **
  ** If this Unicode char is an ASCII lowercase char, then return
  ** it as uppercase, otherwise return this.
  **
  ** Example:
  **   'a'.upper => 'A'
  **   '4'.upper => '4'
  **
  Int upper()

  **
  ** If this Unicode char is an ASCII uppercase char, then return
  ** it as lowercase, otherwise return this.
  **
  ** Example:
  **   'A'.lower => 'a'
  **   'h'.lower => 'h'
  **
  Int lower()

  **
  ** Return if this Unicode char is an digit in the specified radix.
  ** A decimal radix of ten returns true for 0-9.  A radix of 16
  ** also returns true for a-f and A-F.
  **
  ** Example:
  **   '3'.toDigit     => true
  **   3.toDigit       => false
  **   'B'.toDigit(16) => true
  **
  Bool isDigit(Int radix := 10)

  **
  ** Convert this number into a Unicode char '0'-'9'.  If radix is
  ** is greater than 10, then use a lower case letter.  Return null if
  ** this number cannot be represented as a single digit character for
  ** the specified radix.
  **
  ** Example:
  **   3.toDigit      => '3'
  **   15.toDigit(16) => 'f'
  **   99.toDigit     => null
  **
  Int toDigit(Int radix := 10)

  **
  ** Convert a Unicode digit character into a number for the specified
  ** radix.  Return null if this char is not a valid digit.
  **
  ** Example:
  **   '3'.fromDigit     => 3
  **   'f'.fromDigit(16) => 15
  **   '%'.fromDigit     => null
  **
  Int fromDigit(Int radix := 10)

  **
  ** Return if the two Unicode chars are equal without regard
  ** to ASCII case.
  **
  Bool equalsIgnoreCase(Int ch)

/////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if this Unicode char is an uppercase letter in
  ** the current locale.  See also `localeIsLower` and `isUpper`.
  **
  Bool localeIsUpper()

  **
  ** Return if this Unicode char is a lowercase letter in
  ** the current locale.  See also `localeIsUpper` and `isLower`.
  **
  Bool localeIsLower()

  **
  ** If this Unicode char is a lowercase char, then return
  ** it as uppercase according to the current locale.  Note that
  ** Unicode contains some case conversion rules that don't work
  ** correctly on a single character, so `Str.localeLower` should
  ** be preferred.  See also `localeLower` and `upper`.
  **
  Int localeUpper()

  **
  ** If this Unicode char is an uppercase char, then return
  ** it as lowercase according to the current locale.  Note that
  ** Unicode contains some case conversion rules that don't work
  ** correctly on a single character, so `Str.localeLower` should
  ** be preferred.  See also `localeUpper` and `lower`.
  **
  Int localeLower()

/////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  **
  ** Return decimal string representation.
  **
  override Str toStr()

  **
  ** Return hexdecimal string representation.  If width is non-null,
  ** then leading zeros are prepended to ensure the specified number
  ** of nibble characters.
  **
  ** Examples:
  **   255.toHex     =>  "ff"
  **   255.toHex(4)  =>  "00ff"
  **
  Str toHex(Int width := null)

  **
  ** Map as a Unicode code point to a single character Str.
  **
  Str toChar()

/////////////////////////////////////////////////////////////////////////
// Closures
//////////////////////////////////////////////////////////////////////////

  **
  ** Call the specified function to this times passing the current counter.
  **
  Void times(|Int i| c)

}
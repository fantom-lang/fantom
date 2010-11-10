//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    2 Dec 05  Brian Frank  Creation
//   11 Oct 06  Brian Frank  Rename Real to Float
//

**
** Float is used to represent a 64-bit floating point number.
**
@Serializable { simple = true }
const final class Float : Num
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Make a Float for the specified 64-bit representation according
  ** IEEE 754 floating-point double format bit layout.  This method is
  ** paired with `Float.bits`.
  **
  static Float makeBits(Int bits)

  **
  ** Make a Float for the specified 32-bit representation according
  ** IEEE 754 floating-point single format bit layout.  This method is
  ** paired with `Float.bits32`.
  **
  static Float makeBits32(Int bits)

  **
  ** Parse a Str into a Float.  Representations for infinity and
  ** not-a-number are "-INF", "INF", "NaN".  This string format matches
  ** the lexical representation of Section 3.2.5 of XML Schema Part 2.
  ** If invalid format and checked is false return null, otherwise throw
  ** ParseErr.
  **
  ** TODO: need spec - follow XML Schema literal definition
  **
  static Float? fromStr(Str s, Bool checked := true)

  **
  ** Generate a random float between 0.0 inclusive and 1.0 exclusive.
  **
  static Float random()

  **
  ** Default value is 0f.
  **
  static const Float defVal

  **
  ** Private constructor.
  **
  private new privateMake()

  **
  ** Float value for positive infinity.
  **
  const static Float posInf

  **
  ** Float value for negative infinity.
  **
  const static Float negInf

  **
  ** Float value for Not-A-Number.
  **
  const static Float nan

  **
  ** Float value for e which is the base of natural logarithms.
  **
  const static Float e

  **
  ** Float value for pi which is the ratio of the
  ** circumference of a circle to its diameter.
  **
  const static Float pi

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Return true if same float value.  Like Java, NaN != NaN.
  ** Also see `compare`.
  **
  override Bool equals(Obj? obj)

  **
  ** Return if this Float is approximately equal to the given Float by the
  ** specified tolerance.  If tolerance is null, then it is computed
  ** using the magnitude of the two Floats.  It is useful for comparing
  ** Floats since often they lose a bit of precision during manipulation.
  ** This method is equivalent to:
  **   if (tolerance == null) tolerance = min(abs(this/1e6), abs(r/1e6))
  **   (this - r).abs < tolerance
  **
  Bool approx(Float r, Float? tolerance := null)

  **
  ** Compare based on floating point value.
  **
  ** NaN works as follows:
  **   - for the '<=>' operator NaN is always less than other
  **     values and equal to itself (so sort works as expected)
  **   - for all other comparison operators anything compared
  **     against NaN is false (normal Java semanatics)
  **
  ** Examples:
  **   Float.nan <=> Float.nan  =>  0
  **   2f <=> Float.nan         =>  1
  **   Float.nan <=> 2f         =>  -1
  **   2f < Float.nan           =>  false
  **   Float.nan < 2f           =>  false
  **   Float.nan <= Float.nan   =>  false
  **
  override Int compare(Obj obj)

  **
  ** Return if this is Float.nan.  Also see `compare`.
  **
  Bool isNaN()

  **
  ** Return bits().
  **
  override Int hash()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  ////////// unary //////////

  ** Negative of this.  Shortcut is -a.
  @Operator Float negate()

  ** Increment by one.  Shortcut is ++a or a++.
  @Operator Float increment()

  ** Decrement by one.  Shortcut is --a or a--.
  @Operator Float decrement()

  ////////// mult //////////

  ** Multiply this with b.  Shortcut is a*b.
  @Operator Float mult(Float b)

  ** Multiply this with b.  Shortcut is a*b.
  @Operator Float multInt(Int b)

  ** Multiply this with b.  Shortcut is a*b.
  @Operator Decimal multDecimal(Decimal b)

  ////////// div //////////

  ** Divide this by b.  Shortcut is a/b.
  @Operator Float div(Float b)

  ** Divide this by b.  Shortcut is a/b.
  @Operator Float divInt(Int b)

  ** Divide this by b.  Shortcut is a/b.
  @Operator Decimal divDecimal(Decimal b)

  ////////// mod //////////

  ** Return remainder of this divided by b.  Shortcut is a%b.
  @Operator Float mod(Float b)

  ** Return remainder of this divided by b.  Shortcut is a%b.
  @Operator Float modInt(Int b)

  ** Return remainder of this divided by b.  Shortcut is a%b.
  @Operator Decimal modDecimal(Decimal b)

  ////////// plus //////////

  ** Add this with b.  Shortcut is a+b.
  @Operator Float plus(Float b)

  ** Add this with b.  Shortcut is a+b.
  @Operator Float plusInt(Int b)

  ** Add this with b.  Shortcut is a+b.
  @Operator Decimal plusDecimal(Decimal b)

  ////////// minus //////////

  ** Subtract b from this.  Shortcut is a-b.
  @Operator Float minus(Float b)

  ** Subtract b from this.  Shortcut is a-b.
  @Operator Float minusInt(Int b)

  ** Subtract b from this.  Shortcut is a-b.
  @Operator Decimal minusDecimal(Decimal b)

/////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the absolute value of this float.  If this value is
  ** positive then return this, otherwise return the negation.
  **
  Float abs()

  **
  ** Return the smaller of this and the specified Float values.
  **
  Float min(Float that)

  **
  ** Return the larger of this and the specified Float values.
  **
  Float max(Float that)

  **
  ** Returns the smallest whole number greater than or equal
  ** to this number.
  **
  Float ceil()

  **
  ** Returns the largest whole number less than or equal to
  ** this number.
  **
  Float floor()

  **
  ** Returns the nearest whole number to this number.
  **
  Float round()

  **
  ** Return e raised to this power.
  **
  Float exp()

  **
  ** Return natural logarithm of this number.
  **
  Float log()

  **
  ** Return base 10 logarithm of this number.
  **
  Float log10()

  **
  ** Return this value raised to the specified power.
  **
  Float pow(Float pow)

  **
  ** Return square root of this value.
  **
  Float sqrt()

//////////////////////////////////////////////////////////////////////////
// Trig
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the arc cosine.
  **
  Float acos()

  **
  ** Return the arc sine.
  **
  Float asin()

  **
  ** Return the arc tangent.
  **
  Float atan()

  **
  ** Converts rectangular coordinates (x, y) to polar (r, theta).
  **
  static Float atan2(Float y, Float x)

  **
  ** Return the cosine of this angle in radians.
  **
  Float cos()

  **
  ** Return the hyperbolic cosine.
  **
  Float cosh()

  **
  ** Return sine of this angle in radians.
  **
  Float sin()

  **
  ** Return hyperbolic sine.
  **
  Float sinh()

  **
  ** Return tangent of this angle in radians.
  **
  Float tan()

  **
  ** Return hyperbolic tangent.
  **
  Float tanh()

  **
  ** Convert this angle in radians to an angle in degrees.
  **
  Float toDegrees()

  **
  ** Convert this angle in degrees to an angle in radians.
  **
  Float toRadians()

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  **
  ** Return 64-bit representation according IEEE 754 floating-point
  ** double format bit layout.  This method is paired with `Float.makeBits`.
  **
  Int bits()

  **
  ** Return 32-bit representation according IEEE 754 floating-point
  ** single format bit layout.  This method is paired with `Float.makeBits32`.
  **
  Int bits32()

  **
  ** Get string representation according to the lexical representation defined
  ** by Section 3.2.5 of XML Schema Part 2.  Representations for infinity and
  ** not-a-number are "-INF", "INF", "NaN".
  **
  override Str toStr()

  **
  ** Get this Float as a Fantom code literal.
  **
  Str toCode()

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  **
  ** Format this floating point number for the current locale.
  ** If pattern is null, then the locale's default pattern is used.
  ** Also see `Num.localeDecimal`, `Num.localeGrouping`, etc.
  **
  ** The pattern format:
  **   #   optional digit
  **   0   required digit
  **   .   decimal point
  **   ,   grouping separator (only last one before decimal matters)
  **
  ** Examples:
  **   12345.786f.toLocale("#,###.0")  =>  12,345.8
  **   7.1234f.toLocale("#.000")       =>  7.123
  **   0.1234f.toLocale("#.000")       =>  .123
  **   0.1234f.toLocale("0.00")        =>  0.12
  **   70.12f.toLocale("0.0000")       =>  70.1200
  **
  Str toLocale(Str? pattern := null)

}
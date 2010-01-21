//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Mar 06  Brian Frank  Creation
//   4 Oct 08  Brian Frank  Refactor Num into Number/FanNum
//
package fan.sys;

import java.math.*;
import java.text.DecimalFormatSymbols;

/**
 * FanNum defines the methods for sys::Num.  The actual
 * class used for representation is java.lang.Number.
 */
public class FanNum
{

  public static long toInt(Number self)
  {
    return self.longValue();
  }

  public static double toFloat(Number self)
  {
    return self.doubleValue();
  }

  public static BigDecimal toDecimal(Number self)
  {
    if (self instanceof BigDecimal) return (BigDecimal)self;
    if (self instanceof Long) return new BigDecimal(self.longValue());
    return new BigDecimal(self.doubleValue());
  }

  public static Type typeof(Number self) { return Sys.NumType; }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  public static String localeDecimal()
  {
    return FanInt.toChar(Locale.cur().decimal().getDecimalSeparator());
  }

  public static String localeGrouping()
  {
    return FanInt.toChar(Locale.cur().decimal().getGroupingSeparator());
  }

  public static String localeMinus()
  {
    return FanInt.toChar(Locale.cur().decimal().getMinusSign());
  }

  public static String localePercent()
  {
    return FanInt.toChar(Locale.cur().decimal().getPercent());
  }

  public static String localePosInf()
  {
    return Locale.cur().decimal().getInfinity();
  }

  public static String localeNegInf()
  {
    Locale locale = Locale.cur();
    return locale.decimal().getMinusSign() + locale.decimal().getInfinity();
  }

  public static String localeNaN()
  {
    return Locale.cur().decimal().getNaN();
  }

  static String toLocale(NumPattern p, NumDigits d, DecimalFormatSymbols df)
  {
    // string buffer
    StringBuilder s = new StringBuilder();
    if (d.negative) s.append(df.getMinusSign());

    // if we have more frac digits then maxFrac, then round off
    d.round(p.maxFrac);

    // if we have an optional integer part, and only
    // fractional digits, then don't include leading zero
    int start = 0;
    if (p.optInt && d.zeroInt()) start = d.decimal;

    // if min required fraction digits are zero and we
    // have nothing but zeros, then truncate to a whole number
    if (p.minFrac == 0 && d.zeroFrac(p.maxFrac)) d.size = d.decimal;

    // leading zeros
    for (int i=0; i<p.minInt-d.decimal; ++i) s.append('0');

    // walk thru the digits and apply locale symbols
    boolean decimal = false;
    for (int i=start; i<d.size; ++i)
    {
      if (i < d.decimal)
      {
        if ((d.decimal - i) % p.group == 0 && i > 0)
          s.append(df.getGroupingSeparator());
      }
      else
      {
        if (i == d.decimal && p.maxFrac > 0)
        {
          s.append(df.getDecimalSeparator());
          decimal = true;
        }
        if (i-d.decimal >= p.maxFrac) break;
      }
      s.append(d.digits[i]);
    }

    // trailing zeros
    for (int i=0; i<p.minFrac-d.fracSize(); ++i)
    {
      if (!decimal) { s.append(df.getDecimalSeparator()); decimal = true; }
      s.append('0');
    }

    // handle #.# case
    if (s.length() == 0) return "0";

    return s.toString();
  }

}

//////////////////////////////////////////////////////////////////////////
// NumDigits
//////////////////////////////////////////////////////////////////////////

/**
 * NumDigits is used to represents the character digits in
 * a number for locale pattern processing.  It inputs a long,
 * double, or BigDecimal into an array of digit chars and the
 * index to the decimal point.
 */
class NumDigits
{
  NumDigits(BigDecimal d)
  {
    this(d.toString());
  }

  NumDigits(String s)
  {
    digits = new char[s.length()+16];

    int expPos = -1;
    decimal = -99;
    for (int i=0; i<s.length(); ++i)
    {
      int c = s.charAt(i);
      if (c == '-') { negative = true; continue; }
      if (c == '.') { decimal = negative ? i-1 : i; continue; }
      if (c == 'e' || c == 'E') { expPos = i; break; }
      digits[size++] = (char)c;
    }
    if (decimal < 0) decimal = size;

    // if we had an exponent, then we need to normalize it
    if (expPos >= 0)
    {
      // move the decimal by the exponent
      int exp = Integer.parseInt(s.substring(expPos+1));
      decimal += exp;

      // add leading/trailing zeros as necessary
      if (decimal >= size)
      {
        while(size <= decimal) digits[size++] = '0';
      }
      else if (decimal < 0)
      {
        System.arraycopy(digits, 0, digits, -decimal, size);
        for (int i=0; i<-decimal; ++i) digits[i] = '0';
        size += -decimal;
        decimal = 0;
      }
    }
  }

  NumDigits(long d)
  {
    if (d < 0) { negative = true; d = -d; }
    String s = String.valueOf(d);
    if (s.charAt(0) == '-') s = "9223372036854775808"; // handle overflow case
    digits = s.toCharArray();
    size = decimal = digits.length;
  }

  int intSize()  { return decimal; }

  int fracSize() { return size - decimal; }

  boolean zeroInt()
  {
    for (int i=0; i<decimal; ++i) if (digits[i] != '0') return false;
    return true;
  }

  boolean zeroFrac(int maxFrac)
  {
    int until = decimal + maxFrac;
    for (int i=decimal; i<until; ++i) if (digits[i] != '0') return false;
    return true;
  }

  void round(int maxFrac)
  {
    // if frac sie already eq or less than maxFrac no rounding needed
    if (fracSize() <= maxFrac) return;

    // if we need to round, then round the prev digit
    if (digits[decimal+maxFrac] >= '5')
    {
      int i = decimal + maxFrac - 1;
      while (true)
      {
        if (digits[i] < '9') { digits[i]++; break; }
        digits[i--] = '0';
        if (i < 0)
        {
          System.arraycopy(digits, 0, digits, 1, size);
          digits[0] = '1'; size++; decimal++;
          break;
        }
      }
    }

    // update size and clip any trailing zeros
    size = decimal + maxFrac;
    while (digits[size-1] == '0' && size > decimal) size--;
  }

  public String toString()
  {
    return new String(digits, 0, size) + " neg=" + negative + " decimal=" + decimal;
  }

  char[] digits;       // char digits
  int decimal;         // index where decimal fits into digits
  int size;            // size of digits used
  boolean negative;    // is this a negative number
}

//////////////////////////////////////////////////////////////////////////
// NumPattern
//////////////////////////////////////////////////////////////////////////

/**
 * NumPattern parses and models a numeric locale pattern.
 */
final class NumPattern
{
  // pre-compute common patterns to avoid parsing
  private static java.util.HashMap cache = new java.util.HashMap();
  private static void cache(String p) { cache.put(p, new NumPattern(p)); }
  static
  {
    cache("00");    cache("000");       cache("0000");
    cache("0.0");   cache("0.00");      cache("0.000");
    cache("0.#");   cache("#,###.0");   cache("#,###.#");
    cache("0.##");  cache("#,###.00");  cache("#,###.##");
    cache("0.###"); cache("#,###.000"); cache("#,###.###");
    cache("0.0#");  cache("#,###.0#");  cache("#,###.0#");
    cache("0.0##"); cache("#,###.0##"); cache("#,###.0##");
  }

  static NumPattern parse(String s)
  {
    NumPattern x = (NumPattern)cache.get(s);
    if (x != null) return x;
    return new NumPattern(s);
  }

  private NumPattern(String s)
  {
    int group = Integer.MAX_VALUE;
    boolean optInt = true;
    boolean comma = false;
    boolean decimal = false;
    int minInt = 0, minFrac = 0, maxFrac = 0;
    int last = 0;
    for (int i=0; i<s.length(); ++i)
    {
      int c = s.charAt(i);
      switch (c)
      {
        case ',':
          comma = true;
          group = 0;
          break;
        case '0':
          if (decimal)
            { minFrac++; maxFrac++; }
          else
            minInt++;
          break;
        case '#':
          if (decimal)
            maxFrac++;
          else
            if (comma) group++;
          break;
        case '.':
          decimal = true;
          optInt  = last == '#';
          break;
      }
      last = c;
    }
    if (!decimal) optInt = last == '#';

    this.pattern = s;
    this.group   = group;
    this.optInt  = optInt;
    this.minInt  = minInt;
    this.minFrac = minFrac;
    this.maxFrac = maxFrac;
  }

  public String toString()
  {
    return pattern + " group=" + group + " minInt=" + minInt +
      " maxFrac=" + maxFrac + " minFrac=" + minFrac + " optInt=" + optInt;
  }

  final String pattern;  // pattern parsed
  final int group;       // grouping size (typically 3 for 1000)
  final boolean optInt;  // if we have "#." then the int part if optional (no leading zero)
  final int minInt;      // min digits in integer part (leading zeros)
  final int minFrac;     // min digits in fractional part (trailing zeros)
  final int maxFrac;     // max digits in fractional part (clipping)
}
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

  public static Type type(Number self) { return Sys.NumType; }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  public static long localeDecimal()
  {
    return Locale.current().decimal().getDecimalSeparator();
  }

  public static long localeGrouping()
  {
    return Locale.current().decimal().getGroupingSeparator();
  }

  public static long localeMinus()
  {
    return Locale.current().decimal().getMinusSign();
  }

  public static long localePercent()
  {
    return Locale.current().decimal().getPercent();
  }

  public static String localeInf()
  {
    return Locale.current().decimal().getInfinity();
  }

  public static String localeNaN()
  {
    return Locale.current().decimal().getNaN();
  }

}

//////////////////////////////////////////////////////////////////////////
// NumDigits
//////////////////////////////////////////////////////////////////////////

/**
 * NumDigits is used to represents the character digits in
 * a number for locale pattern processing.
 */
class NumDigits
{
  NumDigits(double d)
  {
    // use Double.toString to get the default string format
    int expPos = -1;
    String s = Double.toString(d);
    for (int i=0; i<s.length(); ++i)
    {
      int c = s.charAt(i);
      if (c == '-') { negative = true; continue; }
      if (c == '.') { decimal = negative ? i-1 : i; continue; }
      if (c == 'e' || c == 'E') { expPos = i; break; }
      digits[size++] = (char)c;
    }

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
    if (fracSize() <= maxFrac) return;
    if (digits[decimal+maxFrac] < '5') return;
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

  public String toString()
  {
    return new String(digits, 0, size) + " neg=" + negative + " decimal=" + decimal;
  }

  char[] digits = new char[64];  // char digits
  int decimal;                   // index where decimal fits into digits
  int size;                      // size of digits used
  boolean negative;              // is this a negative number
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
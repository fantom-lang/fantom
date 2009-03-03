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
class NumPattern
{
  NumPattern(String s)
  {
    pattern = s;
    group = Integer.MAX_VALUE;
    boolean comma = false;
    boolean decimal = false;
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
          break;
      }
    }
  }

  public String toString()
  {
    return pattern + " group=" + group + " minInt=" + minInt + " maxFrac=" + maxFrac + " minFrac=" + minFrac;
  }

  String pattern;  // pattern parsed
  int group;       // grouping size (typically 3 for 1000)
  int minInt;      // min digits in integer part (leading zeros)
  int minFrac;     // min digits in fractional part (trailing zeros)
  int maxFrac;     // max digits in fractional part (clipping)
}
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Oct 06  Andy Frank  Creation
//   20 Oct 08  Andy Frank  Refactor Num into FanNum
//

using System;
using System.Collections;
using System.Globalization;
using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// FanNum defines the methods for sys::Num.  The actual
  /// class used for representation is Fan.Sys.Number.
  /// </summary>
  public abstract class FanNum
  {

    public static long toInt(Number self)
    {
      //if (self is long) return (long)self;
      return self.longValue();
    }

    public static double toFloat(Number self)
    {
      //if (self is double) return self;
      return self.doubleValue();
    }

    public static BigDecimal toDecimal(Number self)
    {
      if (self is BigDecimal) return (BigDecimal)self;
      //if (self is Long) return BigDecimal.valueOf(self.longValue());
      return BigDecimal.valueOf(self.doubleValue());
    }

    public static Type type(Number self) { return Sys.NumType; }

  //////////////////////////////////////////////////////////////////////////
  // Locale
  //////////////////////////////////////////////////////////////////////////

    public static string localeDecimal()
    {
      return Locale.cur().dec().NumberDecimalSeparator;
    }

    public static string localeGrouping()
    {
      return Locale.cur().dec().NumberGroupSeparator;
    }

    public static string localeMinus()
    {
      return Locale.cur().dec().NegativeSign;
    }

    public static string localePercent()
    {
      return Locale.cur().dec().PercentSymbol;
    }

    public static String localePosInf()
    {
      return Locale.cur().dec().PositiveInfinitySymbol;
    }

    public static String localeNegInf()
    {
      return Locale.cur().dec().NegativeInfinitySymbol;
    }

    public static String localeNaN()
    {
      return Locale.cur().dec().NaNSymbol;
    }

    internal static string toLocale(NumPattern p, NumDigits d, NumberFormatInfo df)
    {
      // string buffer
      StringBuilder s = new StringBuilder();
      if (d.negative) s.Append(df.NegativeSign);

      // if we have more frac digits then maxFrac, then round off
      d.round(p.maxFrac);

      // if we have an optional integer part, and only
      // fractional digits, then don't include leading zero
      int start = 0;
      if (p.optInt && d.zeroInt()) start = d.dec;

      // if min required fraction digits are zero and we
      // have nothing but zeros, then truncate to a whole number
      if (p.minFrac == 0 && d.zeroFrac(p.maxFrac)) d.size = d.dec;

      // leading zeros
      for (int i=0; i<p.minInt-d.dec; ++i) s.Append('0');

      // walk thru the digits and apply locale symbols
      bool dec = false;
      for (int i=start; i<d.size; ++i)
      {
        if (i < d.dec)
        {
          if ((d.dec - i) % p.group == 0 && i > 0)
            s.Append(df.NumberGroupSeparator);
        }
        else
        {
          if (i == d.dec && p.maxFrac > 0)
          {
            s.Append(df.NumberDecimalSeparator);
            dec = true;
          }
          if (i-d.dec >= p.maxFrac) break;
        }
        s.Append(d.digits[i]);
      }

      // trailing zeros
      for (int i=0; i<p.minFrac-d.fracSize(); ++i)
      {
        if (!dec) { s.Append(df.NumberDecimalSeparator); dec = true; }
        s.Append('0');
      }

      // handle #.# case
      if (s.Length == 0) return "0";

      return s.ToString();
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
  internal class NumDigits
  {
    internal NumDigits(BigDecimal d) : this(d.ToString())
    {
    }

    internal NumDigits(string s)
    {
      digits = new char[s.Length+16];

      int expPos = -1;
      dec = -99;
      for (int i=0; i<s.Length; ++i)
      {
        int c = s[i];
        if (c == '-') { negative = true; continue; }
        if (c == '.') { dec = negative ? i-1 : i; continue; }
        if (c == 'e' || c == 'E') { expPos = i; break; }
        digits[size++] = (char)c;
      }
      if (dec < 0) dec = size;

      // if we had an exponent, then we need to normalize it
      if (expPos >= 0)
      {
        // move the decimal by the exponent
        int exp = Convert.ToInt32(s.Substring(expPos+1));
        dec += exp;

        // add leading/trailing zeros as necessary
        if (dec >= size)
        {
          while(size <= dec) digits[size++] = '0';
        }
        else if (dec < 0)
        {
          Array.Copy(digits, 0, digits, -dec, size);
          for (int i=0; i<-dec; ++i) digits[i] = '0';
          size += -dec;
          dec = 0;
        }
      }
    }

    internal NumDigits(long d)
    {
      if (d < 0) { negative = true; d = -d; }
      string s = d.ToString();
      if (s[0] == '-') s = "9223372036854775808"; // handle overflow case
      digits = s.ToCharArray();
      size = dec = digits.Length;
    }

    internal int intSize()  { return dec; }

    internal int fracSize() { return size - dec; }

    internal bool zeroInt()
    {
      for (int i=0; i<dec; ++i) if (digits[i] != '0') return false;
      return true;
    }

    internal bool zeroFrac(int maxFrac)
    {
      int until = dec+ maxFrac;
      for (int i=dec; i<until; ++i) if (digits[i] != '0') return false;
      return true;
    }

    internal void round(int maxFrac)
    {
      // if frac sie already eq or less than maxFrac no rounding needed
      if (fracSize() <= maxFrac) return;

      // if we need to round, then round the prev digit
      if (digits[dec+maxFrac] >= '5')
      {
        int i = dec + maxFrac - 1;
        while (true)
        {
          if (digits[i] < '9') { digits[i]++; break; }
          digits[i--] = '0';
          if (i < 0)
          {
            Array.Copy(digits, 0, digits, 1, size);
            digits[0] = '1'; size++; dec++;
            break;
          }
        }
      }

      // update size and clip any trailing zeros
      size = dec + maxFrac;
      while (digits[size-1] == '0' && size > dec) size--;
    }

    public override string ToString()
    {
      return new String(digits, 0, size) + " neg=" + negative + " decimal=" + dec;
    }

    internal char[] digits;    // char digits
    internal int dec;          // index where decimal fits into digits
    internal int size;         // size of digits used
    internal bool negative;    // is this a negative number
  }

  //////////////////////////////////////////////////////////////////////////
  // NumPattern
  //////////////////////////////////////////////////////////////////////////

  /**
   * NumPattern parses and models a numeric locale pattern.
   */
  class NumPattern
  {
    // pre-compute common patterns to avoid parsing
    private static Hashtable m_cache = new Hashtable();
    private static void cache(string p) { m_cache[p] = new NumPattern(p); }

    static NumPattern()
    {
      cache("00");    cache("000");       cache("0000");
      cache("0.0");   cache("0.00");      cache("0.000");
      cache("0.#");   cache("#,###.0");   cache("#,###.#");
      cache("0.##");  cache("#,###.00");  cache("#,###.##");
      cache("0.###"); cache("#,###.000"); cache("#,###.###");
      cache("0.0#");  cache("#,###.0#");  cache("#,###.0#");
      cache("0.0##"); cache("#,###.0##"); cache("#,###.0##");
    }

    internal static NumPattern parse(string s)
    {
      NumPattern x = (NumPattern)m_cache[s];
      if (x != null) return x;
      return new NumPattern(s);
    }

    private NumPattern(string s)
    {
      int group = 999999;
      bool optInt = true;
      bool comma = false;
      bool dec = false;
      int minInt = 0, minFrac = 0, maxFrac = 0;
      int last = 0;
      for (int i=0; i<s.Length; ++i)
      {
        int c = s[i];
        switch (c)
        {
          case ',':
            comma = true;
            group = 0;
            break;
          case '0':
            if (dec)
              { minFrac++; maxFrac++; }
            else
              { minInt++; if (comma) group++; }
            break;
          case '#':
            if (dec)
              maxFrac++;
            else
              if (comma) group++;
            break;
          case '.':
            dec = true;
            optInt = last == '#';
            break;
        }
        last = c;
      }
      if (!dec) optInt = last == '#';

      this.pattern = s;
      this.group   = group;
      this.optInt  = optInt;
      this.minInt  = minInt;
      this.minFrac = minFrac;
      this.maxFrac = maxFrac;
    }

    public override string ToString()
    {
      return pattern + " group=" + group + " minInt=" + minInt +
        " maxFrac=" + maxFrac + " minFrac=" + minFrac + " optInt=" + optInt;
    }

    internal string pattern;  // pattern parsed
    internal int group;       // grouping size (typically 3 for 1000)
    internal bool optInt;  // if we have "#." then the int part if optional (no leading zero)
    internal int minInt;      // min digits in integer part (leading zeros)
    internal int minFrac;     // min digits in fractional part (trailing zeros)
    internal int maxFrac;     // max digits in fractional part (clipping)
  }
}
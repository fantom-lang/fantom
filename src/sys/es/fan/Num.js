//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 2008  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   04 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Num
 */
class Num extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor() { super(); }

  

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  static toDecimal(val) { return Decimal.make(val.valueOf()); }
  static toFloat(val) { return Float.make(val.valueOf()); }
  static toInt(val) {
    if (isNaN(val)) return 0;
    if (val == Number.POSITIVE_INFINITY) return Int.maxVal();
    if (val == Number.NEGATIVE_INFINITY) return Int.minVal();
    if (val < 0) return Math.ceil(val);
    return Math.floor(val);
  }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  static localeDecimal() { return Locale.cur().__numSymbols().decimal; }

  static localeGrouping() { return Locale.cur().__numSymbols().grouping; }

  static localeMinus() { return Locale.cur().__numSymbols().minus; }

  static localePercent() { return Locale.cur().__numSymbols().percent; }

  static localePosInf() { return Locale.cur().__numSymbols().posInf; }

  static localeNegInf() { return Locale.cur().__numSymbols().negInf; }

  static localeNaN() { return Locale.cur().__numSymbols().nan; }

  static toLocale(p, d, locale) {
    var symbols = locale.__numSymbols();

    // string buffer
    let s = "";
    if (d.negative) s += symbols.minus;

    // if we have more frac digits then maxFrac, then round off
    d.round(p.maxFrac);

    // if we have an optional integer part, and only
    // fractional digits, then don't include leading zero
    let start = 0;
    if (p.optInt && d.zeroInt()) start = d.decimal;

    // if min required fraction digits are zero and we
    // have nothing but zeros, then truncate to a whole number
    if (p.minFrac == 0 && d.zeroFrac(p.maxFrac)) d.truncateToWhole(); //d.size = d.decimal;

    // leading zeros
    for (let i=0; i<p.minInt-d.decimal; ++i) s += '0';

    // walk thru the digits and apply locale symbols
    let decimal = false;
    for (let i=start; i<d.size; ++i) {
      if (i < d.decimal) {
        if ((d.decimal - i) % p.group == 0 && i > 0)
          s += symbols.grouping;
      }
      else {
        if (i == d.decimal && p.maxFrac > 0) {
          s += symbols.decimal;
          decimal = true;
        }
        if (i-d.decimal >= p.maxFrac) break;
      }
      s += String.fromCharCode(d.digits[i]);
    }

    // trailing zeros
    for (let i=0; i<p.minFrac-d.fracSize(); ++i) {
      if (!decimal) { s += symbols.decimal; decimal = true; }
      s += '0';
    }

    // handle #.# case
    if (s.length == 0) return "0";

    return s;
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
class NumDigits extends Obj {
  constructor(digits, decimal, size, negative) {
    super();
    this.#digits = digits;
    this.#decimal = decimal;
    this.#size = size;
    this.#negative = negative;
  }

  #digits;   // char digits
  #decimal;  // index where decimal fits into digit
  #size;     // size of digits used
  #negative; // is this a negative number

  get digits() { return this.#digits; }
  get decimal() { return this.#decimal; }
  get size() { return this.#size}
  get negative() { return this.#negative; }

//fan.sys.NumDigits.makeDecimal = function(d)
//{
//  return fan.sys.NumDigits.makeStr(d.toString());
//}

  static makeStr(s) {
    const digits = [];
    let decimal = -99;
    let size = 0;
    let negative = false;
    let expPos = -1;
    for (let i=0; i<s.length; ++i) {
      const c = s.charCodeAt(i);
      if (c == 45) { negative = true; continue; }
      if (c == 46) { decimal = negative ? i-1 : i; continue; }
      if (c == 101 || c == 69) { expPos = i; break; }
      digits.push(c); size++;
    }
    if (decimal < 0) decimal = size;

    // if we had an exponent, then we need to normalize it
    if (expPos >= 0) {
      // move the decimal by the exponent
      const exp = parseInt(s.substring(expPos+1), 10);
      decimal += exp;

      // add leading/trailing zeros as necessary
      if (decimal >= size) {
        while(size <= decimal) digits[size++] = 48;
      }
      else if (decimal < 0) {
        for (let i=0; i<-decimal; ++i) digits.unshift(48);
        size += -decimal;
        decimal = 0;
      }
    }
    return new NumDigits(digits, decimal, size, negative);
  }

  static makeLong(l) {
    const digits = [];
    let negative = false;
    if (l < 0) { negative = true; l = -l; }
    let s = l.toString();
    // TODO FIXIT: js prec issues
    if (s.charAt(0) === '-') s = "9223372036854775808"; // handle overflow case
    for (let i=0; i<s.length; i++) digits.push(s.charCodeAt(i));
    return new NumDigits(digits, digits.length, digits.length, negative);
  }

  truncateToWhole() { this.#size = this.#decimal; }

  intSize() { return this.#decimal; }

  fracSize() { return this.#size - this.#decimal; }

  zeroInt() {
    for (let i=0; i<this.#decimal; ++i) if (this.#digits[i] != 48) return false;
    return true;
  }

  zeroFrac(maxFrac) {
    let until = this.#decimal + maxFrac;
    for (var i=this.#decimal; i<until; ++i) if (this.#digits[i] != 48) return false;
    return true;
  }

  round(maxFrac) {
    // if frac size already eq or less than maxFrac no rounding needed
    if (this.fracSize() <= maxFrac) return;

    // if we need to round, then round the prev digit
    if (this.#digits[this.#decimal+maxFrac] >= 53)
    {
      let i = this.#decimal + maxFrac - 1;
      while (true) {
        if (this.#digits[i] < 57) { this.#digits[i]++; break; }
        this.#digits[i--] = 48;
        if (i < 0) {
          this.#digits.unshift(49);
          this.#size++; this.#decimal++;
          break;
        }
      }
    }

    // update size and clip any trailing zeros
    this.#size = this.#decimal + maxFrac;
    while (this.#digits[this.#size-1] == 48 && this.#size > this.#decimal) this.#size--;
  }

  toString() {
    let s = "";
    for (let i=0; i<this.#digits.length; i++) s += String.fromCharCode(this.#digits[i]);
    return s + " neg=" + this.#negative + " decimal=" + this.#decimal;
  }

}

//////////////////////////////////////////////////////////////////////////
// NumPattern
//////////////////////////////////////////////////////////////////////////

/**
 * NumPattern parses and models a numeric locale pattern.
 */
class NumPattern extends Obj {
  constructor(pattern, group, optInt, minInt, minFrac, maxFrac) {
    super();
    this.#pattern = pattern;
    this.#group = group;
    this.#optInt = optInt;
    this.#minInt = minInt;
    this.#minFrac = minFrac;
    this.#maxFrac = maxFrac;
  }

  // pre-compute common patterns to avoid parsing
  static #cache = {};

  #pattern;   // pattern parsed
  #group;     // grouping size (typically 3 for 1000)
  #optInt;    // if we have "#." then the int part if optional (no leading zero)
  #minInt;    // min digits in integer part (leading zeros)
  #minFrac;   // min digits in fractional part (trailing zeros)
  #maxFrac;   // max digits in fractional part (clipping)

  get pattern() { return this.#pattern; }
  get group() { return this.#group; }
  get optInt() { return this.#optInt; }
  get minInt() { return this.#minInt; }
  get minFrac() { return this.#minFrac; }
  get maxFrac() { return this.#maxFrac; }

  static parse(s) {
    const x = NumPattern.cache$[s];
    if (x != null) return x;
    return NumPattern.make(s);
  }

  static make(s) {
    let group = Int.maxVal;
    let optInt = true;
    let comma = false;
    let decimal = false;
    let minInt = 0, minFrac = 0, maxFrac = 0;
    let last = 0;
    for (let i=0; i<s.length; ++i)
    {
      const c = s.charAt(i);
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
            { minInt++; if (comma) group++; }
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

    return new NumPattern(s, group, optInt, minInt, minFrac, maxFrac);
  }

  toString() {
    return this.#pattern + " group=" + this.#group + " minInt=" + this.#minInt +
      " maxFrac=" + this.#maxFrac + " minFrac=" + this.#minFrac + " optInt=" + this.#optInt;
  }

  static cache$(p) { NumPattern.#cache[p] = NumPattern.make(p); }

}
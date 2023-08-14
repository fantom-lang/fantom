//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Dec 2008  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   04 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Int
 */
class Int extends Num {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor() { super(); }

  make(val) { return val; }

  static #MAX_SAFE = 9007199254740991;
  static #MIN_SAFE = -9007199254740991;

  static maxVal() { return Math.pow(2, 53); }
  static minVal() { return -Math.pow(2, 53); }
  static defVal() { return 0; }
  static __chunk  = 4096;

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  static fromStr(s, radix=10, checked=true) {
    try {
      if (radix === 10) { const n = Int.#parseDecimal(s); return n; }
      if (radix === 16) { const n = Int.#parseHex(s); return n; }
      throw new Error("Unsupported radix " + radix);
    }
    catch (err) {
      if (checked) throw ParseErr.make(`Invalid Int: '${s}'`, s, null, err);
      return null;
    }
  }

  static #parseDecimal(s) {
    let n = 0;
    if (s.charCodeAt(0) === 45) n++;
    for (let i=n; i<s.length; i++) {
      const ch = s.charCodeAt(i);
      if (ch >= 48 && ch <= 57) continue;
      throw new Error("Illegal decimal char " + s.charAt(i));
    }
    const x = parseInt(s, 10);
    if (isNaN(x)) throw new Error("Invalid number");
    return x;
  }

  static #parseHex(s) {
    for (let i=0; i<s.length; i++)
    {
      const ch = s.charCodeAt(i);
      if (ch >= 48 && ch <= 57) continue;
      if (ch >= 65 && ch <= 70) continue;
      if (ch >= 97 && ch <= 102) continue;
      throw new Error("Illegal hex char " + s.charAt(i));
    }
    const x = parseInt(s, 16);
    if (isNaN(x)) throw new Error("Invalid number");
    return x;
  }

  static random(r) {
    if (r === undefined) return Math.floor(Math.random() * Math.pow(2, 64));
    else {
      const start = r.start();
      let end     = r.end();
      if (r.inclusive()) ++end;
      if (end <= start) throw ArgErr.make("Range end < start: " + r);
      r = end-start;
      if (r < 0) r = -r;
      return Math.floor(Math.random()*r) + start;
    }
  }

/////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  static toStr(self) { return self.toString(); }

  static equals(self, obj) { return self === obj; }

  static hash(self) { return self; }

/////////////////////////////////////////////////////////////////////////
// Operations
//////////////////////////////////////////////////////////////////////////

  static negate(self) { return -self; }
  static increment(self) { return self+1; }
  static decrement(self) { return self-1; }

  static mult(a, b) { return a * b; }
  static multFloat(a, b) { return Float.make(a * b); }
  static multDecimal(a, b) { return Decimal.make(a * b); }

  static div(a, b) {
    const r = a / b;
    if (r < 0) return Math.ceil(r);
    return Math.floor(r);
  }
  static divFloat(a, b) { return Float.make(a / b); }
  static divDecimal(a, b) { return Decimal.make(Int.div(a, b)); }

  static mod(a, b) { return a % b; }
  static modFloat(a, b) { return Float.make(a % b); }
  static modDecimal(a, b) { return Decimal.make(a % b); }

  static plus(a, b) { return a + b; }
  static plusFloat(a, b) { return Float.make(a + b); }
  static plusDecimal(a, b) { return Decimal.make(a + b); }

  static minus(a, b) { return a - b; }
  static minusFloat(a, b) { return Float.make(a - b); }
  static minusDecimal(a, b) { return Decimal.make(a - b); }

/////////////////////////////////////////////////////////////////////////
// Bitwise
//////////////////////////////////////////////////////////////////////////

// NOTE: these methods only operate on the lowest 32 bits of the integer

static not(a) { return ~a; }
static and(a, b) { let x = a & b;  if (x<0) x += 0xffffffff+1; return x; }
static or(a, b) { let x = a | b;  if (x<0) x += 0xffffffff+1; return x; }
static xor(a, b) { let x = a ^ b;  if (x<0) x += 0xffffffff+1; return x; }
static shiftl(a, b) { let x = a << b; if (x<0) x += 0xffffffff+1; return x; }
static shiftr(a, b) { let x = a >>> b; if (x<0) x += 0xffffffff+1; return x; }
static shifta(a, b) { let x = a >> b; return x; }

/////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  static abs(self)      { return self < 0 ? -self : self; }
  static min(self, val) { return self < val ? self : val; }
  static max(self, val) { return self > val ? self : val; }

  static clamp(self, min, max) {
    if (self < min) return min;
    if (self > max) return max;
    return self;
  }

  static clip(self, min, max) { return clamp(self, min, max); }
 
  static pow(self, pow) {
    if (pow < 0) throw ArgErr.make("pow < 0");
    return Math.pow(self, pow);
  }

  static isEven(self) { return self % 2 == 0; }
  static isOdd(self) { return self % 2 != 0; }

/////////////////////////////////////////////////////////////////////////
// Char
//////////////////////////////////////////////////////////////////////////

  static isSpace(self) { return self == 32 || self == 9 || self == 10 || self == 13; }
  static isAlpha(self) { return Int.isUpper(self) || Int.isLower(self); }
  static isAlphaNum(self) { return Int.isAlpha(self) || Int.isDigit(self); }
  static isUpper(self) { return self >= 65 && self <= 90; }
  static isLower(self) { return self >= 97 && self <= 122; }
  static upper(self) { return Int.isLower(self) ? self-32 : self; }
  static lower(self) { return Int.isUpper(self) ? self+32 : self; }

  static isDigit(self, radix=10) {
    if (radix == 10) return self >= 48 && self <= 57;
    if (radix == 16)
    {
      if (self >= 48 && self <= 57) return true;
      if (self >= 65 && self <= 70) return true;
      if (self >= 97 && self <= 102) return true;
      return false;
    }
    if (radix <= 10) return 48 <= self && self <= (48+radix);
    if ((Int.charMap[self] & Int.DIGIT) != 0) return true;
    const x = radix-10;
    if (97 <= self && self < 97+x) return true;
    if (65 <= self && self < 65+x) return true;
    return false;
  }

  static toDigit(self, radix=10) {
    if (radix == 10) return 0 <= self && self <= 9 ? 48+self : null;
    if (self < 0 || self >= radix) return null;
    if (self < 10) return 48+self;
    return self-10+97;
  }

  static fromDigit(self, radix=10) {
    if (self < 0 || self >= 128) return null;
    var ten = radix < 10 ? radix : 10;
    if (48 <= self && self < 48+ten) return self-48;
    if (radix > 10)
    {
      var alpha = radix-10;
      if (97 <= self && self < 97+alpha) return self+10-97;
      if (65 <= self && self < 65+alpha) return self+10-65;
    }
    return null;
  }

  static equalsIgnoreCase(self, ch) { 
    if (65 <= self && self <= 90) self |= 0x20;
    if (65 <= ch   && ch   <= 90) ch   |= 0x20;
    return self == ch;
  }

/////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  static toLocale(self, pattern=null, locale=Locale.cur()) {
    // if pattern is "B" format as bytes
    if (pattern != null && pattern.length == 1 && pattern.charAt(0) == 'B')
      return Int.#toLocaleBytes(self);

    // get default pattern if necessary
    if (pattern == null)
  // TODO FIXIT
  //    pattern = Env.cur().locale(Sys.sysPod, "int", "#,###");
      pattern = "#,###";

    // parse pattern and get digits
    const p = NumPattern.parse(pattern);
    const d = NumDigits.makeLong(self);

    // route to common FanNum method
    return Num.toLocale(p, d, locale);
  }

  static #KB = 1024;
  static #MB = 1024*1024;
  static #GB = 1024*1024*1024;

  static #toLocaleBytes(b) {
    let KB = Int.#KB;
    let MB = Int.#MB;
    let GB = Int.#GB;
    if (b < KB)    return b + "B";
    if (b < 10*KB) return Float.toLocale(b/KB, "#.#") + "KB";
    if (b < MB)    return Math.round(b/KB) + "KB";
    if (b < 10*MB) return Float.toLocale(b/MB, "#.#") + "MB";
    if (b < GB)    return Math.round(b/MB) + "MB";
    if (b < 10*GB) return Float.toLocale(b/GB, "#.#") + "GB";
    return Math.round(b/Int.#GB) + "GB";
  }

  // TODO FIXIT
  static localeIsUpper(self) { return Int.isUpper(self); }
  static localeIsLower(self) { return Int.isLower(self); }
  static localeUpper(self) { return Int.upper(self); }
  static localeLower(self) { return Int.lower(self); }

/////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  static toInt(val) { return val; }
  static toFloat(val) { return Float.make(val); }
  static toDecimal(val) { return Decimal.make(val); }

  static toChar(self) {
    if (self < 0 || self > 0xFFFF) throw Err.make("Invalid unicode char: " + self);
    return String.fromCharCode(self);
  }

  static toHex(self, width=null) {
    // make sure non-null to prevent infinite loop
    if (self == null) self = 0;

    // TODO FIXIT: how do we handle negative numbers?
    let val = self;
    if (val < 0) val += Int.#MAX_SAFE;

    // convert to hex string
    let s = "";
    while (true) {
      // write chars backwards
      s = "0123456789abcdef".charAt(val % 16) + s;
      val = Math.floor(val / 16);
      if (val === 0) break
    }

    // pad width
    if (width != null && s.length < width) {
      const zeros = width - s.length;
      for (var i=0; i<zeros; ++i) s = '0' + s;
    }

    return s;
  }

  static toRadix(self, radix=10, width=null) {
    // convert to hex string
    let s = self.toString(radix);

    // pad width
    if (width != null && s.length < width) {
      const zeros = width - s.length;
      for (var i=0; i<zeros; ++i) s = '0' + s;
    }

    return s;
  }

  static toCode(self, base=10) {
    if (base == 10) return self.toString();
    if (base == 16) return "0x" + Int.toHex(self);
    throw ArgErr.make("Invalid base " + base);
  }

  static toDuration(self) { return Duration.make(self); }

  static toDateTime(self, tz=TimeZone.cur()) {
    return (tz === undefined)
      ? DateTime.makeTicks(self)
      : DateTime.makeTicks(self, tz);
  }

/////////////////////////////////////////////////////////////////////////
// Closures
//////////////////////////////////////////////////////////////////////////

  static times(self, f) {
    for (let i=0; i<self; ++i) 
      f(i);
  }

/////////////////////////////////////////////////////////////////////////
// CharMap
//////////////////////////////////////////////////////////////////////////

  static charMap = [];
  static SPACE    = 0x01;
  static UPPER    = 0x02;
  static LOWER    = 0x04;
  static DIGIT    = 0x08;
  static HEX      = 0x10;
  static ALPHA    = Int.UPPER | Int.LOWER;
  static ALPHANUM = Int.UPPER | Int.LOWER | Int.DIGIT;

  static
  {
    Int.charMap[32] |= Int.SPACE;
    Int.charMap[10] |= Int.SPACE;
    Int.charMap[13] |= Int.SPACE;
    Int.charMap[9]  |= Int.SPACE;
    Int.charMap[12] |= Int.SPACE;

    // alpha characters
    for (let i=97; i<=122; ++i) Int.charMap[i] |= Int.LOWER;
    for (let i=65; i<=90;  ++i) Int.charMap[i] |= Int.UPPER;

    // digit characters
    for (let i=48; i<=57; ++i) Int.charMap[i] |= Int.DIGIT;

    // hex characters
    for (let i=48; i<=57;  ++i) Int.charMap[i] |= Int.HEX;
    for (let i=97; i<=102; ++i) Int.charMap[i] |= Int.HEX;
    for (let i=65; i<=70;  ++i) Int.charMap[i] |= Int.HEX;
  }

}

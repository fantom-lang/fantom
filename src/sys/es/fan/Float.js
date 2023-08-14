//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 2008  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   14 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Float
 */
class Float extends Num {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor() { super(); }

  static posInf() { return Float.make(Number.POSITIVE_INFINITY); }
  static negInf() { return Float.make(Number.NEGATIVE_INFINITY); }
  static nan() { return Float.make(Number.NaN); }
  static e() { return Math.E; }
  static pi() { return Math.PI; }

  static #defVal = undefined
  static defVal() {
    if (Float.#defVal === undefined) Float.#defVal = Float.make(0);
    return Float.#defVal;
  }

  static make(val) {
    const x = new Number(val);
    x.fanType$ = Float.type$;
    return x;
  }

  static makeBits(bits) {
    throw UnsupportedErr.make("Float.makeBits not available in JavaScript");
  }

  static makeBits32(bits) {
    const buffer = new ArrayBuffer(4);
    (new Uint32Array(buffer))[0] = bits;
    return Float.make(new Float32Array(buffer)[0]);
  }

  

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  static equals(self, that) {
    if (that != null && self.fanType$ === that.fanType$) {
      return self.valueOf() == that.valueOf();
    }
    return false;
  }

  static compare(self, that) {
    if (self == null) return that == null ? 0 : -1;
    if (that == null) return 1;
    if (isNaN(self)) return isNaN(that) ? 0 : -1;
    if (isNaN(that)) return 1;
    if (self < that) return -1;
    return self.valueOf() == that.valueOf() ? 0 : 1;
  }

  static isNaN(self) { return isNaN(self); }

  static isNegZero(self) { return 1/self === -Infinity; }

  static normNegZero(self) { return Float.isNegZero(self) ? 0.0 : self; }

  // TODO FIXIT: hash
  static hash(self) { return Str.hash(self.toString()); }

  static bits(self) { throw UnsupportedErr.make("Float.bits not available in JavaScript"); }

  static bitsArray(self) {
    const buf = new ArrayBuffer(8);
    (new Float64Array(buf))[0] = self;
    return [(new Uint32Array(buf))[0], (new Uint32Array(buf))[1]];
  }

  static bits32(self) {
    const buf = new ArrayBuffer(4);
    (new Float32Array(buf))[0] = self;
    return (new Uint32Array(buf))[0];
  }

/////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  static toInt(val) { return (val<0) ? Math.ceil(val) : Math.floor(val); }
  static toFloat(val) { return val; }
  static toDecimal(val) { return Decimal.make(val); }

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

  static abs(self) { return Float.make(Math.abs(self)); }
  static approx(self, that, tolerance=null) {
    // need this to check +inf, -inf, and nan
    if (Float.compare(self, that) == 0) return true;
    const t = tolerance == null
      ? Math.min(Math.abs(self/1e6), Math.abs(that/1e6))
      : tolerance;
    return Math.abs(self - that) <= t;
  }
  static ceil(self) { return Float.make(Math.ceil(self)); }
  static exp(self) { return Float.make(Math.exp(self)); }
  static floor(self) { return Float.make(Math.floor(self)); }
  static log(self) { return Float.make(Math.log(self)); }
  static log10(self) { return Float.make(Math.log(self) / Math.LN10); }
  static min(self, that) { return Float.make(Math.min(self, that)); }
  static max(self, that) { return Float.make(Math.max(self, that)); }
  static negate(self) { return Float.make(-self); }
  static pow(self, exp) { return Float.make(Math.pow(self, exp)); }
  static round(self) { return Float.make(Math.round(self)); }
  static sqrt(self) { return Float.make(Math.sqrt(self)); }
  static random() { return Float.make(Math.random()); }

  static clamp(self, min, max) {
    if (self < min) return min;
    if (self > max) return max;
    return self;
  }

  static clip(self, min, max) { return Float.clamp(self, min, max); }

  // arithmetic
  static plus(a,b) { return Float.make(a+b); }
  static plusInt(a,b) { return Float.make(a+b); }
  static plusDecimal(a,b) { return Decimal.make(a+b); }

  static minus(a,b) { return Float.make(a-b); }
  static minusInt(a,b) { return Float.make(a-b); }
  static minusDecimal(a,b) { return Decimal.make(a-b); }

  static mult(a,b) { return Float.make(a*b); }
  static multInt(a,b) { return Float.make(a*b); }
  static multDecimal(a,b) { return Decimal.make(a*b); }

  static div(a,b) { return Float.make(a/b); }
  static divInt(a,b) { return Float.make(a/b); }
  static divDecimal(a,b) { return Decimal.make(a/b); }

  static mod(a,b) { return Float.make(a%b); }
  static modInt(a,b) { return Float.make(a%b); }
  static modDecimal(a,b) { return Decimal.make(a%b); }

  static increment(self) { return Float.make(self+1); }

  static decrement(self) { return Float.make(self-1); }

  // Trig
  static acos(self) { return Float.make(Math.acos(self)); }
  static asin(self) { return Float.make(Math.asin(self)); }
  static atan(self) { return Float.make(Math.atan(self)); }
  static atan2(y, x) { return Float.make(Math.atan2(y, x)); }
  static cos(self) { return Float.make(Math.cos(self)); }
  static sin(self) { return Float.make(Math.sin(self)); }
  static tan(self) { return Float.make(Math.tan(self)); }
  static toDegrees(self) { return Float.make(self * 180 / Math.PI); }
  static toRadians(self) { return Float.make(self * Math.PI / 180); }
  static cosh(self) { return Float.make(0.5 * (Math.exp(self) + Math.exp(-self))); }
  static sinh(self) { return Float.make(0.5 * (Math.exp(self) - Math.exp(-self))); }
  static tanh(self) { return Float.make((Math.exp(2*self)-1) / (Math.exp(2*self)+1)); }

//////////////////////////////////////////////////////////////////////////
// Str
//////////////////////////////////////////////////////////////////////////

  static fromStr(s, checked=true) {
    if (s == "NaN") return Float.nan();
    if (s == "INF") return Float.posInf();
    if (s == "-INF") return Float.negInf();
    if (isNaN(s))
    {
      if (!checked) return null;
      throw ParseErr.makeStr("Float", s);
    }
    return Float.make(parseFloat(s));
  }

  static toStr(self) {
    if (isNaN(self)) return "NaN";
    if (Float.isNegZero(self)) return "-0.0";
    if (self == Number.POSITIVE_INFINITY) return "INF";
    if (self == Number.NEGATIVE_INFINITY) return "-INF";
    return (Float.toInt(self) == self) ? self.toFixed(1) : ""+self;
  }

  static encode(self, out) {
    if (isNaN(self)) out.w("sys::Float(\"NaN\")");
    else if (self == Number.POSITIVE_INFINITY) out.w("sys::Float(\"INF\")");
    else if (self == Number.NEGATIVE_INFINITY) out.w("sys::Float(\"-INF\")");
    else out.w(""+self).w("f");
  }

  static toCode(self) {
    if (isNaN(self)) return "Float.nan";
    if (self == Number.POSITIVE_INFINITY) return "Float.posInf";
    if (self == Number.NEGATIVE_INFINITY) return "Float.negInf";
    var s = ""+self
    if (s.indexOf(".") == -1) s += ".0";
    return s + "f";
  }

/////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  static toLocale(self, pattern=null, locale=Locale.cur()) {
    try
    {
      // handle special values
      if (isNaN(self)) return locale.__numSymbols().nan;
      if (self == Float.posInf) return locale.__numSymbols().posInf;
      if (self == Float.negInf) return locale.__numSymbols().negInf;

      // get default pattern if necessary
      if (pattern == null) {
        if (Math.abs(self) >= 100.0)
          return Int.toLocale(Math.round(self), null, locale);

        pattern = Float.toDefaultLocalePattern$(self);
      }

      // TODO: if value is < 10^-3 or > 10^7 it will be
      // converted to exponent string, so just bail on that
  // TODO FIXIT
      var string = ''+self;
  //    if (string.indexOf('E') > 0)
  //      string = new java.text.DecimalFormat("0.#########").format(self);

      // parse pattern and get digits
      var p = NumPattern.parse(pattern);
      var d = NumDigits.makeStr(string);

      // route to common FanNum method
      return Num.toLocale(p, d, locale);
    }
    catch (err)
    {
      ObjUtil.echo(err);
      return ''+self;
    }
  }

  static toDefaultLocalePattern$(self) {
    const abs  = Math.abs(self);
    const fabs = Math.floor(abs);

    if (fabs >= 10.0) return "#0.0#";
    if (fabs >= 1.0)  return "#0.0##";

    // format a fractional number (no decimal part)
    const frac = abs - fabs;
    if (frac < 0.00000001) return "0.0";
    if (frac < 0.0000001)  return "0.0000000##";
    if (frac < 0.000001)   return "0.000000##";
    if (frac < 0.00001)    return "0.00000##";
    if (frac < 0.0001)     return "0.0000##";
    if (frac < 0.001)      return "0.000##";
    return "0.0##";
  }

}
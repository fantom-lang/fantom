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
 * Decimal
 */
class Decimal extends Num {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor() { super(); }

  static #defVal;
  static defVal() {
    if (!Decimal.#defVal) Decimal.#defVal = Decimal.make(0);
    return Decimal.#defVal;
  }

  static make(val) {
    const x = new Number(val);
    x.fanType$ = Decimal.type$;
    return x;
  }

  static fromStr(s, checked=true) {
    try
    {
      // TODO FIXIT
      for (let i=0; i<s.length; i++)
        if (!Int.isDigit(s.charCodeAt(i)) && s[i] !== '.')
          throw new Error();
      return Decimal.make(parseFloat(s));
    }
    catch (e)
    {
      if (!checked) return null;
      throw ParseErr.make("Decimal",  s);
    }
  }

  static toFloat(self) { return Float.make(self.valueOf()); }

  static negate(self) { return Decimal.make(-self.valueOf()); }

  static equals(self, that) {
    if (that != null && self.fanType$ === that.fanType$)
    {
      if (isNaN(self) || isNaN(that)) return false;
      return self.valueOf() == that.valueOf();
    }
    return false;
  }

  // TODO FIXIT: hash
  static hash(self) { Str.hash(self.toString()); }

  static encode(self, out) { out.w(""+self).w("d"); }

  static toCode(self) { return "" + self + "d"; }

  static toLocale(self, pattern=null, locale=Locale.cur()) {

    // TODO: for now we just route to Float.toLocale
    return Float.toLocale(self, pattern, locale);

    // get current locale
    // var locale = fan.sys.Locale.cur();
    // java.text.DecimalFormatSymbols df = locale.decimal();
    //
    // // get default pattern if necessary
    // if (pattern == null)
    //   pattern = Env.cur().locale(Sys.sysPod, "decimal", "#,###.0##");
    //
    // // parse pattern and get digits
    // NumPattern p = NumPattern.parse(pattern);
    // NumDigits d = new NumDigits(self);
    //
    // // route to common FanNum method
    // return FanNum.toLocale(p, d, df);
  }

  static toStr(self) { return Float.toStr(self); }
}
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Decimal
 */
fan.sys.Decimal = fan.sys.Obj.$extend(fan.sys.Num);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Decimal.prototype.$ctor = function() {}

fan.sys.Decimal.make = function(val)
{
  var x = new Number(val);
  x.$fanType = fan.sys.Decimal.$type;
  return x;
}

fan.sys.Decimal.fromStr = function(s, checked)
{
  if (checked === undefined) checked = true;
  try
  {
    // TODO FIXIT
    for (var i=0; i<s.length; i++)
      if (!fan.sys.Int.isDigit(s.charCodeAt(i)) && s[i] !== '.')
        throw new Error();
    return fan.sys.Decimal.make(parseFloat(s));
  }
  catch (e)
  {
    if (!checked) return null;
    throw fan.sys.ParseErr.make("Decimal",  s);
  }
}

fan.sys.Decimal.toFloat = function(self)
{
  return fan.sys.Float.make(self.valueOf());
}

fan.sys.Decimal.negate = function(self)
{
  return fan.sys.Decimal.make(-self.valueOf());
}

fan.sys.Decimal.equals = function(self, that)
{
  if (that != null && self.$fanType === that.$fanType)
  {
    if (isNaN(self) || isNaN(that)) return false;
    return self.valueOf() == that.valueOf();
  }
  return false;
}

// TODO FIXIT: hash
fan.sys.Decimal.hash = function(self)
{
  fan.sys.Str.hash(self.toString());
}

fan.sys.Decimal.encode = function(self, out)
{
  out.w(""+self).w("d");
}

fan.sys.Decimal.toCode = function(self)
{
  return "" + self + "d";
}

fan.sys.Decimal.toLocale = function(self, pattern, locale)
{
  if (locale === undefined || locale == null) locale = fan.sys.Locale.cur();
  if (pattern === undefined) pattern = null;

  // TODO: for now we just route to Float.toLocale
  return fan.sys.Float.toLocale(self, pattern, locale);

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
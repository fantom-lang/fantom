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


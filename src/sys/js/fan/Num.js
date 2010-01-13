//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Num
 */
fan.sys.Num = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Num.prototype.$ctor = function() {}
fan.sys.Num.prototype.type = function() { return fan.sys.Num.$type; }

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Num.toDecimal = function(val) { return fan.sys.Decimal.make(val.valueOf()); }
fan.sys.Num.toFloat = function(val) { return fan.sys.Float.make(val.valueOf()); }
fan.sys.Num.toInt = function(val)
{
  if (isNaN(val)) return 0;
  if (val == Number.POSITIVE_INFINITY) return fan.sys.Int.m_maxVal;
  if (val == Number.NEGATIVE_INFINITY) return fan.sys.Int.m_minVal;
  return Math.floor(val);
}
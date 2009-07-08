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
var sys_Num = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Num.prototype.$ctor = function() {}
sys_Num.prototype.type = function()
{
  return sys_Type.find("sys::Num");
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Num.toDecimal = function(val) { return val; }
sys_Num.toFloat = function(val) { return val; }
sys_Num.toInt = function(val)
{
  if (isNaN(val)) return 0;
  if (val == Number.POSITIVE_INFINITY) return sys_Int.maxVal;
  if (val == Number.NEGATIVE_INFINITY) return sys_Int.minVal;
  return Math.floor(val);
}
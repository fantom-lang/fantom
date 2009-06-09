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
var sys_Decimal = sys_Obj.$extend(sys_Num);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Decimal.prototype.$ctor = function() {}

sys_Decimal.make = function(val)
{
  var x = new Number(val);
  x.$fanType = sys_Type.find("sys::Decimal");
  return x;
}


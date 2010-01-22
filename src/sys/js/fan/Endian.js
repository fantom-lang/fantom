//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Feb 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Endian
 */
fan.sys.Endian = fan.sys.Obj.$extend(fan.sys.Enum);

fan.sys.Endian.prototype.$ctor = function(ordinal, name)
{
  fan.sys.Enum.make$(this, ordinal, name);
}

fan.sys.Endian.fromStr = function(name, checked)
{
  if (checked === undefined) checked = true;
  return fan.sys.Enum.doFromStr(fan.sys.Endian.$type, name, checked);
}

fan.sys.Endian.prototype.$typeof = function()
{
  return fan.sys.Endian.$type;
}



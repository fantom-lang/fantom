//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Mar 09  Andy Frank  Creation
//

/**
 * File.
 */
fan.sys.File = fan.sys.Obj.$extend(fan.sys.Obj);

fan.sys.File.prototype.$ctor = function() {}
fan.sys.File.prototype.type = function() { return fan.sys.Type.find("sys::File"); }

fan.sys.File.prototype.exists = function() { return true; }

fan.sys.File.make = function()
{
  return new fan.sys.File();
}
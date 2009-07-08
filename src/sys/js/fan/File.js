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
var sys_File = sys_Obj.$extend(sys_Obj);

sys_File.prototype.$ctor = function() {}
sys_File.prototype.type = function() { return sys_Type.find("sys::File"); }

sys_File.prototype.exists = function() { return true; }

sys_File.make = function()
{
  return new sys_File();
}
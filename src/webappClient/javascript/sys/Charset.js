//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//

/**
 * Charset.
 */
var sys_Charset = sys_Obj.extend(
{
  $ctor: function() {},
  type: function() { return sys_Type.find("sys::Charset"); }
});
sys_Charset.utf16BE = function() { return null; }
sys_Charset.utf16LE = function() { return null; }
sys_Charset.utf8 = function() { return null; }
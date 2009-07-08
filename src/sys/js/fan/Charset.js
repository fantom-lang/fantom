//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Charset.
 */
var sys_Charset = sys_Obj.$extend(sys_Obj);

sys_Charset.prototype.$ctor = function() {}
sys_Charset.prototype.type = function() { return sys_Type.find("sys::Charset"); }

// TODO
sys_Charset.utf16BE = function() { return null; }
sys_Charset.utf16LE = function() { return null; }
sys_Charset.utf8    = function() { return null; }
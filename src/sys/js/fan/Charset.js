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
fan.sys.Charset = fan.sys.Obj.$extend(fan.sys.Obj);

fan.sys.Charset.prototype.$ctor = function() {}
fan.sys.Charset.prototype.type = function() { return fan.sys.Type.find("sys::Charset"); }

// TODO
fan.sys.Charset.utf16BE = function() { return null; }
fan.sys.Charset.utf16LE = function() { return null; }
fan.sys.Charset.utf8    = function() { return null; }
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   7 Jul 09  Andy Frank  Creation
//

/**
 * Locale.
 */
fan.sys.Locale = fan.sys.Obj.$extend(fan.sys.Obj);

fan.sys.Locale.prototype.$ctor = function() {}
fan.sys.Locale.prototype.$typeof = function() { return fan.sys.Locale.$type; }

fan.sys.Locale.cur = function() { return null; }
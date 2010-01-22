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

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

fan.sys.Locale.make = function()
{
  var self = new fan.sys.Locale();
  return self;
}

fan.sys.Locale.prototype.$ctor = function() {}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Locale.prototype.$typeof = function() { return fan.sys.Locale.$type; }
fan.sys.Locale.cur = function()
{
  if (fan.sys.Locale.$cur == null) fan.sys.Locale.$cur = fan.sys.Locale.make();
  return fan.sys.Locale.$cur;
}
fan.sys.Locale.fromStr = function(str) { return fan.sys.Locale.make(); }
fan.sys.Locale.prototype.use = function(f) { f.call(this); }
fan.sys.Locale.prototype.get = function(pod, key, def) { return def; }
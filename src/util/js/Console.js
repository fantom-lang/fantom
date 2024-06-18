//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Jun 24  Brian Frank  Creation
//

/**
 * Console
 */
fan.util.Console = fan.sys.Obj.$extend(fan.sys.Obj);

fan.util.Console.prototype.$ctor = function() {}
fan.util.Console.prototype.$typeof = function() { return fan.util.Console.$type; }

fan.util.Console.cur = function() { return fan.util.Console.$cur; }

fan.util.Console.$cur = new fan.util.Console();

fan.util.Console.prototype.debug = function(msg) { console.debug(msg); return this; }

fan.util.Console.prototype.info = function(msg) { console.info(msg); return this; }

fan.util.Console.prototype.warn = function(msg) { console.warn(msg); return this; }

fan.util.Console.prototype.err = function(msg) { console.error(msg); return this; }

fan.util.Console.prototype.width = function() { return null; }

fan.util.Console.prototype.height = function() { return null; }

fan.util.Console.prototype.table = function(obj) { console.table(obj); return this; }

fan.util.Console.prototype.group = function(msg, collapsed)
{
  if (!collapsed)
    console.group(msg)
  else
    console.groupCollapsed(msg);
  return this;
}

fan.util.Console.prototype.groupEnd = function()
{
  console.groupEnd();
  return this;
}

fan.util.Console.prototype.prompt = function(msg)
{
  return null; // unsupported
}

fan.util.Console.prototype.promptPassword = function(msg)
{
  return null; // unsupported
}


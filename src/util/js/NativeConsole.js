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
fan.util.NativeConsole = fan.sys.Obj.$extend(fan.util.Console);

fan.util.NativeConsole.prototype.$ctor = function() {}
fan.util.NativeConsole.prototype.$typeof = function() { return fan.util.NativeConsole.$type; }

fan.util.NativeConsole.curNative = function() { return fan.util.NativeConsole.$curNative; }

fan.util.NativeConsole.$curNative = new fan.util.NativeConsole();

fan.util.NativeConsole.prototype.debug = function(msg) { console.debug(msg); return this; }

fan.util.NativeConsole.prototype.info = function(msg) { console.info(msg); return this; }

fan.util.NativeConsole.prototype.warn = function(msg) { console.warn(msg); return this; }

fan.util.NativeConsole.prototype.err = function(msg) { console.error(msg); return this; }

fan.util.NativeConsole.prototype.width = function() { return null; }

fan.util.NativeConsole.prototype.height = function() { return null; }

fan.util.NativeConsole.prototype.table = function(obj)
{
  var grid = []
  var t = fan.util.ConsoleTable.make(obj);
  for (var r=0; r<t.rows().size(); ++r)
  {
    var row = t.rows().get(r);
    var obj = {};
    for (var c=0; c<t.headers().size(); ++c)
    {
      var key = t.headers().get(c);
      var val = row.get(c);
      obj[key] = val;
    }
    grid.push(obj);
  }
  console.table(grid)
  return this;
}

fan.util.NativeConsole.prototype.group = function(msg, collapsed)
{
  if (!collapsed)
    console.group(msg)
  else
    console.groupCollapsed(msg);
  return this;
}

fan.util.NativeConsole.prototype.groupEnd = function()
{
  console.groupEnd();
  return this;
}

fan.util.NativeConsole.prototype.prompt = function(msg)
{
  return null; // unsupported
}

fan.util.NativeConsole.prototype.promptPassword = function(msg)
{
  return null; // unsupported
}


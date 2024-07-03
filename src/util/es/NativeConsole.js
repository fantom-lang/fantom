//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Jun 24  Brian Frank  Creation
//

/**
 * NativeConsole
 */
class NativeConsole extends Console {

  static curNative() { return NativeConsole.#curNative; }

  static #curNative = new NativeConsole();

  constructor() { super(); }

  typeof() { return NativeConsole.type$; }

  width() { return null; }

  height() { return null; }

  debug(msg) { console.debug(msg); return this; }

  info(msg) { console.info(msg); return this; }

  warn(msg) { console.warn(msg); return this; }

  err(msg) { console.error(msg); return this; }

  table(obj)
  {
    var grid = []
    var t = ConsoleTable.make(obj);
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

  group(msg, collapsed)
  {
    if (!collapsed)
      console.group(msg)
    else
      console.groupCollapsed(msg);
    return this;
  }

  groupEnd()
  {
    console.groupEnd();
    return this;
  }

  prompt(msg)
  {
    return null; // unsupported
  }

  promptPassword(msg)
  {
    return null; // unsupported
  }
}


//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jun 24  Brian Frank  Creation
//

using concurrent

**
** Console provides utilities to interact with the terminal console.
** For Java this API is designed to use [jline]`docTools::Setup#jline`
** if installed.  In browser JavaScript environments this APIs uses
** the JS debugging window.
**
@Js
abstract const class Console
{
  ** Get the default console for the virtual machine
  static Console cur() { NativeConsole.curNative }

  ** Construct a console that wraps an output stream.
  ** The returned console instance is **not** thread safe.
  static Console wrap(OutStream  out) { OutStreamConsole(out) }

  ** Number of chars that fit horizontally in console or null if unknown
  abstract Int? width()

  ** Number of lines that fit vertically in console or null if unknown
  abstract Int? height()

  ** Print a message to the console at the debug level
  abstract This debug(Obj? msg, Err? err := null)

  ** Print a message to the console at the informational level
  abstract This info(Obj? msg, Err? err := null)

  ** Print a message to the console at the warning level
  abstract This warn(Obj? msg, Err? err := null)

  ** Print a message to the console at the error level
  abstract This err(Obj? msg, Err? err := null)

  ** Print tabular data to the console:
  **  - List of list is two dimensional data where first row is header names
  **  - List of items with an each method will create column per key
  **  - List of items without each will map to a column of "val"
  **  - Anything else will be table of one cell table
  abstract This table(Obj? obj)

  ** Clear the console of all text if supported
  abstract This clear()

  ** Enter an indented group level in the console.  The JS debug
  ** window can specify the group to default in a collapsed state (this
  ** flag is ignored in a standard terminal).
  abstract This group(Obj? msg, Bool collapsed := false)

  ** Exit an indented, collapsable group level
  abstract This groupEnd()

  ** Prompt the user to enter a string from standard input.
  ** Return null if end of stream has been reached.
  abstract Str? prompt(Str msg := "")

  ** Prompt the user to enter a password string from standard input
  ** with echo disabled.  Return null if end of stream has been reached.
  abstract Str? promptPassword(Str msg := "")
}

**************************************************************************
** NativeConsole
**************************************************************************

**
** NativeConsole binds to VM console facilities
**
@NoDoc @Js
native const class NativeConsole : Console
{
  static NativeConsole curNative()
  override Int? width()
  override Int? height()
  override This debug(Obj? msg, Err? err := null)
  override This info(Obj? msg, Err? err := null)
  override This warn(Obj? msg, Err? err := null)
  override This err(Obj? msg, Err? err := null)
  override This table(Obj? obj)
  override This clear()
  override This group(Obj? msg, Bool collapsed := false)
  override This groupEnd()
  override Str? prompt(Str msg := "")
  override Str? promptPassword(Str msg := "")
}

**************************************************************************
** OutStreamConsole
**************************************************************************

**
** OutStreamConsole writes to an output stream (not thread safe)
**
@NoDoc @Js
const class OutStreamConsole : Console
{
  new make(OutStream out) { this.outRef = Unsafe(out) }

  override Int? width() { null }
  override Int? height() { null }
  override This debug(Obj? msg, Err? err := null) { log("DEBUG", msg, err) }
  override This info(Obj? msg, Err? err := null) { log(null, msg, err) }
  override This warn(Obj? msg, Err? err := null) { log("WARN", msg, err) }
  override This err(Obj? msg, Err? err := null) { log("ERR", msg, err) }
  override This table(Obj? obj) { ConsoleTable(obj).dump(this); return this }
  override This clear() { this }
  override This group(Obj? msg, Bool collapsed := false) { info(msg); indent.increment; return this }
  override This groupEnd() { indent.decrement; return this }
  override Str? prompt(Str msg := "") { throw UnsupportedErr() }
  override Str? promptPassword(Str msg := "") { throw UnsupportedErr() }

  virtual This log(Str? level, Str msg, Err? err := null)
  {
    out.print(Str.spaces(indent.val * 2))
    if (level != null) out.print(level).print(": ")
    out.printLine(msg)
    if (err != null) err.traceToStr.splitLines.each |line| { out.print(level).printLine(line) }
    return this
  }

  OutStream out() { outRef.val }
  const Unsafe outRef

  const AtomicInt indent := AtomicInt()
}

**************************************************************************
** ConsoleTable
**************************************************************************

**
** ConsoleTable is helper class to coerce objects to tables
**
@NoDoc @Js
class ConsoleTable
{
  new make(Obj? x)
  {
    list := x as List

    // list of lists
    if (list != null && list.first is List)
    {
      headers = list[0]
      if (list.size > 1) rows = list[1..-1]
      return
    }

    // list of something
    if (list != null)
    {
      // turn each item in list to a Str:Str map
      maps := Str:Str[,]
      list.each |item| { maps.add(map(item)) }

      // create list of columns union
      cols := Str:Str[:] { ordered = true }
      maps.each |map|
      {
        map.each |v, k| { cols[k] = k }
      }
      headers = cols.vals

      // now turn each row Str:Str into a Str[] of cells
      maps.each |map|
      {
        row := Str[,]
        row.capacity = headers.size
        cols.each |k| { row.add(map[k] ?: "") }
        rows.add(row)
      }
      return
    }

    // scalar value
    headers = ["val"]
    rows = [[str(x)]]
  }

  Str[] headers := [,]
  Str[][] rows := [,]

  once Int[] widths()
  {
    widths := Int[,]
    widths.capacity = headers.size
    headers.each |h, c|
    {
      w := h.size
      rows.each |row|
      {
        w = w.max(row[c].size)
      }
      widths.add(w)
    }
    return widths
  }

  Void dump(Console c)
  {
    c.info(row(headers))
    c.info(underlines)
    rows.each |x| { c.info(row(x)) }
  }

  private Str row(Str[] cells)
  {
    s := StrBuf()
    cells.each |cell, i|
    {
      if (i > 0) s.add("  ")
      s.add(cell)
      s.add(Str.spaces(widths[i] - cell.size))
    }
    return s.toStr
  }

  private Str underlines()
  {
    s := StrBuf()
    headers.each |h, i|
    {
      if (i > 0) s.add("  ")
      widths[i].times { s.addChar('-') }
    }
    return s.toStr
  }

  static Str:Str map(Obj? x)
  {
    if (x == null) return ["val":"null"]

    m := x.typeof.method("each", false)
    if (m == null || x is Str) return ["val":str(x)]

    acc := Str:Str[:] { ordered = true }
    f := |v, k| { acc[str(k)] = str(v)}
    m.callOn(x, [f])
    return acc
  }

  private static Str str(Obj? x)
  {
    if (x == null) return "null"
    s := x.toStr
    if (s.contains("\n")) s = s.splitLines.first
    if (s.size > 80) s = s[0..80] + ".."
    return s
  }
}


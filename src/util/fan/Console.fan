//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jun 24  Brian Frank  Creation
//

**
** Console provides utilities to interact with the terminal console.
** For Java this API is designed to use [jline]`docTools::Setup#jline`
** if installed.  In browser JavaScript environments this APIs uses
** the JS debugging window.
**
@Js
native const final class Console
{
  ** Get the default console for the virtual machine
  static Console cur()

  ** Number of chars that fit horizontally in console or null if unknown
  Int? width()

  ** Number of lines that fit vertically in console or null if unknown
  Int? height()

  ** Print a message to the console at the debug level
  This debug(Obj? msg)

  ** Print a message to the console at the informational level
  This info(Obj? msg)

  ** Print a message to the console at the warning level
  This warn(Obj? msg)

  ** Print a message to the console at the error level
  This err(Obj? msg)

  ** Print tabular data to the console:
  **  - List of list is two dimensional data where first row is header names
  **  - List of items with an each method will create column per key
  **  - List of items without each will map to a column of "val"
  **  - Anything else will be table of one cell table
  This table(Obj? obj)

  ** Clear the console of all text if supported
  This clear()

  ** Enter an indented group level in the console.  The JS debug
  ** window can specify the group to default in a collapsed state (this
  ** flag is ignored in a standard terminal).
  This group(Obj? msg, Bool collapsed := false)

  ** Exit an indented, collapsable group level
  This groupEnd()

  ** Prompt the user to enter a string from standard input.
  ** Return null if end of stream has been reached.
  Str? prompt(Str msg := "")

  ** Prompt the user to enter a password string from standard input
  ** with echo disabled.  Return null if end of stream has been reached.
  Str? promptPassword(Str msg := "")
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


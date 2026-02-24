//
// Copyright (c) 2024, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Feb 2026  Mike Jarmy  Creation
//

**
** YamlWriter writes JSON-style values (null, strings, booleans, numbers,
** maps and lists) in YAML format.
**
@Js
class YamlWriter
{
  new make(OutStream out)
  {
    this.out = out
  }

  This writeYaml(Obj? obj)
  {
    write(obj, 0, false)
  }

  private This write(Obj? obj, Int depth, Bool isListItem)
  {
    if (obj is Map) return writeMap(obj, depth, isListItem)
    if (obj is List) return writeList(obj, depth, isListItem)
    return writeVal(obj)
  }

  private This writeMap(Map map, Int depth, Bool isListItem)
  {
    n := 0
    map.each |val, key|
    {
      // If it's the first key of an object in a list, we don't indent; the
      // dash and space (2 chars) that have already been written act as the
      // indent.
      if ((n == 0) && isListItem)
        w(key).w(":")
      else
        indent(depth).w(key).w(":")

      if ((val is Map) || (val is List))
        nl.write(val, depth+1, false)
      else
        w(" ").writeVal(val).nl

      n++
    }

    return this
  }

  private This writeList(List list, Int depth, Bool isListItem)
  {
    list.each |item|
    {
      indent(depth).w("- ")

      //  If the item is a collection, handle it on the same line
      if ((item is Map) || (item is List))
      {
        write(item, depth+1, true)
      }
      else
      {
        writeVal(item).nl
      }
    }
    return this
  }

  private This writeVal(Obj? obj)
  {
    if (obj is Str)
    {
      if ((obj as Str).any |c| { specialChars.containsChar(c) })
      {
        w("\"")
        w(obj)
        w("\"")
        return this
      }
    }

    w(obj)
    return this
  }

  private This w(Obj? obj)
  {
    if (obj == null)
      out.print("null")
    else
      out.print(obj.toStr)
    return this
  }

  private This nl()
  {
    out.printLine
    return this
  }

  private This indent(Int depth) { w(Str.spaces(depth*2)) }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static const Str specialChars := ":{}[],&*#?|-<>=!%@`"

  private OutStream out
}

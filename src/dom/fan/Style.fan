//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Dec 2014  Andy Frank  Creation
//

using gfx

**
** Style models CSS style properties.
**
@NoDoc @Js
class Style
{
  ** Private ctor.
  private new make() {}

  ** Clear all style declarations.
  native This clear()

  ** Get the given property value.
  **   color := style["color"]
  @Operator native Obj? get(Str name)

  ** Set the given propery value.
  **   style["color"] = "#f00"
  @Operator This set(Str name, Str val)
  {
    if (vendor.containsKey(name))
    {
      setProp("-webkit-$name", val)
      setProp(   "-moz-$name", val)
      setProp(    "-ms-$name", val)
    }
    setProp(name, val)
    return this
  }

  ** Set all the given property values.
  **   style.setAll(["color":"#f00", "font-weight":"bold"])
  This setAll(Str:Obj map)
  {
    map.each |v,n| { set(n,v) }
    return this
  }

  ** Set properties via CSS text.
  **   style.setText("color: #f00; font-weight: bold;")
  This setText(Str css)
  {
    css.split(';').each |s|
    {
      if (s.isEmpty) return
      i := s.index(":")
      n := s[0..<i].trim
      v := s[i+1..-1].trim
      set(n, v)
    }
    return this
  }

  ** Set CSS property.
  private native Void setProp(Str name, Str val)

  ** Property names that require vendor prefixes.
  private const static Str:Str[] vendor := [:].setList([
    "flex",
    "flex-direction",
  ])
}
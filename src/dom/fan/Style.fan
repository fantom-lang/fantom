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

  ** Get the computed property value.
  native Obj? computed(Str name)

  ** Get the given property value.
  **   color := style["color"]
  @Operator native Obj? get(Str name)

  ** Set the given propery value.  If 'val' is null this
  ** property is removed.
  **   style["color"] = "#f00"
  @Operator This set(Str name, Str? val)
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
  This setAll(Str:Str? map)
  {
    map.each |v,n| { set(n,v) }
    return this
  }

  ** Set properties via CSS text.
  **   style.setText("color: #f00; font-weight: bold;")
  This setCss(Str css)
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

  ** Convenience for 'get("width")'.
  Str? width
  {
    get { get("width") }
    set { set("width", it) }
  }

  ** Convenience for 'get("height")'.
  Str? height
  {
    get { get("height") }
    set { set("height", it) }
  }

  ** Convenience to set CSS width and height.
  This setSize(Str w, Str h)
  {
    set("width", w)
    set("height", h)
    return this
  }

  ** Set CSS property.
  private native Void setProp(Str name, Str? val)

  ** Break out standard CSS property into required vendor prefixes.
  internal Str[] toVendor(Str name)
  {
    if (vendor.containsKey(name))
    {
      // 14-Aug-2015: Safari 8.0.7 chokes on foreign vendor prefixes when
      // a transition animatation is used directly in the 'style' attr
      w := Win.cur
      if (w.isWebkit)  return ["-webkit-$name"]
      if (w.isFirefox) return [   "-moz-$name", name]
      if (w.isIE)      return [    "-ms-$name", name]
    }
    return [name]
  }

  ** Property names that require vendor prefixes.
  private const static Str:Str[] vendor := [:].setList([
    "align-content",
    "align-items",
    "flex",
    "flex-direction",
    "flex-wrap",
    "justify-content",
    "transform",
  ])
}
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Aug 09  Brian Frank  Creation
//

**
** Modes width, style, color, and radius of a rectangular border.
**
@Js
@Serializable { simple = true }
const class Border
{

  ** Width in pixels of top side, default is 1.
  const Int widthTop := 1
  ** Width in pixels of right side, default is 1.
  const Int widthRight := 1
  ** Width in pixels of bottom side, default is 1.
  const Int widthBottom := 1
  ** Width in pixels of left side, default is 1.
  const Int widthLeft := 1

  ** Style of top side as one of styleX constants, default is solid.
  const Int styleTop := styleSolid
  ** Style of right side as one of styleX constants, default is solid.
  const Int styleRight := styleSolid
  ** Style of bottom side as one of styleX constants, default is solid.
  const Int styleBottom := styleSolid
  ** Style of left side as one of styleX constants, default is solid.
  const Int styleLeft := styleSolid

  ** Constant identifier for solid style.
  static const Int styleSolid  := 0
  ** Constant identifier for inset style.
  static const Int styleInset  := 1
  ** Constant identifier for outside style.
  static const Int styleOutset := 2

  ** Color of top side, default is black.
  const Color colorTop := black
  ** Color of right side, default is black.
  const Color colorRight := black
  ** Color of bottom side, default is black.
  const Color colorBottom := black
  ** Color of left side, default is black.
  const Color colorLeft := black

  ** Radius in pixels of top-left corner, default is 0.
  const Int radiusTopLeft := 0
  ** Radius in pixels of top-right corner, default is 0.
  const Int radiusTopRight := 0
  ** Radius in pixels of bottom-right corner, default is 0.
  const Int radiusBottomRight := 0
  ** Radius in pixels of bottom-left corner, default is 0.
  const Int radiusBottomLeft := 0

  // to avoid Color javascript initializer dependency
  private static const Color black := Color(0)

  **
  ** Default is zero pixel border.
  **
  static const Border defVal := Border("0")

  **
  ** Construct with it-block
  **
  new make(|This| f)
  {
    f(this)
    toStr = formatStr
  }

  **
  ** Parse a border from string (see `toStr`).  If invalid
  ** and checked is true then throw ParseErr otherwise
  ** return null.  The string formatted as four optional
  ** parts, where each part may have 1 to 4 values:
  **   border := [width] [style] [color] [radius]
  **   width  := top ["," right ["," bottom ["," left]]]
  **   style  := top ["," right ["," bottom ["," left]]]
  **   color  := top ["," right ["," bottom ["," left]]]
  **   radius := top-left ["," top-right ["," bottom-right ["," bottom-left]]]
  **
  ** Width and radius must be integers, color must match `Color` string
  ** format, and style must be "solid", "inset", or "outset".  If one side
  ** is not specified, it is reflected from the opposite side:
  **   a      =>  a,a,a,a
  **   a,b    =>  a,b,a,b
  **   a,b,c  =>  a,b,c,b
  **
  ** Examples:
  **   Border("2")          =>  2 solid #000000 0
  **   Border("#abc")       =>  1 solid #aabbcc 0
  **   Border("2 inset 3")  =>  2 inset #000000 3
  **   Border("0,1,2,3")    =>  0,1,2,3 solid #000000 0
  **   Border("0,1,2 #00f") =>  0,1,2 solid #0000ff 0
  **
  static Border? fromStr(Str str, Bool checked := true)
  {
    try
    {
      if (str.isEmpty) return defVal
      return makeStr(str)
    }
    catch {}
    if (checked) throw ParseErr("Invalid Border: $str")
    return null
  }

  private new makeStr(Str str)
  {
    p := BorderParser(str)

    p.parseGroup(1) |s| { Int.fromStr(s, 10, false) }
    this.widthTop    = p.top
    this.widthRight  = p.right
    this.widthBottom = p.bottom
    this.widthLeft   = p.left

    p.parseGroup(styleSolid) |s| { Border.styleFromStr(s, false) }
    this.styleTop    = p.top
    this.styleRight  = p.right
    this.styleBottom = p.bottom
    this.styleLeft   = p.left

    p.parseGroup(black) |s| { Color.fromStr(s, false) }
    this.colorTop    = p.top
    this.colorRight  = p.right
    this.colorBottom = p.bottom
    this.colorLeft   = p.left

    p.parseGroup(0) |s| { Int.fromStr(s, 10, false) }
    this.radiusTopLeft     = p.top
    this.radiusTopRight    = p.right
    this.radiusBottomRight = p.bottom
    this.radiusBottomLeft  = p.left

    if (p.tok != null) throw Err()
    this.toStr = formatStr
  }

  **
  ** Hash is based on string format.
  **
  override Int hash() { toStr.hash }

  **
  ** Equality is based on string format.
  **
  override Bool equals(Obj? obj)
  {
    that := obj as Border
    if (that == null) return false
    return toStr == that.toStr
  }

  **
  ** Return "solid", "inset", "outset" for int constant.
  **
  static Str styleToStr(Int s)
  {
    switch (s)
    {
      case styleSolid:  return "solid"
      case styleInset:  return "inset"
      case styleOutset: return "outset"
      default:          throw ArgErr()
    }
  }

  **
  ** Parse style string into int constant - see `styleToStr`.
  **
  static Int? styleFromStr(Str s, Bool checked := true)
  {
    switch (s)
    {
      case "solid":  return styleSolid
      case "inset":  return styleInset
      case "outset": return styleOutset
      default:
        if (checked) throw ParseErr(s)
        return null
    }
  }

  **
  ** String format - see `fromStr` for format.
  **
  override const Str toStr

  private Str formatStr()
  {
    s := StrBuf()
    formatPart(s, widthTop, widthRight, widthBottom, widthLeft) { it.toStr }
    formatPart(s, styleTop, styleRight, styleBottom, styleLeft) { styleToStr(it) }
    formatPart(s, colorTop, colorRight, colorBottom, colorLeft) { it.toStr }
    formatPart(s, radiusTopLeft, radiusTopRight, radiusBottomRight, radiusBottomLeft) { it.toStr }
    return s.toStr
  }

  private StrBuf formatPart(StrBuf s, Obj t, Obj r, Obj b, Obj l, |Obj->Str| f)
  {
    if (!s.isEmpty) s.addChar(' ')
    if (l == r)
    {
      if (t == b)
      {
        if (t == l) return s.add(f(t))
        return s.add(f(t)).addChar(',').add(f(l))
      }
      return s.add(f(t)).addChar(',').add(f(r)).addChar(',').add(f(b))
    }
    return s.add(f(t)).addChar(',').add(f(r)).addChar(',').add(f(b)).addChar(',').add(f(l))
  }

  **
  ** Return widthRight+widthLeft, widthTop+widthBottom
  **
  Size toSize() { Size(widthRight+widthLeft, widthTop+widthBottom) }

}

**************************************************************************
** BorderParser
**************************************************************************

@Js
internal class BorderParser
{
  new make(Str str) { this.str = str; next }

  Void parseGroup(Obj def, |Str s->Obj?| f)
  {
    top = tok != null ? f(tok) : null
    if (top == null) { top = right = bottom = left = def; return }
    right  = comma ? parse(f) : top
    bottom = comma ? parse(f) : top
    left   = comma ? parse(f) : right
    if (comma) throw Err()
    next
  }

  private Obj parse(|Str s->Obj?| f)
  {
    next
    val := f(tok)
    if (val == null) throw Err()
    return val
  }

  private Void next()
  {
    // if no more tokens
    size := str.size
    if (n >= size) { tok = null; comma = false; return }

    // strip leading whitespace
    while (n < size && str[n] == ' ') ++n

    // parse token
    s := n
    for (; n<size; ++n)
      if (str[n] == ' ' || str[n] == ',') break
    tok = str[s ..< n]

    // strip trailing whitespace
    while (n < size && str[n] == ' ') ++n

    // check if we have a comma, if so skip it and return true
    comma = n < size && str[n] == ','
    if (comma) ++n
  }

  Str str
  Int n
  Str? tok := "?"
  Bool comma
  Obj? top; Obj? right; Obj? bottom; Obj? left;
}
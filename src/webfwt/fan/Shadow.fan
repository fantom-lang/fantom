//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jul 2011  Andy Frank  Creation
//

using gfx
using fwt

**
** Models styled shadows.
**
@Js
@Serializable { simple=true }
const class Shadow
{
  ** Color of shadow
  const Color color := Color.black

  ** Offset for shadow.
  const Point offset := Point(0,0)

  ** Blur radius for shadow.
  const Int blur := 0

  ** Spread radius for shadow.
  const Int spread := 0

  ** Default is no shadow.
  static const Shadow defVal := Shadow.fromStr("#000 0 0")

  ** Construct with it-block
  new make(|This| f)
  {
    f(this)
    toStr = formatStr
  }

  **
  ** Parse a shadow from string (see `toStr`).  If invalid
  ** and checked is true then throw ParseErr otherwise
  ** return null.  The string is formated as:
  **
  **   shadow := color x y [blur [spread]]
  **
  ** Color must match `gfx::Color` string format. Position,
  ** blur, and spread must all be integers.
  **
  ** Examples:
  **   Shadow("#000 1 1")      => #000 1 1 0 0
  **   Shadow("#f00 1 1 2")    => #f00 1 1 2 0
  **   Shadow("#fff 0 -1 1")   => #fff 0 -1 1 0
  **   Shadow("#555 2 2 0 5")  => #555 2 2 0 5
  **
  static new fromStr(Str str, Bool checked := true)
  {
    try
    {
      if (str.isEmpty) return defVal
      return makeStr(str)
    }
    catch {}
    if (checked) throw ParseErr("Invalid Shadow: $str")
    return null
  }

  private new makeStr(Str str)
  {
    p := str.split(' ')
    if (p.size < 3 || p.size > 5) throw Err()
    this.color  = Color.fromStr(p.first.trim)
    this.offset = Point(p[1].trim.toInt, p[2].trim.toInt)
    this.blur   = p.size > 3 ? p[3].trim.toInt : 0
    this.spread = p.size > 4 ? p[4].trim.toInt : 0
    this.toStr  = formatStr
  }

  ** Hash is based on string format.
  override Int hash() { toStr.hash }

  ** Equality is based on string format.
  override Bool equals(Obj? obj)
  {
    that := obj as Shadow
    if (that == null) return false
    return toStr == that.toStr
  }

  ** String format - see `fromStr` for format.
  override const Str toStr

  private Str formatStr()
  {
    s := StrBuf()
    s.join(color.toCss)
    s.join(offset.x)
    s.join(offset.y)
    if (blur > 0 || spread > 0)
    {
      s.join(blur)
      if (spread > 0) s.join(spread)
    }
    return s.toStr
  }

  ** Get CSS string for this Shadow.
  Str toCss()
  {
    s := StrBuf()
    s.join("${offset.x}px")
    s.join("${offset.y}px")
    if (spread > 0) s.join("${blur}px ${spread}px")
    else if (blur > 0) s.join("${blur}px")
    s.join(color.toCss)
    return s.toStr
  }
}
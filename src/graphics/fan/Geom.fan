//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 2008  Brian Frank  Creation (gfx version)
//   29 Mar 2017  Brian Frank  SVG/CSS changes
//

**************************************************************************
** Point
**************************************************************************

**
** Point models a x,y coordinate.
**
@Js
@Serializable { simple = true }
const class Point
{
  ** Default instance is '0,0'.
  const static Point defVal := Point(0f, 0f)

  ** Construct with x, y.
  new make(Float x, Float y) { this.x = x; this.y = y }

  ** Construct with x, y.
  new makeInt(Int x, Int y) { this.x = x.toFloat; this.y = y.toFloat }

  ** Parse from comma or space separated string.
  ** If invalid then throw ParseErr or return null based on checked flag.
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      f := GeomUtil.parseFloatList(s)
      return make(f[0], f[1])
    }
    catch {}
    if (checked) throw ParseErr("Invalid Point: $s")
    return null
  }

  ** Return 'x+tx, y+ty'
  Point translate(Point t) { make(x+t.x, y+t.y) }

  ** Return hash of x and y.
  override Int hash() { x.hash.xor(y.hash.shiftl(16)) }

  ** Return if obj is same Point value.
  override Bool equals(Obj? obj)
  {
    that := obj as Point
    if (that == null) return false
    return this.x == that.x && this.y == that.y
  }

  ** Return '"x y"'
  override Str toStr() { GeomUtil.formatFloats2(x, y) }

  ** X coordinate
  const Float x

  ** Y coordinate
  const Float y
}

**************************************************************************
** Size
**************************************************************************

**
** Size models the width and height of a shape.
**
@Js
@Serializable { simple = true }
const class Size
{
  ** Default instance is '0,0'.
  const static Size defVal := Size(0f, 0f)

  ** Construct with w, h.
  new make(Float w, Float h) { this.w = w; this.h = h }

  ** Construct with w, h as integers.
  new makeInt(Int w, Int h) { this.w = w.toFloat; this.h = h.toFloat }

  ** Parse from comma or space separated string.
  ** If invalid then throw ParseErr or return null based on checked flag.
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      f := GeomUtil.parseFloatList(s)
      return make(f[0], f[1])
    }
    catch {}
    if (checked) throw ParseErr("Invalid Size: $s")
    return null
  }

  ** Return '"w h"'
  override Str toStr() { GeomUtil.formatFloats2(w, h) }

  ** Return hash of w and h.
  override Int hash() { w.hash.xor(h.hash.shiftl(16)) }

  ** Return if obj is same Size value.
  override Bool equals(Obj? obj)
  {
    that := obj as Size
    if (that == null) return false
    return this.w == that.w && this.h == that.h
  }

  ** Width
  const Float w

  ** Height
  const Float h
}

**************************************************************************
** Rect
**************************************************************************

**
** Represents the x,y coordinate and w,h size of a rectangle.
**
@Js
@Serializable { simple = true }
const class Rect
{
  ** Default instance is 0, 0, 0, 0.
  const static Rect defVal := Rect(0f, 0f, 0f, 0f)

  ** Construct with x, y, w, h.
  new make(Float x, Float y, Float w, Float h)
  {
    this.x = x; this.y = y
    this.w = w; this.h = h
  }

  ** Construct with x, y, w, h as integers.
  new makeInt(Int x, Int y, Int w, Int h)
  {
    this.x = x.toFloat; this.y = y.toFloat
    this.w = w.toFloat; this.h = h.toFloat
  }

  ** Construct from a Point and Size instance
  new makePosSize(Point p, Size s)
  {
    this.x = p.x; this.y = p.y
    this.w = s.w; this.h = s.h
  }

  ** Parse from comma or space separated string.
  ** If invalid then throw ParseErr or return null based on checked flag.
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      f := GeomUtil.parseFloatList(s)
      return make(f[0], f[1], f[2], f[3])
    }
    catch {}
    if (checked) throw ParseErr("Invalid Rect: $s")
    return null
  }

  ** Get the x, y coordinate of this rectangle.
  Point pos() { Point(x, y) }

  ** Get the w, h size of this rectangle.
  Size size() { Size(w, h) }

  ** Return true if x,y is inside the bounds of this rectangle.
  Bool contains(Point pt)
  {
    return pt.x >= this.x && pt.x <= this.x+w &&
           pt.y >= this.y && pt.y <= this.y+h
  }

  ** Return true if this rectangle intersects any portion of that rectangle
  Bool intersects(Rect that)
  {
    ax1 := this.x; ay1 := this.y; ax2 := ax1 + this.w; ay2 := ay1 + this.h
    bx1 := that.x; by1 := that.y; bx2 := bx1 + that.w; by2 := by1 + that.h
    return !(ax2 <= bx1 || bx2 <= ax1 || ay2 <= by1 || by2 <= ay1)
  }

  ** Compute the intersection between this rectangle and that rectangle.
  ** If there is no intersection, then return `defVal`.
  Rect intersection(Rect that)
  {
    ax1 := this.x; ay1 := this.y; ax2 := ax1 + this.w; ay2 := ay1 + this.h
    bx1 := that.x; by1 := that.y; bx2 := bx1 + that.w; by2 := by1 + that.h
    rx1 := ax1.max(bx1); rx2 := ax2.min(bx2)
    ry1 := ay1.max(by1); ry2 := ay2.min(by2)
    rw := rx2 - rx1
    rh := ry2 - ry1
    if (rw <= 0f || rh <= 0f) return defVal
    return make(rx1, ry1, rw, rh)
  }

  ** Compute the union between this rectangle and that rectangle,
  ** which is the bounding box that exactly contains both rectangles.
  Rect union(Rect that)
  {
    ax1 := this.x; ay1 := this.y; ax2 := ax1 + this.w; ay2 := ay1 + this.h
    bx1 := that.x; by1 := that.y; bx2 := bx1 + that.w; by2 := by1 + that.h
    rx1 := ax1.min(bx1); rx2 := ax2.max(bx2)
    ry1 := ay1.min(by1); ry2 := ay2.max(by2)
    rw := rx2 - rx1
    rh := ry2 - ry1
    if (rw <= 0f || rh <= 0f) return defVal
    return make(rx1, ry1, rw, rh)
  }

  ** Return '"x y w h"'
  override Str toStr() { return GeomUtil.formatFloats4(x, y, w, h) }

  ** Return hash of x, y, w, and h.
  override Int hash()
  {
    x.hash.xor(y.hash.shiftl(8)).xor(w.hash.shiftl(16)).xor(w.hash.shiftl(24))
  }

  ** Return if obj is same Rect value.
  override Bool equals(Obj? obj)
  {
    that := obj as Rect
    if (that == null) return false
    return this.x == that.x && this.y == that.y &&
           this.w == that.w && this.h == that.h
  }

  ** X coordinate
  const Float x

  ** Y coordinate
  const Float y

  ** Width
  const Float w

  ** Height
  const Float h
}

**************************************************************************
** Insets
**************************************************************************

**
** Insets represents spacing around the edge of a rectangle.
**
@Js
@Serializable { simple = true }
const class Insets
{
  ** Default instance 0, 0, 0, 0.
  const static Insets defVal := Insets(0f, 0f, 0f, 0f)

  **
  ** Construct with top, and optional right, bottom, left.  If one side
  ** is not specified, it is reflected from the opposite side:
  **
  **   Insets(5)     => Insets(5,5,5,5)
  **   Insets(5,6)   => Insets(5,6,5,6)
  **   Insets(5,6,7) => Insets(5,6,7,6)
  **
  new make(Num top, Num? right := null, Num? bottom := null, Num? left := null)
  {
    if (right == null) right = top
    if (bottom == null) bottom = top
    if (left == null) left = right
    this.top = top.toFloat
    this.right = right.toFloat
    this.bottom = bottom.toFloat
    this.left = left.toFloat
  }

  ** Parse from comma or space separated string using CSS format:
  **   - "top"
  **   - "top, right" (implies bottom = top, left = right)
  **   - "top, right, bottom" (implies left = right)
  **   - "top, right, bottom, left"
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      f := GeomUtil.parseFloatList(s)
      return make(f[0], f.getSafe(1), f.getSafe(2), f.getSafe(3))
    }
    catch (Err e) {}
    if (checked) throw ParseErr("Invalid Insets: $s")
    return null
  }

  ** If all four sides are equal return '"len"'
  ** otherwise return '"top right bottom left"'.
  override Str toStr()
  {
    if (top == right && top == bottom && top == left)
      return GeomUtil.formatFloat(top)
    else
      return GeomUtil.formatFloats4(top, right, bottom, left)
  }

  ** Return hash of top, right, bottom, left.
  override Int hash()
  {
    top.hash.xor(right.hash.shiftl(8)).xor(bottom.hash.shiftl(16)).xor(left.hash.shiftl(24))
  }

  ** Return if obj is same Insets value.
  override Bool equals(Obj? obj)
  {
    that := obj as Insets
    if (that == null) return false
    return this.top == that.top && this.right == that.right &&
           this.bottom == that.bottom && this.left == that.left
  }

  ** Return right+left, top+bottom
  Size toSize() { Size(right+left, top+bottom) }

  ** Top side spacing
  const Float top

  ** Right side spacing
  const Float right

  ** Bottom side spacing
  const Float bottom

  ** Left side spacing
  const Float left

  ** Left plus right
  Float w() { left + right }

  ** Top plus bottom
  Float h() { top + bottom }

  ** Return if all sides are set to zero
  Bool isNone() { top == 0f && right == 0f && bottom == 0f && left == 0f }
}

**************************************************************************
** GeomUtil
**************************************************************************

@NoDoc @Js
const class GeomUtil
{
  ** Split with comma or whitespace CSS/SVG styled syntax
  static Str[] split(Str s)
  {
    acc := Str[,]
    start := 0
    for (i := 0; i<s.size; ++i)
    {
      c := s[i]
      if (c == ' ' || c == ',')
      {
        if (start < i) acc.add(s[start..<i])
        start = i+1
      }
    }
    if (start < s.size) acc.add(s[start..-1])
    return acc
  }

  ** Parse list comma or whitespace separated floats
  static Float[] parseFloatList(Str s)
  {
    split(s).map |tok| { tok.trim.toFloat }
  }

  ** Format two floats to space separated string
  static Str formatFloats2(Float a, Float b)
  {
    StrBuf()
      .add(formatFloat(a)).addChar(' ')
      .add(formatFloat(b)).toStr
  }

  ** Format four floats to space separated string
  static Str formatFloats4(Float a, Float b, Float c, Float d)
  {
    StrBuf()
      .add(formatFloat(a)).addChar(' ')
      .add(formatFloat(b)).addChar(' ')
      .add(formatFloat(c)).addChar(' ')
      .add(formatFloat(d)).toStr
  }

  ** Format float to string
  static Str formatFloat(Float f)
  {
    f.toLocale("0.###", Locale.en)
  }
}
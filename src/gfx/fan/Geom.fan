//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 08  Brian Frank  Creation
//

**************************************************************************
** Point
**************************************************************************

**
** Point represents a coordinate in the display space.
**
@Js
@Serializable { simple = true }
const class Point
{
  ** Default instance is 0, 0.
  const static Point defVal := Point(0, 0)

  ** Construct with x, y.
  new make(Int x, Int y) { this.x = x; this.y = y }

  ** Parse from string.  If invalid and checked is
  ** true then throw ParseErr otherwise return null.
  static Point? fromStr(Str s, Bool checked := true)
  {
    try
    {
      comma := s.index(",")
      return make(s[0..<comma].trim.toInt, s[comma+1..-1].trim.toInt)
    }
    catch {}
    if (checked) throw ParseErr("Invalid Point: $s")
    return null
  }

  ** Return 'x+tx, y+ty'
  Point translate(Point t) { make(x+t.x, y+t.y) }

  ** Return hash of x and y.
  override Int hash() { x.xor(y.shiftl(16)) }

  ** Return if obj is same Point value.
  override Bool equals(Obj? obj)
  {
    that := obj as Point
    if (that == null) return false
    return this.x == that.x && this.y == that.y
  }

  ** Return '"x,y"'
  override Str toStr() { "$x,$y" }

  ** X coordinate
  const Int x

  ** Y coordinate
  const Int y
}

**************************************************************************
** Size
**************************************************************************

**
** Size represents the width and height of a rectangle.
**
@Js
@Serializable { simple = true }
const class Size
{
  ** Default instance is 0, 0.
  const static Size defVal := Size(0, 0)

  ** Construct with w, h.
  new make(Int w, Int h) { this.w = w; this.h = h }

  ** Parse from string.  If invalid and checked is
  ** true then throw ParseErr otherwise return null.
  static Size? fromStr(Str s, Bool checked := true)
  {
    try
    {
      comma := s.index(",")
      return make(s[0..<comma].trim.toInt, s[comma+1..-1].trim.toInt)
    }
    catch {}
    if (checked) throw ParseErr("Invalid Size: $s")
    return null
  }

  ** Return '"w,h"'
  override Str toStr() { "$w,$h" }

  ** Return hash of w and h.
  override Int hash() { w.xor(h.shiftl(16)) }

  ** Return if obj is same Size value.
  override Bool equals(Obj? obj)
  {
    that := obj as Size
    if (that == null) return false
    return this.w == that.w && this.h == that.h
  }

  ** Width
  const Int w

  ** Height
  const Int h
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
  const static Rect defVal := Rect(0, 0, 0, 0)

  ** Construct with x, y, w, h.
  new make(Int x, Int y, Int w, Int h)
    { this.x = x; this.y = y; this.w = w; this.h = h }

  ** Construct from a Point and Size instance
  new makePosSize(Point p, Size s)
    { this.x = p.x; this.y = p.y; this.w = s.w; this.h= s.h }

  ** Parse from string.  If invalid and checked is
  ** true then throw ParseErr otherwise return null.
  static Rect? fromStr(Str s, Bool checked := true)
  {
    try
    {
      c1 := s.index(",")
      c2 := s.index(",", c1+1)
      c3 := s.index(",", c2+1)
      return make(s[0..<c1].trim.toInt, s[c1+1..<c2].trim.toInt,
                  s[c2+1..<c3].trim.toInt, s[c3+1..-1].trim.toInt)
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
  Bool contains(Int x, Int y)
  {
    return x >= this.x && x <= this.x+w &&
           y >= this.y && y <= this.y+h
  }

  ** Return '"x,y,w,h"'
  override Str toStr() { return "$x,$y,$w,$h" }

  ** Return hash of x, y, w, and h.
  override Int hash()
  {
    x.xor(y.shiftl(8)).xor(w.shiftl(16)).xor(w.shiftl(24))
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
  const Int x

  ** Y coordinate
  const Int y

  ** Width
  const Int w

  ** Height
  const Int h
}

**************************************************************************
** Insets
**************************************************************************

**
** Insets represent a number of pixels around the edge of a rectangle.
**
@Js
@Serializable { simple = true }
const class Insets
{
  ** Default instance 0, 0, 0, 0.
  const static Insets defVal := Insets(0, 0, 0, 0)

  **
  ** Construct with top, and optional right, bottom, left.  If one side
  ** is not specified, it is reflected from the opposite side:
  **
  **   Insets(5)     => Insets(5,5,5,5)
  **   Insets(5,6)   => Insets(5,6,5,6)
  **   Insets(5,6,7) => Insets(5,6,7,6)
  **
  new make(Int top, Int? right := null, Int? bottom := null, Int? left := null)
  {
    if (right == null) right = top
    if (bottom == null) bottom = top
    if (left == null) left = right
    this.top = top
    this.right = right
    this.bottom = bottom
    this.left = left
  }

  ** Parse from string (see `toStr`).  If invalid and checked
  ** is true then throw ParseErr otherwise return null.  Supported
  ** formats are:
  **   - "len"
  **   - "top,right,bottom,left"
  static Insets? fromStr(Str s, Bool checked := true)
  {
    try
    {
      c1 := s.index(",")
      if (c1 == null) { len := s.toInt; return make(len, len, len, len) }
      c2 := s.index(",", c1+1)
      c3 := s.index(",", c2+1)
      return make(s[0..<c1].trim.toInt, s[c1+1..<c2].trim.toInt,
                  s[c2+1..<c3].trim.toInt, s[c3+1..-1].trim.toInt)
    }
    catch {}
    if (checked) throw ParseErr("Invalid Insets: $s")
    return null
  }

  ** If all four sides are equal return '"len"'
  ** otherwise return '"top,right,bottom,left"'.
  override Str toStr()
  {
    if (top == right && top == bottom && top == left)
      return top.toStr
    else
      return "$top,$right,$bottom,$left"
  }

  ** Return hash of top, right, bottom, left.
  override Int hash()
  {
    top.xor(right.shiftl(8)).xor(bottom.shiftl(16)).xor(left.shiftl(24))
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
  const Int top

  ** Right side spacing
  const Int right

  ** Bottom side spacing
  const Int bottom

  ** Left side spacing
  const Int left
}

**************************************************************************
** Hints
**************************************************************************

**
** Hints model heights/weight contraints.  Hint differs from Size
** in that 'w' or 'h' can be null.
**
@Js
const class Hints
{

  ** Default instance is null, null.
  const static Hints defVal := Hints(null, null)

  ** Construct with w, h.
  new make(Int? w, Int? h) { this.w = w; this.h = h }

  ** Return '"w,h"'
  override Str toStr() { "$w,$h" }

  ** Return hash of w and h.
  override Int hash()
  {
    (w == null ? 3 : w.hash).xor((h == null ? 11 : h.hash).shiftl(16))
  }

  ** Return if obj is same Hints value.
  override Bool equals(Obj? obj)
  {
    that := obj as Hints
    if (that == null) return false
    return this.w == that.w && this.h == that.h
  }

  ** Add the given w and h to this hint's dimensions.  If a hint
  ** dimension is null, then the resulting dimension is null too.
  @Operator Hints plus(Size size)
  {
    make(w == null ? null : w + size.w, h == null ? null : h + size.h)
  }

  ** Subtract the given w and h from this hint's dimensions.  If a hint
  ** dimension is null, then the resulting dimension is null too.
  @Operator Hints minus(Size size)
  {
    make(w == null ? null : w - size.w, h == null ? null : h - size.h)
  }

  ** Suggested width or null if no contraints
  const Int? w

  ** Suggested height or null if no contraints
  const Int? h
}
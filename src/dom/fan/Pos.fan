//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Sep 2015  Andy Frank  Creation
//

**
** Pos represents a coordinate.
**
@Js
@Serializable { simple = true }
const class Pos
{
  ** Default instance is 0, 0.
  const static Pos defVal := Pos(0, 0)

  ** Construct with x, y.
  new make(Int x, Int y) { this.x = x; this.y = y }

  ** Parse from string.  If invalid and checked is
  ** true then throw ParseErr otherwise return null.
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      comma := s.index(",")
      return make(s[0..<comma].trim.toInt, s[comma+1..-1].trim.toInt)
    }
    catch {}
    if (checked) throw ParseErr("Invalid Pos: $s")
    return null
  }

  ** Return 'x+tx, y+ty'
  Pos translate(Int tx, Int ty) { make(x+tx, y+ty) }

  ** Return 'x+tx, y+ty'
  Pos translatePos(Pos t) { make(x+t.x, y+t.y) }

  ** Assuming a page position, return position relative to the given 'Elem'.
  Pos rel(Elem e)
  {
    p := e.pagePos
    return make(x-p.x, y-p.y)
  }

  ** Return hash of x and y.
  override Int hash() { x.xor(y.shiftl(16)) }

  ** Return if obj is same Pos value.
  override Bool equals(Obj? obj)
  {
    that := obj as Pos
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
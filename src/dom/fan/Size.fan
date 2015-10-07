//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   7 Oct 2015  Andy Frank  Creation
//

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
  static new fromStr(Str s, Bool checked := true)
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
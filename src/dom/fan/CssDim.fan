//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jun 2016  Andy Frank  Creation
//

**
** CssDim models a CSS dimension which is a number with a unit attached.
**
@NoDoc @Js
@Serializable { simple = true }
const class CssDim
{
  ** Default instance is 0px.
  const static CssDim defVal := CssDim(0, "px")

  ** Create a new CssDim with given value and unit.
  new make(Num val, Str unit)
  {
    this.val  = val
    this.unit = unit
  }

  ** Parse from string.  If invalid and checked is
  ** true then throw ParseErr otherwise return null.
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      if (s == "auto") return autoVal
      n := StrBuf()
      f := false
      for (i:=0; i<s.size; i++)
      {
        ch := s[i]
        if (ch == '-' || ch.isDigit) n.addChar(ch)
        else if (ch == '.') { f=true; n.addChar(ch) }
        else break
      }
      v := f ? n.toStr.toFloat : n.toStr.toInt
      u := s[n.size..-1]
      if (u.size == 0) throw Err("Missing unit")
      if (u.all |ch| { ch=='%' || ch.isAlpha } == false) throw Err("Invalid unit")
      return make(v, u)
    }
    catch (Err err)
    {
      if (checked) throw ParseErr("Invalid CssDim: $s", err)
      return null
    }
  }

  ** Hash is 'toStr.hash'.
  override Int hash() { toStr.hash }

  ** Return if obj is same CssDim value.
  override Bool equals(Obj? obj)
  {
    that := obj as CssDim
    if (that == null) return false
    return this.val == that.val && this.unit == that.unit
  }

  ** Return '"<val><unit>"'
  override Str toStr()
  {
    this === autoVal ? "auto" : "${val}$unit"
  }

  ** Value of dimension.
  const Num val

  ** Unit of dimension.
  const Str unit

  private static const CssDim autoVal := CssDim(0, "auto")
}
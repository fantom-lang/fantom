//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Jul 08  Brian Frank  Creation
//

**
** Pen defines how a shape is stroked.
**
@simple
const class Pen
{

  **
  ** Width of the stroke, default is 1.
  **
  const Int width := 1

  **
  ** Defines how two ends of unjoined segements are stroked.
  ** Valid values are `capSquare`, `capButt`, and `capRound`.
  ** Default is capSquare.
  **
  const Int cap := capSquare

  ** Constant for `cap`
  static const Int capSquare := 0
  ** Constant for `cap`
  static const Int capButt  := 1
  ** Constant for `cap`
  static const Int capRound := 2

  **
  ** Defines how two path segments are joined at the endpoints.
  ** Valid values are `joinMiter`, `joinRound`, and `joinBevel`.
  ** Default is joinMiter.
  **
  const Int join := joinMiter

  ** Constant for `join`
  static const Int joinMiter := 0
  ** Constant for `join`
  static const Int joinBevel := 1
  ** Constant for `join`
  static const Int joinRound := 3

  **
  ** Dash pattern as on/off again lengths.  If null
  ** then shapes are stroked solid.
  **
  const Int[]? dash

  **
  ** Default pen is width of 1 with capSquare and joinMiter.
  **
  static const Pen def := make

  **
  ** Parse a pen from string (see `toStr`).  If invalid
  ** and checked is true then throw ParseErr otherwise
  ** return null.
  **
  static Pen? fromStr(Str str, Bool checked := true)
  {
    try
    {
      Int? w := null
      c := capSquare
      j := joinMiter
      Int[]? d := null

      b := str.index("[")
      if (b != null)
      {
        d = Int[,]
        str[b+1...str.index("]")].split(',').each |Str tok| { d.add(tok.toInt) }
        str = str[0...b].trim
      }

      str.split.each |Str s|
      {
        switch (s)
        {
          case "capSquare": c = capSquare
          case "capButt":   c = capButt
          case "capRound":  c = capRound
          case "joinMiter": j = joinMiter
          case "joinBevel": j = joinBevel
          case "joinRound": j = joinRound
          default:          w = s.toInt
        }
      }

      return Pen { it.width = w; it.cap = c; it.join = j; it.dash = d }
    }
    catch {}
    if (checked) throw ParseErr("Invalid Pen: $str")
    return null
  }

  **
  ** Hash the fields.
  **
  override Int hash()
  {
    h := width ^ (cap << 16) ^ (join << 20)
    if (dash != null) h ^= dash.hash << 32
    return h
  }

  **
  ** Equality is based on Pen's fields.
  **
  override Bool equals(Obj? obj)
  {
    that := obj as Pen
    if (that == null) return false
    return this.width == that.width &&
           this.cap   == that.cap   &&
           this.join  == that.join  &&
           this.dash  == that.dash
  }

  **
  ** Return '"width cap join dash"' such as '"2 capButt joinBevel [1,1]"'.
  ** Omit cap, join, or dash if at defaults.
  **
  override Str toStr()
  {
    s := width.toStr

    switch (cap)
    {
      case capButt:  s += " capButt"
      case capRound: s += " capRound"
    }

    switch (join)
    {
      case joinBevel: s += " joinBevel"
      case joinRound: s += " joinRound"
    }

    if (dash != null) s += " [" + dash.join(",") + "]"
    return s
  }

}
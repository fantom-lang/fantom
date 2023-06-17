//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Feb 2022  Brian Frank  Creation
//

**
** Stroke defines the how to render shape outlines.
**
@Js
@Serializable { simple = true }
const class Stroke
{
  ** Default value is width 1, no dash, butt cap, miter join.
  static const Stroke defVal := makeFields

  ** Value with width of zero
  static const Stroke none := makeFields(0f)

  **
  ** Parse from string format:
  **    width [dash] cap join
  **
  ** Examples:
  **   0.5
  **   2 [1, 2]
  **   round radius
  **
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      width := 1f
      dash  := null
      cap   := StrokeCap.butt
      join  := StrokeJoin.miter

      Str[]? toks
      bracketStart := s.index("[")
      if (bracketStart != null)
      {
        bracketEnd := s.indexr("]")
        dash = s[bracketStart+1..<bracketEnd]
        toks = s[0..<bracketStart].split.addAll(s[bracketEnd+1..-1].split)
      }
      else
      {
        if (s.isEmpty) throw Err()
        toks = s.split
      }

      toks.each |tok|
      {
        if (tok.isEmpty) return

        char := tok[0]

        if (char.isDigit || char == '.')  { width = Float.fromStr(tok); return }

        tryCap := StrokeCap.fromStr(tok, false)
        if (tryCap != null) { cap = tryCap; return }

        join = StrokeJoin.fromStr(tok, true)
      }

      return makeFields(width, dash, cap, join)
    }
    catch (Err e)
    {
      if (checked) throw ParseErr("Stroke: $s")
      return null
    }
  }

  ** Make with an it-block
  new make(|This| f) { f(this) }

  ** Make with fields
  new makeFields(Float width := 1f, Str? dash := null, StrokeCap cap := StrokeCap.butt, StrokeJoin join := StrokeJoin.miter)
  {
    this.width = width
    this.dash  = dash
    this.cap   = cap
    this.join  = join
  }

  ** Stroke width.  Default is 1.
  const Float width := 1f

  ** Dash pattern as space/comma separated numbers of dashes and gaps.
  ** If null then render as solid line.
  const Str? dash

  ** How to render line end caps.  Default is butt.
  const StrokeCap cap := StrokeCap.butt

  ** How to render line joins. Default is miter.
  const StrokeJoin join := StrokeJoin.miter

  ** Is the width set to zero
  Bool isNone() { width == 0f }

  ** Hash is based on fields
  override Int hash()
  {
    hash := width.hash
            .xor(cap.ordinal.shiftl(11))
            .xor(join.ordinal.shiftl(13))
    if (dash != null) hash = hash.xor(dash.hash)
    return hash
  }

  ** Equality is based on fields
  override Bool equals(Obj? obj)
  {
    that := obj as Stroke
    if (that == null) return false
    return this.width ==  that.width &&
           this.dash  ==  that.dash  &&
           this.cap   === that.cap   &&
           this.join  === that.join
  }

  ** Return this stroke with different width.
  Stroke toSize(Float newWidth)
  {
    if (this.width == newWidth) return this
    return makeFields(newWidth, dash, cap, join)
  }

  ** Return string format - see `fromStr`
  override Str toStr()
  {
    s := StrBuf()
    if (width != 1f) s.join(GeomUtil.formatFloat(width))
    if (dash != null) s.add(" [").add(dash).add("]")
    if (cap !== StrokeCap.butt) s.addChar(' ').add(cap.name)
    if (join !== StrokeJoin.miter) s.addChar(' ').add(join.name)
    if (s.isEmpty) return GeomUtil.formatFloat(width)
    return s.toStr
  }

}

**************************************************************************
** StrokeCap
**************************************************************************

**
** Defines how a stroke end cap is rendered
**
@Js
enum class StrokeCap
{
  ** Cap is a flat edge with no extension
  butt,

  ** Cap is a a rounded semi-circle
  round,

  ** Cap is a half square extension
  square
}

**************************************************************************
** StrokeJoin
**************************************************************************

**
** Defines how two stroke lines are joined together
**
@Js
enum class StrokeJoin
{
  ** Join using a bevel with angle to smooth transition
  bevel,

  ** Join using sharp corners
  miter,

  ** Join using rounded semi-circle (round in SVG terminology)
  radius
}


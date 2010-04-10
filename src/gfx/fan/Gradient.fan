//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jul 08  Brian Frank  Creation
//   31 Mar 10  Brian Frank  Rewrite to support full CSS model
//

**
** Fills a shape with a linear or radial color gradient.
**
** NOTE: SWT only supports linear two stop gradients with no
**  angle using the Graphics.fillRect method.
**
@Js
@Serializable { simple = true }
const class Gradient : Brush
{
  ** Percent unit constant
  const static Unit percent := loadUnit("percent", "%")

  ** Pixel unit constant
  const static Unit pixel := loadUnit("pixel", "px")

  ** Mode is linear or radial
  const GradientMode mode := GradientMode.linear

  ** Starting point x coordinate with unit defined by `x1Unit`
  const Int x1 := 0

  ** Starting point y coordinate with unit defined by `y1Unit`
  const Int y1 := 0

  ** Ending point x coordinate with unit defined by `x2Unit`
  const Int x2 := 100

  ** Ending point y coordinate with unit defined by `y2Unit`
  const Int y2 := 100

  ** Unit of `x1` which must be `percent` or `pixel`
  const Unit x1Unit := pixel

  ** Unit of `y1` which must be `percent` or `pixel`
  const Unit y1Unit  := pixel

  ** Unit of `x2` which must be `percent` or `pixel`
  const Unit x2Unit := pixel

  ** Unit of `y2` which must be `percent` or `pixel`
  const Unit y2Unit  := pixel

  ** List of gradient stops, default is "white 0.0" to "black 1.0".
  const GradientStop[] stops := defStops

  **
  ** Parse a gradient from string (see `toStr`).  If invalid
  ** and checked is true then throw ParseErr otherwise
  ** return null:
  **
  **   <gradient>      :=  <linear> | <radial> | <impliedLinear>
  **   <linear>        :=  "linear(" <args> ")"
  **   <radial>        :=  "radial(" <args> ")"
  **   <impliedLinear> :=  <args>
  **   <args>          :=  <start> "," <end> ("," <stop>)*
  **   <start>         :=  <pos> <pos>
  **   <end>           :=  <pos> <pos>
  **   <pos>           :=  <int> <unit> // no space allowed between
  **   <stop>          :=  <color> [<float>]  // 0f..1f
  **   <color>         :=  #AARRGGBB, #RRGGBB, #RGB
  **   <unit>          :=  "px" | "%"
  **
  ** The general format is a start and end position followed by a comma list of
  ** gradient stops.  The start and end positions are x, y coordinates (% or pixel).
  ** The stops are a color followed by a position in the range (0..1).  If the
  ** position is omitted it is calcaulated as percentage:
  **    #000, #fff        =>  #000 0.0, #fff 1.0
  **    #000, #abc, #fff  =>  #000 0.0, #000 0.5, #fff 1.0
  **
  ** Examples:
  **   Gradient("linear(0% 0%, 100% 100%, #f00, #00f)") =>  linear(0% 0%, 100% 100%, #ff0000 0.0, #0000ff 1.0)
  **   Gradient("5px 3px, 25px 30px, #f00, #00f")       =>  linear(5px 3px, 25px 30px, #ff0000 0.0, #0000ff 1.0)
  **   Gradient("0% 50%, 100% 50%, #f00 0.1, #00f 0.9") =>  linear(0% 50%, 100% 50%, #ff0000 0.1, #0000ff 0.9)
  **
  static Gradient? fromStr(Str str, Bool checked := true)
  {
    try
    {
      return makeStr(str)
    }
    catch {}
    if (checked) throw ParseErr("Invalid Gradient: $str")
    return null
  }

  private new makeStr(Str str)
  {
    // if function syntax
    if (str[-1] == ')')
    {
      if (str.startsWith("radial(")) this.mode = GradientMode.radial
      else if (!str.startsWith("linear(")) throw Err()
      str = str["linear(".size .. -2]
    }

    // tokenize into parts by comma
    parts := str.split(',')

    // first two parts are pos: // x y as ##% or ##px
    for (i := 0; i<2; ++i)
    {
      pos  := parts[i]
      coor := pos.split
      if (coor.size != 2) throw Err()

      Int? x; Int? y
      Unit? xUnit; Unit? yUnit

      xs := coor[0]
      if (xs.endsWith("%"))       { x = xs[0..-2].toInt; xUnit = percent }
      else if (xs.endsWith("px")) { x = xs[0..-3].toInt; xUnit = pixel }
      else throw Err()

      ys := coor[1]
      if (ys.endsWith("%"))       { y = ys[0..-2].toInt; yUnit = percent }
      else if (ys.endsWith("px")) { y = ys[0..-3].toInt; yUnit = pixel }
      else throw Err()

      if (i == 0)
      {
        this.x1 = x; this.x1Unit = xUnit
        this.y1 = y; this.y1Unit = yUnit
      }
      else
      {
        this.x2 = x; this.x2Unit = xUnit
        this.y2 = y; this.y2Unit = yUnit
      }
    }

    // stop colors and optional positions
    stopColors := Color[,]
    stopPos    := Str?[,]
    for (i := 2; i<parts.size; ++i)
    {
      stopPart := parts[i]
      space := stopPart.index(" ")
      if (space == null)
      {
        stopColors.add(Color.fromStr(stopPart))
        stopPos.add(null)
      }
      else
      {
        stopColors.add(Color.fromStr(stopPart[0..<space]))
        stopPos.add(stopPart[space+1..-1])
      }
    }
    if (stopColors.size < 2) throw Err()

    // compute final stops
    this.stops = stopColors.map |color, i|
    {
      pos := stopPos[i]?.toFloat ?: (i * 100 / (stopPos.size - 1)).toFloat / 100f
      return GradientStop(color, pos)
    }
  }

  **
  ** Construct for it-block.
  ** Throw ArgErr if any units are invalid or less than 2 stops.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
    if (x1Unit !== percent && x1Unit !== pixel) throw ArgErr("Invalid x1Unit: $x1Unit")
    if (y1Unit !== percent && y1Unit !== pixel) throw ArgErr("Invalid y1Unit: $y1Unit")
    if (x2Unit !== percent && x2Unit !== pixel) throw ArgErr("Invalid x2Unit: $x2Unit")
    if (y2Unit !== percent && y2Unit !== pixel) throw ArgErr("Invalid y2Unit: $y2Unit")
    if (stops.size < 2) throw ArgErr("Must have 2 or more stops")
  }

  **
  ** Hash the fields.
  **
  override Int hash()
  {
    return (mode.hash.shiftl(28))
           .xor(x1.hash.shiftl(21))
           .xor(y1.hash.shiftl(14))
           .xor(x2.hash.shiftl(21))
           .xor(y2.hash.shiftl(14))
           .xor(stops.hash)
  }

  **
  ** Equality is based on fields.
  **
  override Bool equals(Obj? obj)
  {
    that := obj as Gradient
    if (that == null) return false
    return this.mode   == that.mode   &&
           this.x1     == that.x1     &&
           this.y1     == that.y1     &&
           this.x1Unit == that.x1Unit &&
           this.y1Unit == that.y1Unit &&
           this.x2     == that.x2     &&
           this.y2     == that.y2     &&
           this.x2Unit == that.x2Unit &&
           this.y2Unit == that.y2Unit &&
           this.stops  == that.stops
  }

  **
  ** Return '"[point1:color1; point2:color2]"'.
  ** This string format is subject to change.
  **
  override Str toStr()
  {
    s := StrBuf()
    s.add(mode.name).addChar('(')
    s.add(x1).add(x1Unit.symbol).addChar(' ')
    s.add(y1).add(y1Unit.symbol).addChar(',')
    s.add(x2).add(x2Unit.symbol).addChar(' ')
    s.add(y2).add(y2Unit.symbol)
    stops.each |stop| { s.addChar(',').add(stop) }
    return s.addChar(')').toStr
  }

  ** Just in case unit database is not available, create unit as fallback
  private static Unit loadUnit(Str name, Str symbol)
  {
    try
      return Unit.find(name)
    catch (Err e)
      return Unit.fromStr("$name;$symbol")
  }

  ** white 0% to black 100%
  private static const GradientStop[] defStops :=
  [
    GradientStop(Color.white, 0f),
    GradientStop(Color.black, 1f),
  ]

}

**************************************************************************
** GradientStop
**************************************************************************

**
** GradientStop is used with `Gradient` to model a color stop.
**
@Js
const class GradientStop
{
  **
  ** Construct with color, pos, and unit.
  **
  new make(Color color, Float pos)
  {
    this.color = color
    this.pos   = pos
  }

  ** Color for the stop
  const Color color

  ** Position of the stop within range (0f..1f)
  const Float pos

  **
  ** Hash the fields.
  **
  override Int hash() { pos.hash.xor(color.hash) }

  **
  ** Equality is based on fields.
  **
  override Bool equals(Obj? obj)
  {
    that := obj as GradientStop
    if (that == null) return false
    return this.pos   == that.pos   &&
           this.color == that.color
  }

  **
  ** Return stop formatted as "{color} {pos}".
  **
  override Str toStr()
  {
    "${color} ${pos}"
  }
}
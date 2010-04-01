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

  ** Starting point x coordinate with unit defined by `xUnit`
  const Int x := 50

  ** Starting point y coordinate with unit defined by `yUnit`
  const Int y

  ** Unit of `x` which must be `percent` or `pixel`
  const Unit xUnit := percent

  ** Unit of `y` which must be `percent` or `pixel`
  const Unit yUnit  := percent

  ** Angle measured in degrees of linear gradient.  If null, then
  ** the angle is implied to be computed as the opposite side of
  ** the starting point.  For example if x and y is 0% (top left
  ** hand corner), then the angle is computed such that the end
  ** point is bottom right hand corner.
  const Int? angle

  ** List of gradient stops, default is "white 0%" to "black 100%".
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
  **   <args>          :=  <start> [<angle>] ("," <stop>)*
  **   <start>         :=  <namedStart> | <xyStart>
  **   <namedStart>    :=  (<xName>) | (<yName>) | (<xName> <yName>) | (<yName> <xName>)
  **   <xNamed>        :=  "top"  | "center" | "bottom"
  **   <yNamed>        :=  "left" | "center" | "right"
  **   <xyStart>       :=  <pos> <pos>
  **   <angle>         :=  <int> "deg"  // no space allowed between
  **   <stop>          :=  <color> [<pos>]
  **   <color>         :=  #AARRGGBB, #RRGGBB, #RGB
  **   <pos>           :=  <int> <unit> // no space allowed between
  **   <unit>          := "px" | "%"
  **
  ** The general format is a start position followed by a comma list of gradient
  ** stops.  The starting position may be named or x, y coordinate (% or pixel).
  ** Named coordinates are conveniences for 0%, 50%, or 100%.  If a dimension is
  ** omitted it is assumed to be 50%.  For example:
  **    top          =>  50% 0%
  **    bottom       =>  50% 100%
  **    top right    =>  100% 0%
  **    bottom left  =>  0% 100%
  **
  ** The stops are a color followed by an optional % or pixel position.  If
  ** the position is omitted it is calcaulated as percentage:
  **    #000, #fff        =>  #000 0%, #fff 100%
  **    #000, #abc, #fff  =>  #000 0%, #000 50%, #fff 100%
  **
  ** Examples:
  **   Gradient("linear(top, #f00, #00f)")      =>  linear(50% 0%,#ff0000 0%,#0000ff 100%)
  **   Gradient("top, #f00, #00f")              =>  linear(50% 0%,#ff0000 0%,#0000ff 100%)
  **   Gradient("10px 10px -45deg, #f00, #00f") =>  linear(10px 10px -45deg,#ff0000 0%,#0000ff 100%)
  **   Gradient("left, #f00 10px, #00f 90%")    =>  linear(0% 50%,#ff0000 10px,#0000ff 90%)
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

    // first part is pos: x y angle
    pos := parts[0]

    // if angle was included into position parse and strip it
    if (pos.endsWith("deg"))
    {
      sp := pos.indexr(" ")
      angle = pos[sp+1..-4].toInt
      pos = pos[0..<sp]
    }

    // handle named positions
    if (pos[0].isAlpha)
    {
      switch (pos)
      {
        case "top":    x = 50;  y = 0;
        case "bottom": x = 50;  y = 100;
        case "center": x = 50;  y = 50;
        case "left":   x = 0;   y = 50;
        case "right":  x = 100; y = 50;

        case "top left":      case "left top":      x = 0;   y = 0;
        case "top center":    case "center top":    x = 50;  y = 0;
        case "top right":     case "right top":     x = 100; y = 0;

        case "center left":   case "left center":   x = 0;   y = 50;
        case "center center":                       x = 50;  y = 50;
        case "center right":  case "right center":  x = 100; y = 50;

        case "bottom left":   case "left bottom":   x = 0;   y = 100;
        case "bottom center": case "center bottom": x = 50;  y = 100;
        case "bottom right":  case "right bottom":  x = 100; y = 100;

        default: throw Err()
      }
    }

    // x y as ##% or ##px
    else
    {
      coor := pos.split
      if (coor.size != 2) throw Err()

      xs := coor[0]
      if (xs.endsWith("%"))       { this.x = xs[0..-2].toInt }
      else if (xs.endsWith("px")) { this.x = xs[0..-3].toInt; this.xUnit = pixel }
      else throw Err()

      ys := coor[1]
      if (ys.endsWith("%"))       { this.y = ys[0..-2].toInt }
      else if (ys.endsWith("px")) { this.y = ys[0..-3].toInt; this.yUnit = pixel }
      else throw Err()
    }

    // stop colors and optional positions
    stopColors := Color[,]
    stopPos    := Str?[,]
    for (i := 1; i<parts.size; ++i)
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
      s := stopPos[i] ?: (i * 100 / (stopPos.size - 1)) + "%"
      if (s.endsWith("px")) return GradientStop(color, s[0..-3].toInt, pixel)
      if (s.endsWith("%"))  return GradientStop(color, s[0..-2].toInt, percent)
      throw Err()
    }
  }

  **
  ** Construct for it-block.
  ** Throw ArgErr if any units are invalid or less than 2 stops.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
    if (xUnit !== percent && xUnit !== pixel) throw ArgErr("Invalid xUnit: $xUnit")
    if (yUnit !== percent && yUnit !== pixel) throw ArgErr("Invalid yUnit: $yUnit")
    if (stops.size < 2) throw ArgErr("Must have 2 or more stops")
  }

  **
  ** Hash the fields.
  **
  override Int hash()
  {
    return (mode.hash.shiftl(28))
           .xor(x.hash.shiftl(21))
           .xor(y.hash.shiftl(14))
           .xor(stops.hash)
  }

  **
  ** Equality is based on fields.
  **
  override Bool equals(Obj? obj)
  {
    that := obj as Gradient
    if (that == null) return false
    return this.mode  == that.mode  &&
           this.x     == that.x     &&
           this.y     == that.y     &&
           this.xUnit == that.xUnit &&
           this.yUnit == that.yUnit &&
           this.angle == that.angle &&
           this.stops == that.stops
  }

  **
  ** Return '"[point1:color1; point2:color2]"'.
  ** This string format is subject to change.
  **
  override Str toStr()
  {
    s := StrBuf()
    s.add(mode.name).addChar('(')
    s.add(x).add(xUnit.symbol).addChar(' ')
    s.add(y).add(yUnit.symbol)
    if (angle != null) s.addChar(' ').add(angle).add("deg")
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
    GradientStop(Color.white, 0, percent),
    GradientStop(Color.black, 100, percent),
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
  new make(Color color, Int pos, Unit unit := Gradient.percent)
  {
    this.color = color
    this.pos   = pos
    this.unit  = unit
    if (unit !== Gradient.percent && unit !== Gradient.pixel) throw ArgErr("Invalid unit: $unit")
  }

  ** Color for the stop
  const Color color

  ** Position of the stop with unit defined by `unit`
  const Int pos

  ** Unit of `pos` which must be `Gradient.percent` or `Gradient.pixl`
  const Unit unit

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
           this.color == that.color &&
           this.unit  == that.unit
  }

  **
  ** Return stop formatted as "{color} {pos}{unit}".
  **
  override Str toStr()
  {
    "${color} ${pos}${unit.symbol}"
  }
}
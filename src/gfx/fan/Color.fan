//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 08  Brian Frank  Creation
//

**
** Color models an ARGB color with an alpha, red, green,
** and blue component between 0 and 255.  Color is also
** a solid `Brush`.
**
@js @simple
const class Color : Brush
{

//////////////////////////////////////////////////////////////////////////
// Constants
//////////////////////////////////////////////////////////////////////////

  ** Constant for 0x00_00_00
  const static Color black := make(0x00_00_00)

  ** Constant for 0xff_ff_ff
  const static Color white := make(0xff_ff_ff)

  ** Constant for 0xff_00_00
  const static Color red := make(0xff_00_00)

  ** Constant for 0x00_ff_00
  const static Color green := make(0x00_ff_00)

  ** Constant for 0x00_00_ff
  const static Color blue := make(0x00_00_ff)

  ** Constant for 0x80_80_80
  const static Color gray := make(0x80_80_80)

  ** Constant for 0xa9_a9_a9
  const static Color darkGray := make(0xa9_a9_a9)

  ** Constant for 0xff_ff_00
  const static Color yellow := make(0xff_ff_00)

  ** Constant for 0xff_a5_00
  const static Color orange := make(0xff_a5_00)

  ** Constant for 0x80_00_80
  const static Color purple := make(0x80_00_80)

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Make a new instance with the ARGB components masked
  ** together: bits 31-24 alpha; bits 16-23 red; bits 8-15 green;
  ** bits 0-7 blue.  If hasAlpha is false, then we assume the
  ** alpha bits are 0xFF.
  **
  new make(Int argb := 0, Bool hasAlpha := false)
  {
    if (!hasAlpha) argb |= 0xff00_0000
    this.argb = argb
  }

  **
  ** Construct a color using HSB model (hue, saturation, brightness).
  ** These values are sometimes also known as HSV.  These values
  ** are passed as a list of three floats:
  **   hbs[0]: hue as 0.0 to 360.0
  **   hbs[1]: saturation as 0.0 to 1.0
  **   hbs[2]: brightness (or value) as 0.0 to 1.0
  ** Also see `hsb`.
  **
  static Color makeHsb(Float[] hsb)
  {
    h := hsb[0]; s := hsb[1]; v := hsb[2]
    r := v; g := v; b := v
    if (s != 0f)
    {
      if (h == 360f) h = 0f
      h /= 60f
      i := h.floor
      f := h - i
      p := v * (1f - s)
      q := v * (1f - s * f)
      t := v * (1f - (s*(1f-f)))
      switch (i.toInt)
      {
        case 0: r=v; g=t; b=p
        case 1: r=q; g=v; b=p
        case 2: r=p; g=v; b=t
        case 3: r=p; g=q; b=v
        case 4: r=t; g=p; b=v
        case 5: r=v; g=p; b=q
      }
    }
    return make((r * 255f).toInt << 16 | (g * 255f).toInt << 8 | (b * 255f).toInt, false)
  }

  **
  ** Parse color from string (see `toStr`).  If invalid
  ** and checked is true then throw ParseErr otherwise
  ** return null.  The following formats are supported:
  **   - #AARRGGBB
  **   - #RRGGBB
  **   - #RGB
  **
  ** Examples:
  **   Color.fromStr("#8A0")
  **   Color.fromStr("#88AA00")
  **   Color.fromStr("#d088aa00")
  **
  static Color? fromStr(Str s, Bool checked := true)
  {
    try
    {
      if (!s.startsWith("#")) throw Err()
      sub := s[1..-1]
      hex := sub.toInt(16)
      switch (sub.size)
      {
        case 3:
          r := (hex >> 8) & 0xf; r = (r << 4) | r
          g := (hex >> 4) & 0xf; g = (g << 4) | g
          b := (hex >> 0) & 0xf; b = (b << 4) | b
          return make((r << 16) | (g << 8) | b)
        case 6:
          return make(hex, false)
        case 8:
          return make(hex, true)
        default: throw Err()
      }
    }
    catch {}
    if (checked) throw ParseErr("Invalid Color: $s")
    return null
  }

//////////////////////////////////////////////////////////////////////////
// Color Model
//////////////////////////////////////////////////////////////////////////

  **
  ** The ARGB components masked together: bits 31-24 alpha;
  ** bits 16-23 red; bits 8-15 green; bits 0-7 blue.
  **
  const Int argb

  **
  ** Get the RGB bitmask without the alpha bits.
  **
  Int rgb() { return argb & 0x00ff_ffff }

  **
  ** The alpha component from 0 to 255, where 255 is opaque
  ** and 0 is transparent.
  **
  Int alpha() { return (argb >> 24) & 0xff }

  **
  ** The red component from 0 to 255.
  **
  Int r() { return (argb >> 16) & 0xff }

  **
  ** The green component from 0 to 255.
  **
  Int g() { return (argb >> 8) & 0xff }

  **
  ** The blue component from 0 to 255.
  **
  Int b() { return argb & 0xff }

  **
  ** Return HSB (hue, saturation, brightness) of this color.
  ** These values are sometimes also known as HSV.  These values
  ** are returned as three floats:
  **   hbs[0]: hue as 0.0 to 360.0
  **   hbs[1]: saturation as 0.0 to 1.0
  **   hbs[2]: brightness (or value) as 0.0 to 1.0
  ** Also see `makeHsb`.
  **
  Float[] hsb()
  {
    r := this.r.toFloat
    b := this.b.toFloat
    g := this.g.toFloat
    min := r.min(b.min(g))
    max := r.max(b.max(g))
    delta := max - min
    s := max == 0f ? 0f : delta / max
    h := 0f
    if (s != 0f)
    {
      if (r == max) h = (g - b) / delta
      else if (g == max) h = 2f + (b - r) / delta
      else if (b == max) h = 4f + (r - g) / delta
      h *= 60f
      if (h < 0f) h += 360f
    }
    v := max / 255f
    return [h, s, v]
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Return `argb` as the hash code.
  **
  override Int hash() { return rgb }

  **
  ** Return `argb` as the hash code.
  **
  override Bool equals(Obj? that)
  {
    x := that as Color
    return x == null ? false : x.argb == argb
  }

  **
  ** If the alpha component is 255, then format as '"#RRGGBB"' hex
  ** string, otherwise format as '"#AARRGGBB"' hex string.
  **
  override Str toStr()
  {
    if (alpha == 0xff)
      return "#" + rgb.toHex(6)
    else
      return "#" + argb.toHex(8)
  }

  **
  ** To a valid CSS color string.
  **
  Str toCss()
  {
    if (alpha == 0xff) return "#" + rgb.toHex(6)
    alphaVal := alpha * 100 / 255
    return "rgba($r,$g,$b,0.${alphaVal})"
  }

  **
  ** Get a color which is a lighter shade of this color.
  **
  Color lighter()
  {
    // TODO
    return this
  }

  **
  ** Get a color which is a dark shade of this color.
  **
  Color darker()
  {
    // TODO
    return this
  }

}
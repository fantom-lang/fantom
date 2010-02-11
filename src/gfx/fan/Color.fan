//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 08  Brian Frank  Creation
//

**
** Models an ARGB color (alpha, red, green, blue).
** Color is also a solid `Brush`.
**
@Js
@Serializable { simple = true }
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
    if (!hasAlpha) argb = argb.or(0xff00_0000)
    this.argb = argb
  }

  **
  ** Make a new instance with the ARGB individual
  ** components as integers between 0 and 255.
  **
  static Color makeArgb(Int a, Int r, Int g, Int b)
  {
    return make((a.and(0xff).shiftl(24))
             .or(r.and(0xff).shiftl(16))
             .or(g.and(0xff).shiftl(8))
             .or(b.and(0xff)), true)
  }

  **
  ** Make a new instance with the RGB individual
  ** components as integers between 0 and 255.
  **
  static Color makeRgb(Int r, Int g, Int b)
  {
    return make((r.and(0xff).shiftl(16))
             .or(g.and(0xff).shiftl(8))
             .or(b.and(0xff)), false)
  }

  **
  ** Construct a color using HSV model (hue, saturation, value),
  ** also known as HSB (hue, saturation, brightness):
  **   - hue as 0.0 to 360.0
  **   - saturation as 0.0 to 1.0
  **   - value (or brightness) as 0.0 to 1.0
  ** Also see `h`, `s`, `v`.
  **
  static Color makeHsv(Float h, Float s, Float v)
  {
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
    return make((r * 255f).toInt.shiftl(16)
                .or((g * 255f).toInt.shiftl(8))
                .or((b * 255f).toInt),
                false)
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
          r := hex.shiftr(8).and(0xf); r = r.shiftl(4).or(r)
          g := hex.shiftr(4).and(0xf); g = g.shiftl(4).or(g)
          b := hex.shiftr(0).and(0xf); b = b.shiftl(4).or(b)
          return make(r.shiftl(16).or(g.shiftl(8)).or(b))
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
  Int rgb() { argb.and(0x00ff_ffff) }

  **
  ** The alpha component from 0 to 255, where 255 is opaque
  ** and 0 is transparent.
  **
  Int a() { argb.shiftr(24).and(0xff) }

  **
  ** The red component from 0 to 255.
  **
  Int r() { argb.shiftr(16).and(0xff) }

  **
  ** The green component from 0 to 255.
  **
  Int g() { argb.shiftr(8).and(0xff) }

  **
  ** The blue component from 0 to 255.
  **
  Int b() { argb.and(0xff) }

  **
  ** Hue as a float between 0.0 and 360.0 of the HSV model (hue,
  ** saturation, value), also known as HSB (hue, saturation, brightness).
  ** Also see `makeHsv`, `s`, `v`.
  **
  Float h()
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
    return h
  }

  **
  ** Saturation as a float between 0.0 and 1.0 of the HSV model (hue,
  ** saturation, value), also known as HSB (hue, saturation, brightness).
  ** Also see `makeHsv`, `h`, `v`.
  **
  Float s()
  {
    min := r.min(b.min(g)).toFloat
    max := r.max(b.max(g)).toFloat
    return max == 0f ? 0f : (max-min) / max
  }

  **
  ** Value or brightness as a float between 0.0 and 1.0 of the HSV
  ** model (hue, saturation, value), also known as HSB (hue, saturation,
  ** brightness).  Also see `makeHsv`, `h`, `s`.
  **
  Float v()
  {
    return r.max(b.max(g)).toFloat / 255f
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
    if (a == 0xff)
      return "#" + rgb.toHex(6)
    else
      return "#" + argb.toHex(8)
  }

  **
  ** To a valid CSS color string.
  **
  Str toCss()
  {
    if (a == 0xff) return "#" + rgb.toHex(6)
    alphaVal := a * 100 / 255
    return "rgba($r,$g,$b,0.${alphaVal})"
  }

  **
  ** Get a color which is a lighter shade of this color.
  ** This increases the brightness by the given percentage
  ** which is a float between 0.0 and 1.0.
  **
  Color lighter(Float percentage := 0.2f)
  {
    // adjust value (brighness)
    v := (this.v + percentage).max(0f).min(1f)
    return makeHsv(h, s, v)
  }

  **
  ** Get a color which is a dark shade of this color.
  ** This decreases the brightness by the given percentage
  ** which is a float between 0.0 and 1.0.
  **
  Color darker(Float percentage := 0.2f)
  {
    return lighter(-percentage)
  }

}
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 2008  Brian Frank  Creation
//   10 Apr 2017  Brian Frank  Refactor to model CSS color
//

**
** Models an CSS4 RGB color with alpha
**
@Js
@Serializable { simple = true }
const final class Color : Paint
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Transparent constant with opacity set to zero
  const static Color transparent := make(0, 0f)

  ** Black is #000
  const static Color black := make(0, 1.0f)

  ** White is #FFF
  const static Color white := make(0xFFFFFF, 1.0f)

  ** Make a new instance with the RGB components masked
  ** together: bits 16-23 red; bits 8-15 green; bits 0-7 blue.
  ** Alpha should be a float between 1.0 and 0.0.
  new make(Int rgb := 0, Float a := 1.0f)
  {
    this.rgb = rgb.and(0xff_ff_ff)
    this.a = a.max(0f).min(1.0f)
  }

  ** Make a new instance with the RGB individual
  ** components as integers between 0 and 255 and alpha
  ** as float between 1.0 and 0.0.
  static Color makeRgb(Int r, Int g, Int b, Float a := 1.0f)
  {
    return make((r.and(0xff).shiftl(16))
             .or(g.and(0xff).shiftl(8))
             .or(b.and(0xff)), a)
  }

  ** Construct a color using HSL model (hue, saturation, lightness):
  **   - hue as 0.0 to 360.0
  **   - saturation as 0.0 to 1.0
  **   - lightness (or brightness) as 0.0 to 1.0
  **   - alpha as 0.0 to 1.0
  ** Also see `h`, `s`, `l`.
  static Color makeHsl(Float h, Float s, Float l, Float a := 1.0f)
  {
    c := (1f - (2f * l - 1f).abs) * s
    x := c * (1f - ((h / 60f) % 2f - 1f).abs)
    m := l - c / 2f
    r := 0f
    g := 0f
    b := 0f
         if (h < 60f)               { r=c;  g=x;  b=0f }
    else if (h >= 60f  && h < 120f) { r=x;  g=c;  b=0f }
    else if (h >= 120f && h < 180f) { r=0f; g=c;  b=x  }
    else if (h >= 180f && h < 240f) { r=0f; g=x;  b=c  }
    else if (h >= 240f && h < 300f) { r=x;  g=0f; b=c  }
    else if (h >= 300f && h < 360f) { r=c;  g=0f; b=x  }
    return make(((r+m) * 255f).round.toInt.shiftl(16)
                .or(((g+m) * 255f).round.toInt.shiftl(8))
                .or(((b+m) * 255f).round.toInt), a)
  }

//////////////////////////////////////////////////////////////////////////
// Parsing
//////////////////////////////////////////////////////////////////////////

  ** Parse color from CSS 4 string.  If invalid
  ** and checked is true then throw ParseErr otherwise
  ** return null.  The following formats are supported:
  **   - CSS keyword color
  **   - #RRGGBB
  **   - #RRGGBBAA
  **   - #RGB
  **   - #RGBA
  **   - rgb(r, g b)
  **   - rgba(r, g, b, a)
  **   - hsl(h, s, l)
  **   - hsla(h, s, l, a)
  **
  ** Functional notation works with comma or space separated
  ** arguments.
  **
  ** Examples:
  **   Color.fromStr("red")
  **   Color.fromStr("#8A0")
  **   Color.fromStr("#88AA00")
  **   Color.fromStr("rgba(255, 0, 0, 0.3)")
  **   Color.fromStr("rgb(100% 0% 0% 25%)")
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      // #xxx syntax
      if (s.startsWith("#")) return parseHex(s)

      // keyword
      k := byKeyword[s]
      if (k != null) return k

      // try functional notation
      paren := s.index("(")
      if (paren != null)
      {
        if (s[-1] != ')') throw Err()
        return parseFunc(s[0..<paren], GeomUtil.split(s[paren+1..-2]))
      }

      // bad format
      throw Err()
    }
    catch (Err e) {}
    if (checked) throw ParseErr("Invalid Color: $s")
    return null
  }

  ** Parse comma separated list from string
  @NoDoc
  static Color[]? listFromStr(Str s, Bool checked := true)
  {
    try
    {
      toks := s.split(',')
      if (s.contains("("))
      {
        acc := StrBuf[,]
        inParen := false
        toks.each |tok, i|
        {
          if (inParen) acc.last.addChar(',').add(tok)
          else acc.add(StrBuf().add(tok))
          if (tok.contains("(")) inParen = true
          if (tok.contains(")")) inParen = false
        }
        toks = acc.map |buf->Str| { buf.toStr }
      }
      return toks.map |tok->Color| { Color.fromStr(tok) }
    }
    catch (Err e) e.trace
    if (checked) throw ParseErr("Invalid color list: $s")
    return null
  }

  private static Color parseHex(Str s)
  {
    sub := s[1..-1]
    hex := sub.toInt(16)
    switch (sub.size)
    {
      case 3:
        r := hex.shiftr(8).and(0xf); r = r.shiftl(4).or(r)
        g := hex.shiftr(4).and(0xf); g = g.shiftl(4).or(g)
        b := hex.shiftr(0).and(0xf); b = b.shiftl(4).or(b)
        return make(r.shiftl(16).or(g.shiftl(8)).or(b))
      case 4:
        r := hex.shiftr(12).and(0xf); r = r.shiftl(4).or(r)
        g := hex.shiftr(8).and(0xf);  g = g.shiftl(4).or(g)
        b := hex.shiftr(4).and(0xf);  b = b.shiftl(4).or(b)
        a := hex.shiftr(0).and(0xf);  a = a.shiftl(4).or(a)
        return makeRgb(r, g, b, a/255f)
      case 6:
        return make(hex)
      case 8:
        return make(hex.shiftr(8), GeomUtil.formatFloat(hex.and(0xff)/255f).toFloat)
      default:
        throw Err()
    }
  }

  private static Color parseFunc(Str func, Str[] args)
  {
    switch (func)
    {
      case "rgb":
      case "rgba":
        return makeRgb(parseRgbArg(args[0]), parseRgbArg(args[1]), parseRgbArg(args[2]), parsePercentArg(args.getSafe(3)))
      case "hsl":
      case "hsla":
        return makeHsl(parseDegArg(args[0]), parsePercentArg(args[1]), parsePercentArg(args[2]), parsePercentArg(args.getSafe(3)))
      default:
        throw Err()
    }
  }

  private static Int parseRgbArg(Str s)
  {
    if (s[-1] == '%') return (255f * s[0..-2].toFloat / 100f).toInt
    return s.toInt
  }

  private static Float parseDegArg(Str s)
  {
    if (s.endsWith("deg")) s = s[0..-4]
    f := s.toFloat
    if (f > 360f) f = f.toInt.mod(360).toFloat
    return f
  }

  private static Float parsePercentArg(Str? s)
  {
    if (s == null) return 1.0f
    if (s[-1] == '%') return s[0..-2].toFloat / 100f
    return s.toFloat
  }

//////////////////////////////////////////////////////////////////////////
// Color Model
//////////////////////////////////////////////////////////////////////////

  ** The RGB components masked together: bits 16-23 red;
  ** bits 8-15 green; bits 0-7 blue.
  const Int rgb

  ** The alpha component from 0.0 to 1.0
  const Float a

  ** The red component from 0 to 255.
  Int r() { rgb.shiftr(16).and(0xff) }

  ** The green component from 0 to 255.
  Int g() { rgb.shiftr(8).and(0xff) }

  ** The blue component from 0 to 255.
  Int b() { rgb.and(0xff) }

  ** Hue as a float between 0.0 and 360.0 of the HSL model (hue,
  ** saturation, lightness).  Also see `makeHsl`, `s`, `l`.
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

  ** Saturation as a float between 0.0 and 1.0 of the HSL model (hue,
  ** saturation, lightness).  Also see `makeHsl`, `h`, `l`.
  Float s()
  {
    min := r.min(b.min(g)).toFloat
    max := r.max(b.max(g)).toFloat
    c   := max - min
    if (c == 0f) return 0f
    return c / (1f - (2f * l - 1f).abs) / 255f
  }

  ** Lightness (brightness) as a float between 0.0 and 1.0 of the HSL
  ** model (hue, saturation, lightness). Also see `makeHsl`, `h`, `s`.
  Float l()
  {
    max := r.max(b.max(g)).toFloat
    min := r.min(b.min(g)).toFloat
    return (max + min) * 0.5f / 255f
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  ** Return the hash code.
  override Int hash() { rgb.xor(a.hash.shiftl(24)) }

  ** Equality
  override Bool equals(Obj? that)
  {
    x := that as Color
    if (x == null) return false
    return x.rgb == rgb && x.a == a
  }

  ** If the alpha component is 1.0, then format as '"#RRGGBB"' hex
  ** string, otherwise format as '"rbga()"' notation.
  override Str toStr()
  {
    if (a >= 1.0f) return toHexStr
    aStr := a.toLocale("0.##", Locale.en)
    return "rgba($r,$g,$b,$aStr)"
  }

  ** Format as #RGB, #RRGGBB or #RRGGBBAA syntax
  Str toHexStr()
  {
    hex := rgb.toHex(6)
    if (a >= 1f)
    {
      if (hex[0] == hex[1] && hex[2] == hex[3] && hex[4] == hex[5])
        return "#" + hex[0].toChar + hex[2].toChar + hex[4].toChar
      else
        return "#" + hex
    }
    ahex := (255f * a).toInt.min(255).max(0).toHex(2)
    return "#" + hex + ahex
  }

//////////////////////////////////////////////////////////////////////////
// Paint
//////////////////////////////////////////////////////////////////////////

  ** Always return true
  override Bool isColorPaint() { true }

  ** Return this
  override Color asColorPaint() { this }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  ** Return if `a` is zero, fully transparent
  Bool isTransparent() { a <= 0f }

  ** Adjust the opacity of this color and return new instance,
  ** where 'opacity' is between 0.0  and 1.0.
  Color opacity(Float opacity := 1f)
  {
    make(rgb, a * opacity)
  }

  ** Get a color which is a lighter shade of this color.
  ** This increases the brightness by the given percentage
  ** which is a float between 0.0 and 1.0.
  Color lighter(Float percentage := 0.2f)
  {
    // adjust value (brighness)
    l := (this.l + percentage).max(0f).min(1f)
    return makeHsl(h, s, l)
  }

  ** Get a color which is a dark shade of this color.
  ** This decreases the brightness by the given percentage
  ** which is a float between 0.0 and 1.0.
  Color darker(Float percentage := 0.2f)
  {
    lighter(-percentage)
  }

  ** Adjust saturation as percentage between -1..1.
  Color saturate(Float percentage := 0.2f)
  {
    s := (this.s + percentage).max(0f).min(1f)
    return makeHsl(h, s, l)
  }

  ** Convenience for 'saturate(-percentage)'.
  Color desaturate(Float percentage := 0.2f)
  {
    saturate(-percentage)
  }

//////////////////////////////////////////////////////////////////////////
// Interpolate
//////////////////////////////////////////////////////////////////////////

  ** Interpolate between a and b where t is 0.0 to 1.0 using RGB color model.
  static Color interpolateRgb(Color a, Color b, Float t)
  {
    return Color.makeRgb(interpolateByte(a.r, b.r, t),
                         interpolateByte(a.g, b.g, t),
                         interpolateByte(a.b, b.b, t),
                         interpolatePercent(a.a, b.a, t))
  }

  ** Interpolate between a and b where t is 0.0 to 1.0 using HSL color model.
  static Color interpolateHsl(Color a, Color b, Float t)
  {
    return Color.makeHsl(interpolateDeg(a.h, b.h, t),
                         interpolatePercent(a.s, b.s, t),
                         interpolatePercent(a.l, b.l, t),
                         interpolatePercent(a.a, b.a, t))
  }

  private static Float interpolateDeg(Float a, Float b, Float t)
  {
    (a + (b-a) * t).min(360f).max(0f)
  }

  private static Int interpolateByte(Int a, Int b, Float t)
  {
    (a + (b-a) * t).toInt.min(255).max(0)
  }

  private static Float interpolatePercent(Float a, Float b, Float t)
  {
    (a + (b-a) * t).min(1f).max(0f)
  }

//////////////////////////////////////////////////////////////////////////
// Predefined
//////////////////////////////////////////////////////////////////////////

  @NoDoc static Str[] keywords() { byKeyword.keys }

  private static const Str:Color byKeyword
  static
  {
    // CSS 1, 2, 3, and 4 keywords
    acc := Str:Color[:] { caseInsensitive = true }
    acc["black"] = Color(0x000000)
    acc["silver"] = Color(0xc0c0c0)
    acc["gray"] = Color(0x808080)
    acc["white"] = Color(0xffffff)
    acc["maroon"] = Color(0x800000)
    acc["red"] = Color(0xff0000)
    acc["purple"] = Color(0x800080)
    acc["fuchsia"] = Color(0xff00ff)
    acc["green"] = Color(0x008000)
    acc["lime"] = Color(0x00ff00)
    acc["olive"] = Color(0x808000)
    acc["yellow"] = Color(0xffff00)
    acc["navy"] = Color(0x000080)
    acc["blue"] = Color(0x0000ff)
    acc["teal"] = Color(0x008080)
    acc["aqua"] = Color(0x00ffff)
    acc["orange"] = Color(0xffa500)
    acc["aliceblue"] = Color(0xf0f8ff)
    acc["antiquewhite"] = Color(0xfaebd7)
    acc["aquamarine"] = Color(0x7fffd4)
    acc["azure"] = Color(0xf0ffff)
    acc["beige"] = Color(0xf5f5dc)
    acc["bisque"] = Color(0xffe4c4)
    acc["blanchedalmond"] = Color(0xffebcd)
    acc["blueviolet"] = Color(0x8a2be2)
    acc["brown"] = Color(0xa52a2a)
    acc["burlywood"] = Color(0xdeb887)
    acc["cadetblue"] = Color(0x5f9ea0)
    acc["chartreuse"] = Color(0x7fff00)
    acc["chocolate"] = Color(0xd2691e)
    acc["coral"] = Color(0xff7f50)
    acc["cornflowerblue"] = Color(0x6495ed)
    acc["cornsilk"] = Color(0xfff8dc)
    acc["crimson"] = Color(0xdc143c)
    acc["cyan"] = Color(0x00ffff)
    acc["darkblue"] = Color(0x00008b)
    acc["darkcyan"] = Color(0x008b8b)
    acc["darkgoldenrod"] = Color(0xb8860b)
    acc["darkgray"] = Color(0xa9a9a9)
    acc["darkgreen"] = Color(0x006400)
    acc["darkgrey"] = Color(0xa9a9a9)
    acc["darkkhaki"] = Color(0xbdb76b)
    acc["darkmagenta"] = Color(0x8b008b)
    acc["darkolivegreen"] = Color(0x556b2f)
    acc["darkorange"] = Color(0xff8c00)
    acc["darkorchid"] = Color(0x9932cc)
    acc["darkred"] = Color(0x8b0000)
    acc["darksalmon"] = Color(0xe9967a)
    acc["darkseagreen"] = Color(0x8fbc8f)
    acc["darkslateblue"] = Color(0x483d8b)
    acc["darkslategray"] = Color(0x2f4f4f)
    acc["darkslategrey"] = Color(0x2f4f4f)
    acc["darkturquoise"] = Color(0x00ced1)
    acc["darkviolet"] = Color(0x9400d3)
    acc["deeppink"] = Color(0xff1493)
    acc["deepskyblue"] = Color(0x00bfff)
    acc["dimgray"] = Color(0x696969)
    acc["dimgrey"] = Color(0x696969)
    acc["dodgerblue"] = Color(0x1e90ff)
    acc["firebrick"] = Color(0xb22222)
    acc["floralwhite"] = Color(0xfffaf0)
    acc["forestgreen"] = Color(0x228b22)
    acc["gainsboro"] = Color(0xdcdcdc)
    acc["ghostwhite"] = Color(0xf8f8ff)
    acc["gold"] = Color(0xffd700)
    acc["goldenrod"] = Color(0xdaa520)
    acc["greenyellow"] = Color(0xadff2f)
    acc["grey"] = Color(0x808080)
    acc["honeydew"] = Color(0xf0fff0)
    acc["hotpink"] = Color(0xff69b4)
    acc["indianred"] = Color(0xcd5c5c)
    acc["indigo"] = Color(0x4b0082)
    acc["ivory"] = Color(0xfffff0)
    acc["khaki"] = Color(0xf0e68c)
    acc["lavender"] = Color(0xe6e6fa)
    acc["lavenderblush"] = Color(0xfff0f5)
    acc["lawngreen"] = Color(0x7cfc00)
    acc["lemonchiffon"] = Color(0xfffacd)
    acc["lightblue"] = Color(0xadd8e6)
    acc["lightcoral"] = Color(0xf08080)
    acc["lightcyan"] = Color(0xe0ffff)
    acc["lightgoldenrodyellow"] = Color(0xfafad2)
    acc["lightgray"] = Color(0xd3d3d3)
    acc["lightgreen"] = Color(0x90ee90)
    acc["lightgrey"] = Color(0xd3d3d3)
    acc["lightpink"] = Color(0xffb6c1)
    acc["lightsalmon"] = Color(0xffa07a)
    acc["lightseagreen"] = Color(0x20b2aa)
    acc["lightskyblue"] = Color(0x87cefa)
    acc["lightslategray"] = Color(0x778899)
    acc["lightslategrey"] = Color(0x778899)
    acc["lightsteelblue"] = Color(0xb0c4de)
    acc["lightyellow"] = Color(0xffffe0)
    acc["limegreen"] = Color(0x32cd32)
    acc["linen"] = Color(0xfaf0e6)
    acc["mediumaquamarine"] = Color(0x66cdaa)
    acc["mediumblue"] = Color(0x0000cd)
    acc["mediumorchid"] = Color(0xba55d3)
    acc["mediumpurple"] = Color(0x9370db)
    acc["mediumseagreen"] = Color(0x3cb371)
    acc["mediumslateblue"] = Color(0x7b68ee)
    acc["mediumspringgreen"] = Color(0x00fa9a)
    acc["mediumturquoise"] = Color(0x48d1cc)
    acc["mediumvioletred"] = Color(0xc71585)
    acc["midnightblue"] = Color(0x191970)
    acc["mintcream"] = Color(0xf5fffa)
    acc["mistyrose"] = Color(0xffe4e1)
    acc["moccasin"] = Color(0xffe4b5)
    acc["navajowhite"] = Color(0xffdead)
    acc["oldlace"] = Color(0xfdf5e6)
    acc["olivedrab"] = Color(0x6b8e23)
    acc["orangered"] = Color(0xff4500)
    acc["orchid"] = Color(0xda70d6)
    acc["palegoldenrod"] = Color(0xeee8aa)
    acc["palegreen"] = Color(0x98fb98)
    acc["paleturquoise"] = Color(0xafeeee)
    acc["palevioletred"] = Color(0xdb7093)
    acc["papayawhip"] = Color(0xffefd5)
    acc["peachpuff"] = Color(0xffdab9)
    acc["peru"] = Color(0xcd853f)
    acc["pink"] = Color(0xffc0cb)
    acc["plum"] = Color(0xdda0dd)
    acc["powderblue"] = Color(0xb0e0e6)
    acc["rosybrown"] = Color(0xbc8f8f)
    acc["royalblue"] = Color(0x4169e1)
    acc["saddlebrown"] = Color(0x8b4513)
    acc["salmon"] = Color(0xfa8072)
    acc["sandybrown"] = Color(0xf4a460)
    acc["seagreen"] = Color(0x2e8b57)
    acc["seashell"] = Color(0xfff5ee)
    acc["sienna"] = Color(0xa0522d)
    acc["skyblue"] = Color(0x87ceeb)
    acc["slateblue"] = Color(0x6a5acd)
    acc["slategray"] = Color(0x708090)
    acc["slategrey"] = Color(0x708090)
    acc["snow"] = Color(0xfffafa)
    acc["springgreen"] = Color(0x00ff7f)
    acc["steelblue"] = Color(0x4682b4)
    acc["tan"] = Color(0xd2b48c)
    acc["thistle"] = Color(0xd8bfd8)
    acc["tomato"] = Color(0xff6347)
    acc["transparent"] = transparent
    acc["turquoise"] = Color(0x40e0d0)
    acc["violet"] = Color(0xee82ee)
    acc["wheat"] = Color(0xf5deb3)
    acc["whitesmoke"] = Color(0xf5f5f5)
    acc["yellowgreen"] = Color(0x9acd32)
    acc["rebeccapurple"] = Color(0x663399)
    byKeyword = acc
  }
}


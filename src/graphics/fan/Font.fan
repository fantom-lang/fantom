//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 2008  Brian Frank  Creation
//   29 Mar 2017  Brian Frank  Refactor for predefined font metrics
//

**
** Font models font-family, font-size, and font-style, and font-weight.
** Metrics are available for a predefined set of fonts.
**
@Js
@Serializable { simple = true }
const class Font
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Construct with it-block
  new make(|This| f) { f(this) }

  ** Construct a Font with individual fields
  @NoDoc new makeFields(Str[] names, Float size, FontWeight weight := FontWeight.normal, FontStyle style := FontStyle.normal)
  {
    if (names.isEmpty) throw ArgErr("No names specified")
    this.names  = names
    this.size   = size
    this.weight = weight
    this.style  = style
    this.data   = FontData.find(this)
  }

  ** Parse font from string using CSS shorthand format for
  ** supported properties:
  **
  **   [<style>] [<weight>] <size> <names>
  **
  ** Examples:
  **   Font.fromStr("12pt Arial")
  **   Font.fromStr("bold 10pt Courier")
  **   Font.fromStr("italic bold 8pt Times")
  **   Font.fromStr("italic 300 10pt sans-serif")
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      toks := s.split
      toki := 0

      style := FontStyle.decode(toks[toki], false)
      if (style != null) toki++
      else style = FontStyle.normal

      weight := FontWeight.decode(toks[toki], false)
      if (weight != null) toki++
      else weight = FontWeight.normal

      if (!toks[toki].endsWith("pt")) throw Err()
      size := toks[toki][0..-3].toFloat
      toki++

      names := decodeNames(toks[toki..-1].join(" "))

      return makeFields(names, size, weight, style)
    }
    catch (Err e) {}
    if (checked) throw ParseErr("Invalid Font: $s")
    return null
  }

  private static Str[] decodeNames(Str s)
  {
    s.split(',')
  }

  private static Float decodeSize(Str s)
  {
    if (!s.endsWith("pt")) throw Err("Invalid font size: $s")
    return s[0..-3].toFloat
  }

  private static FontWeight decodeWeight(Str s)
  {
    FontWeight.decode(s)
  }

  private static FontStyle decodeStyle(Str s)
  {
    FontStyle.decode(s)
  }

//////////////////////////////////////////////////////////////////////////
// Props
//////////////////////////////////////////////////////////////////////////

  ** Construct from a map of CSS props such as font-family, font-size.
  ** Also see `toProps`.
  static new fromProps(Str:Str props)
  {
    if (props["font-family"] == null) return null
    return makeFields(
      decodeNames(props["font-family"] ?: "sans-serif"),
      decodeSize(props["font-size"] ?: "12pt"),
      decodeWeight(props["font-weight"] ?: "normal"),
      decodeStyle(props["font-style"] ?: "normal"))
  }

  ** Get CSS style properties for this font.
  ** Also see `fromProps`
  Str:Str toProps()
  {
    acc := Str:Str[:] { ordered = true }
    acc["font-family"] = names.join(",")
    acc["font-size"] = GeomUtil.formatFloat(size) + "pt"
    if (!weight.isNormal) acc["font-weight"] = weight.num.toStr
    if (!style.isNormal) acc["font-style"] = style.name
    return acc
  }

//////////////////////////////////////////////////////////////////////////
// Font
//////////////////////////////////////////////////////////////////////////

  ** First family name in `names`
  Str name() { names.first }

  ** List of prioritized family names
  const Str[] names := ["sans-serif"]

  ** Size of font in points.
  const Float size := 11f

  ** Weight as number from 100 to 900
  const FontWeight weight := FontWeight.normal

  ** Style as normal, italic, or oblique
  const FontStyle style := FontStyle.normal

  ** Normalize to the closest font with metrics
  Font normalize()
  {
    if (data != null) return this
    return FontData.normalize(this)
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  ** Return hash of all fields
  override Int hash()
  {
    names.hash.xor(size.hash).xor(weight.hash * 73).xor(style.hash * 19)
  }

  ** Equality is based on all fields.
  override Bool equals(Obj? that)
  {
    x := that as Font
    if (x == null) return false
    return names  == x.names  &&
           size   == x.size   &&
           weight == x.weight &&
           style  == x.style
  }

  ** Format as '"[style] [weight] <size>pt <names>"'
  override Str toStr()
  {
    s := StrBuf()
    if (!style.isNormal)  s.add(style.name).addChar(' ')
    if (!weight.isNormal) s.add(weight.num).addChar(' ')
    s.add(GeomUtil.formatFloat(size)).add("pt").addChar(' ')
    s.add(names.join(","))
    return s.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  ** Return this font with different point size.
  Font toSize(Float size)
  {
    if (this.size == size) return this
    return Font.makeFields(names, size, weight, style)
  }

  ** Return this font with different style
  Font toStyle(FontStyle style)
  {
    if (this.style == style) return this
    return Font.makeFields(names, size, weight, style)
  }

  ** Return this font with different weight.
  Font toWeight(FontWeight weight)
  {
    if (this.weight == weight) return this
    return Font.makeFields(names, size, weight, style)
  }

//////////////////////////////////////////////////////////////////////////
// Metrics
//////////////////////////////////////////////////////////////////////////

  ** Get font metrics for this font.  If this is not a [normalized]`normalize`
  ** font with built-in metrics, then raise UnsupportedErr.
  FontMetrics metrics(DeviceContext dc := DeviceContext.cur)
  {
    if (data == null) throw UnsupportedErr("FontMetrics not supported: $this")
    return FontMetrics(dc, size, data)
  }

  ** Font metric data from predefined registry
  private const FontData? data
}

**************************************************************************
** FontMetrics
**************************************************************************

** FontMetrics represents font size information for a
** specific `Font` and `DeviceContext`.
@Js
const class FontMetrics
{
  @NoDoc
  new make(DeviceContext dc, Float size, FontData data)
  {
    this.data  = data
    this.size  = size
    this.ratio = (dc.dpi / 72f * fudge) * size / 1000f
  }

  ** Get height of this font which is the sum of
  ** ascent, descent, and leading.
  Float height() { (data.height * ratio).round }

  ** Get ascent of this font which is the distance from
  ** baseline to top of chars, not including any leading area.
  Float ascent() { (data.ascent * ratio).round }

  ** Get descent of this font which is the distance from
  ** baseline to bottom of chars, not including any leading area.
  Float descent() { (data.descent * ratio).round }

  ** Get leading of this font which is the distance above
  ** the ascent which may include accents and other marks.
  Float leading() { (data.leading * ratio).round }

  ** Get the width of the string when painted with this font.
  Float width(Str s)
  {
    d := data
    w := 0
    for (i := 0; i<s.size; ++i)
      w += d.charWidth(s[i])
    return (w.toFloat * ratio).round
  }

  ** Last char we have metrics for
  @NoDoc Int lastChar() { data.lastChar }

  ** This factor is used to tune metrics based on eye-ball testing
  ** since we have simplified metric data for efficiency
  private static const Float fudge := 1.02f

  private const FontData data  // backing metric data
  private const Float size     // font size in points
  private const Float ratio    // ratio to map 1000pt to device context
}

**************************************************************************
** FontWeight
**************************************************************************

** Font weight property values
@Js
enum class FontWeight
{
  thin(100),
  extraLight(200),
  light(300),
  normal(400),
  medium(500),
  semiBold(600),
  bold(700),
  extraBold(800),
  black(900)

  ** Numeric weight as number from 100 to 900
  const Int num

  ** Is this the normal value
  Bool isNormal() { this === normal }

  ** From numeric value 100 to 900
  static FontWeight? fromNum(Int num, Bool checked := true)
  {
    switch (num)
    {
      case 100: return thin
      case 200: return extraLight
      case 300: return light
      case 400: return normal
      case 500: return medium
      case 600: return semiBold
      case 700: return bold
      case 800: return extraBold
      case 900: return black
    }
    if (checked) throw ArgErr("Invalid FontWeight num: $num")
    return null
  }

  ** Decode from CSS string
  @NoDoc static FontWeight? decode(Str s, Bool checked := true)
  {
    try
    {
      val := fromStr(s, false)
      if (val != null) return val
      return fromNum(s.toInt)
    }
    catch (Err e) {}
    if (checked) throw ArgErr("Invalid FontWeight: $s")
    return null
  }

  private new make(Int num) { this.num = num }
}

**************************************************************************
** FontStyle
**************************************************************************

** Font style property values: normal, italic, oblique
@Js
enum class FontStyle
{
  normal, italic, oblique

  ** Is this the normal value
  Bool isNormal() { this === normal }

  ** Decode from CSS string
  @NoDoc static FontStyle? decode(Str s, Bool checked := true)
  {
    fromStr(s, checked)
  }
}
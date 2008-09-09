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
@simple
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
// System Colors
//////////////////////////////////////////////////////////////////////////

  ** System color for dark shadow on widgets
  static native Color sysDarkShadow()
  ** System color for normal shadow on widgets
  static native Color sysNormShadow()
  ** System color for light shadow on widgets
  static native Color sysLightShadow()
  ** System color for highlight shadow on widgets
  static native Color sysHighlightShadow()
  ** System color for foreground and text on widgets
  static native Color sysFg()
  ** System color for background on widgets
  static native Color sysBg()
  ** System color for borders on widgets
  static native Color sysBorder()

  ** System color for list text.
  static native Color sysListFg()
  ** System color for list background.
  static native Color sysListBg()
  ** System color for list selection text.
  static native Color sysListSelFg()
  ** System color for list selection background.
  static native Color sysListSelBg()

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
  static Color fromStr(Str s, Bool checked := true)
  {
    try
    {
      if (!s.startsWith("#")) throw Err()
      s = s[1..-1]
      hex := s.toInt(16)
      switch (s.size)
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
  ** Free any operating system resources used by this instance.
  **
  native Void dispose()

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
  override Bool equals(Obj that)
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

}
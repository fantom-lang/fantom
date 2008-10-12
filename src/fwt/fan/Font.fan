//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//

**
** Font models the rendering of text.
**
@simple
const class Font
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct a Font with family name, size in points,
  ** and optional bold/italic style.
  **
  new make(Str name := null, Int size := 12, Bool bold := false, Bool italic := false)
  {
    if (name != null) this.name = name
    this.size   = size
    this.bold   = bold
    this.italic = italic
  }

  **
  ** Parse font from string (see `toStr`).  If invalid
  ** and checked is true then throw ParseErr otherwise
  ** return null.
  **
  ** Examples:
  **   Font.fromStr("12pt Arial")
  **   Font.fromStr("bold 10pt Courier")
  **   Font.fromStr("bold italic 8pt Times Roman")
  **
  static Font fromStr(Str s, Bool checked := true)
  {
    try
    {
      Str name := null
      Int size := null
      bold   := false
      italic := false

      toks := s.split
      for (i:=0; i<toks.size; ++i)
      {
        tok := toks[i]
        if (tok == "bold") bold = true;
        else if (tok == "italic") italic = true
        else if (size != null) name = name == null ? tok : "$name $tok"
        else if (!tok.endsWith("pt")) throw Err()
        else size = tok[0..-3].toInt
      }

      return make(name, size.toInt, bold, italic)
    }
    catch {}
    if (checked) throw ParseErr("Invalid Font: $s")
    return null
  }

//////////////////////////////////////////////////////////////////////////
// System Fonts
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the default system font.
  **
  static native Font sys()

  **
  ** Get the default system mono-spaced font.
  **
  static native Font sysMonospace()

//////////////////////////////////////////////////////////////////////////
// Font
//////////////////////////////////////////////////////////////////////////

  **
  ** Name of font.
  **
  const Str name

  **
  ** Size of font in points.
  **
  const Int size

  **
  ** Is this font bold.
  **
  const Bool bold

  **
  ** Is this font in italic.
  **
  const Bool italic

  **
  ** Free any operating system resources used by this instance.
  **
  native Void dispose()

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Return hash of name, size, and style.
  **
  override Int hash()
  {
    hash := name.hash ^ size.hash
    if (bold) hash *= 73
    if (italic) hash *= 19
    return hash
  }

  **
  ** Equality is based on name, size, and style.
  **
  override Bool equals(Obj? that)
  {
    x := that as Font
    if (x == null) return false
    return name == x.name &&
           size == x.size &&
           bold == x.bold &&
           italic == x.italic
  }

  **
  ** Format as '"[bold] [italic] <size>pt <name>"'
  **
  override Str toStr()
  {
    s := StrBuf()
    if (bold) s.add("bold")
    if (italic)
    {
      if (!s.isEmpty) s.add(" ")
      s.add("italic")
    }
    if (!s.isEmpty) s.add(" ")
    s.add(size).add("pt ").add(name)
    return s.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Return this font, but with the specified point size.
  ** If thsi font already has the given size return this.
  **
  Font toSize(Int size)
  {
    if (this.size == size) return this
    return Font(name, size, bold, italic)
  }

  **
  ** Return this font, but with a plain styling (neither
  ** bold, nor italic).  If this font is already plain
  ** then return this.
  **
  Font toPlain()
  {
    if (!bold && !italic) return this
    return Font(name, size, false, false)
  }

  **
  ** Return this font, but with a bold styling.  If
  ** this font is already bold then return this.
  **
  Font toBold()
  {
    if (bold) return this
    return Font(name, size, true, italic)
  }

  **
  ** Return this font, but with a italic styling.  If
  ** this font is already italic then return this.
  **
  Font toItalic()
  {
    if (italic) return this
    return Font(name, size, bold, true)
  }

//////////////////////////////////////////////////////////////////////////
// Metrics
//////////////////////////////////////////////////////////////////////////

  **
  ** Get height of this font on default display device.  The height
  ** is the pixels is the sum of ascent, descent, and leading.
  **
  native Int height()

  **
  ** Get ascent of this font on default display device.  The ascent
  ** is the distance in pixels from baseline to top of chars, not
  ** including any leading area.
  **
  native Int ascent()

  **
  ** Get descent of this font on default display device.  The descent
  ** is the distance in pixels from baseline to bottom of chars, not
  ** including any leading area.
  **
  native Int descent()

  **
  ** Get leading of this font on default display device.  The leading
  ** area is the distance in pixels above the ascent which may include
  ** accents and other marks.
  **
  native Int leading()

  **
  ** Get the width of the string in pixels when painted
  ** with this font on the default display device.
  **
  native Int width(Str s)


}
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Mar 2022  Brian Frank  Creation
//

using [java] java.awt::FontMetrics as AwtFontMetrics
using graphics

**
** Java2D font metrics
**
const class Java2DFontMetrics : FontMetrics
{
  new make(AwtFontMetrics fm)
  {
    this.height  = fm.getHeight.toFloat
    this.ascent  = fm.getAscent.toFloat
    this.descent = fm.getDescent.toFloat
    this.leading = fm.getLeading.toFloat
    this.fmRef   = Unsafe(fm)
  }

  override const Float height

  override const Float ascent

  override const Float descent

  override const Float leading

  override Float width(Str s)
  {
    fm.stringWidth(s).toFloat
  }

  AwtFontMetrics fm() { fmRef.val }
  const Unsafe fmRef
}



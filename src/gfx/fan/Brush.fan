//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jul 08  Brian Frank  Creation
//   10 Aug 09  Brian Frank  Add Pattern
//

**
** Brush defines how a shape is filled
**   - `Color` is a solid brush
**   - `Gradient` used to paint a color gradient
**   - `Pattern` used to paint with an image
**
@Js
mixin Brush
{
}

**************************************************************************
** Pattern
**************************************************************************

**
** Pattern is an brush for filling shapes with an image.
**
@Js
@Serializable
const class Pattern : Brush
{

  **
  ** Image to use for filling.
  **
  const Image image

  **
  ** Background color to use underneath image filling,
  ** or null for no background color.
  **
  ** This feature is not supported in SWT when used with
  ** Graphics (it is supported in BorderPane).
  **
  const Color? bg

  **
  ** Vertical alignment, default is repeat.
  ** Fill it not supported.
  **
  ** Only repeat is supported in SWT.
  **
  const Valign valign := Valign.repeat

  **
  ** Horizontal alignment, default is repeat.
  ** Fill it not supported.
  **
  ** Only repeat is supported in SWT.
  **
  const Halign halign := Halign.repeat

  **
  ** Construct required image and optional with it-block
  **
  new make(Image image, |This|? f := null)
  {
    this.image = image
    if (f != null) f(this)
    if (halign === Halign.fill || valign === Valign.fill) throw ArgErr()
  }

  **
  ** Hash is based on fields.
  **
  override Int hash()
  {
    return image.hash
           .xor(bg == null ? 97 : bg.hash)
           .xor(halign.hash.shiftl(11))
           .xor(valign.hash.shiftl(7))
  }

  **
  ** Equality is based on fields.
  **
  override Bool equals(Obj? obj)
  {
    that := obj as Pattern
    if (that == null) return false
    return image   == that.image   &&
           bg      == that.bg      &&
           valign  == that.valign  &&
           halign  == that.halign
  }


  **
  ** Return string representation (no guarantee of format)
  **
  override Str toStr()
  {
    s := StrBuf().add(image)
    if (bg != null) s.add(" bg=").add(bg)
    s.add(" valign=").add(valign).add(" halign=").add(halign)
    return s.toStr
  }

}
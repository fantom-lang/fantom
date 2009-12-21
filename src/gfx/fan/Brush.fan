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
@js
mixin Brush
{
}

**************************************************************************
** Gradient
**************************************************************************

**
** Fills a shape using a two color linear gradient.
**
@js
const class Gradient : Brush
{

  // keep this stuff hidden for now until I figure out real design;
  // I'd like to do real SVG percent based stops, in which case we'd
  // probably expose something like GradientStop[]; but SWT doesn't
  // provide too much support

  @nodoc const Point p1
  @nodoc const Point p2
  @nodoc const Color c1
  @nodoc const Color c2
  private new make(Point p1, Color c1, Point p2, Color c2)
  {
    this.p1 = p1; this.c1 = c1
    this.p2 = p2; this.c2 = c2
  }

  **
  ** Construct a two color linear gradient between the two points.
  **
  static Gradient makeLinear(Point p1, Color c1, Point p2, Color c2)
  {
    return make(p1, c1, p2, c2);
  }

  **
  ** Hash the fields.
  **
  override Int hash()
  {
    return (p1.hash.shiftl(45))
           .xor(p2.hash.shiftl(30))
           .xor(c1.hash.shiftl(15))
           .xor(c2.hash)
  }

  **
  ** Equality is based on fields.
  **
  override Bool equals(Obj? obj)
  {
    that := obj as Gradient
    if (that == null) return false
    return this.p1 == that.p1 && this.p2 == that.p2 &&
           this.c1 == that.c1 && this.c2 == that.c2
  }

  **
  ** Return '"[point1:color1; point2:color2]"'.
  ** This string format is subject to change.
  **
  override Str toStr()
  {
    return "[$p1:$c1; $p2:$c2]"
  }
}

**************************************************************************
** Pattern
**************************************************************************

**
** Pattern is an brush for filling shapes with an image.
**
@js @serializable
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
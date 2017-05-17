//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 May 2017  Brian Frank  Creation
//

**
** SVG (Scalar Vector Graphics) utilities
**
@Js
final const class Svg
{
  ** Cannot create/subclass
  private new make() {}

  ** SVG XML namesapce
  static const Uri ns := `http://www.w3.org/2000/svg`

  ** Create element with proper namespace
  static Elem elem(Str tagName)
  {
    Elem(tagName, ns)
  }

  ** Convenience to create 'line' element
  static Elem line(Num x1, Num y1, Num x2, Num y2)
  {
    elem("line") { it->x1 = x1; it->y1 = y1; it->x2 = x2; it->y2 = y2 }
  }

  ** Convenience to create 'rect' element
  static Elem rect(Num x, Num y, Num w, Num h)
  {
    elem("rect") { it->x = x; it->y = y; it->width = w; it->height = h }
  }

  ** Convenience to create 'text' element
  static Elem text(Str text, Num x, Num y)
  {
    elem("text") {  it.text = text; it->x = x; it->y = y }
  }

}
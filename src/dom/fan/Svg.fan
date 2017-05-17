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

  ** Auto-generate an id for the def element and mount it into
  ** the svg document's defs section.  This method will automatically
  ** generate a '<defs>' child in the svg document as needed.
  ** If defs already has an id or is already mounted, then no
  ** action is taken.
  static Str def(Elem svgElem, Elem defElem)
  {
    // sanity check document element
    if (svgElem.tagName != "svg") throw Err("Document not <svg> element: $svgElem.tagName")

    // check for <defs>
    defsElem := svgElem.children.find |kid| { kid.tagName == "defs" }

    // create it if needed
    if (defsElem == null)
    {
      defsElem = elem("defs")
      if (svgElem.hasChildren)
        svgElem.insertBefore(defsElem, svgElem.children.first)
      else
        svgElem.add(defsElem)
    }

    // auto-generate if needed
    if (defElem.id.isEmpty) defElem.id = "def-${defsElem.children.size}"

    // mount if needed
    if (defElem.parent == null) defsElem.add(defElem)

    // return id
    return defElem.id
  }

  ** Mount a definition element using `def` and return a CSS URL
  ** to the fragment identifier such as "url(#def-d)".  This is used
  ** to reference gradient and clip definitions.
  static Str defUrl(Elem svgElem, Elem defElem)
  {
    "url(#" + def(svgElem, defElem) + ")"
  }

}
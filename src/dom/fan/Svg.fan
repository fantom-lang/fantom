//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 May 2017  Brian Frank  Creation
//

using concurrent
using graphics

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

  ** XLink XML namespace
  static const Uri nsXLink := `http://www.w3.org/1999/xlink`

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

  ** Convenience to create a 'image' element
  static Elem image(Uri href, Float x, Float y, Float w, Float h)
  {
    elem("image")
    {
      it->x      = x
      it->y      = y
      it->width  = w
      it->height = h
      it.setAttr("href", href.encode, nsXLink)
    }
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
    if (defElem.id == null) defElem.id = "def-" + genId.incrementAndGet.toHex

    // mount if needed
    if (defElem.parent == null) defsElem.add(defElem)

    // return id
    return defElem.id
  }

  private static const AtomicInt genId := AtomicInt()

  ** Mount a definition element using `def` and return a CSS URL
  ** to the fragment identifier such as "url(#def-d)".  This is used
  ** to reference gradient and clip definitions.
  static Str defUrl(Elem svgElem, Elem defElem)
  {
    "url(#" + def(svgElem, defElem) + ")"
  }

  ** Internal hook to customize Elem.trap behavoir.
  internal static Obj? doTrap(Elem svgElem, Str name, Obj?[]? args := null)
  {
    if (args == null || args.isEmpty)
    {
      // get
      return svgElem.attr(name)?.toStr
    }
    else
    {
      // set
      val := args.first

      // TODO: should we be using trap for text?
      if (name == "text") { svgElem.text = val.toStr; return null }

      // convenience to explode font attrs
      if (name == "font")
      {
        if (val is Str) val = Font.fromStr(val)
        f := (Font)val
        f.toProps.each |v,n| { svgElem.setAttr(n, v.toStr) }
        return null
      }

      // convert to hyphens if needed and route to setAttr
      if (camelMap.containsKey(name)) name = fromCamel(name)
      svgElem.setAttr(name, val.toStr)
      return null
    }
  }

  ** Convert camel case to hyphen notation.
  private static Str fromCamel(Str s)
  {
    h := StrBuf(s.size + 2)
    for (i:=0; i<s.size; ++i)
    {
      ch := s[i]
      if (ch.isUpper) h.addChar('-').addChar(ch.lower)
      else h.addChar(ch)
    }
    return h.toStr
  }

  // TODO: just keep a big whitelist here??
  private static const Str:Str camelMap := Str:Str[:].setList([
    "accentHeight",
    "alignmentBaseline",
    "baselineShift",
    "capHeight",
    "clipPath",
    "clipRule",
    "colorInterpolation",
    "colorInterpolationFilters",
    "colorProfile",
    "colorRendering",
    "dominantBaseline",
    "enableBackground",
    "fillOpacity",
    "fillRule",
    "floodColor",
    "floodOpacity",
    "fontFamily",
    "fontSize",
    "fontSizeAdjust",
    "fontStretch",
    "fontStyle",
    "fontVariant",
    "fontWeight",
    "glyphName",
    "glyphOrientationHorizontal",
    "glyphOrientationVertical",
    "horizAdvX",
    "horizOriginX",
    "imageRendering",
    "letterSpacing",
    "lightingColor",
    "markerEnd",
    "markerMid",
    "markerStart",
    "overlinePosition",
    "overlineThickness",
    "panose1",
    "paintOrder",
    "renderingIntent",
    "shapeRendering",
    "stopColor",
    "stopOpacity",
    "strikethroughPosition",
    "strikethroughThickness",
    "strokeDasharray",
    "strokeDashoffset",
    "strokeLinecap",
    "strokeLinejoin",
    "strokeMiterlimit",
    "strokeOpacity",
    "strokeWidth",
    "textAnchor",
    "textDecoration",
    "textRendering",
    "underlinePosition",
    "underlineThickness",
    "unicode",
    "unicodeBidi",
    "unicodeRange",
    "unitsPerEm",
    "vAlphabetic",
    "vHanging",
    "vIdeographic",
    "vMathematical",
    "values",
    "version",
    "vertAdvY",
    "vertOriginX",
    "vertOriginY",
    "wordSpacing",
    "xHeight",
  ])
}
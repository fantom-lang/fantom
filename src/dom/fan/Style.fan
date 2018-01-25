//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Dec 2014  Andy Frank  Creation
//

using concurrent

**
** Style models CSS style properties for an Elem.
**
@Js class Style
{
  ** Private ctor.
  private new make() {}

  ** The CSS classes for this element.
  native Str[] classes

  ** Return true if this element has the given CSS class name,
  ** or false if it does not.
  native Bool hasClass(Str name)

  ** Add the given CSS class name to this element.  If this
  ** element already contains the given class name, then this
  ** method does nothing. Returns this.
  native This addClass(Str name)

  ** Remove the given CSS class name to this element. If this
  ** element does not have the given class name, this method
  ** does nothing. Returns this.
  native This removeClass(Str name)

  **
  ** Toggle the presence of the given CSS class name based on
  ** the 'cond' argument:
  **   - 'null': remove class if present, or add if missing
  **   - 'true': always add class (see `addClass`)
  **   - 'false': always remove class(see `removeClass`)
  **
  This toggleClass(Str name, Bool? cond := null)
  {
    if (cond?.not ?: hasClass(name)) removeClass(name)
    else addClass(name)
    return this
  }

  **
  ** Add a psuedo-class CSS definietion to this element. A new
  ** class name is auto-generated and used to prefix 'name',
  ** 'name' must start with the ':' character.  Returns the
  ** generated class name.
  **
  **   style.addPseudoClass(":hover", "background: #eee")
  **
  Str addPseudoClass(Str name, Str css)
  {
    if (!name.startsWith(":"))
      throw ArgErr("Pseudo-class name must start with ':'")

    key := "$name/$css"
    cls := pseudoCache[key]
    if (cls == null)
    {
      cls = "dom-style-autogen-$counter.getAndIncrement"
      Win.cur.doc.head.add(Elem("style") {
        it->type = "text/css"
        it.text  = ".${cls}${name} { $css }"
      })
      pseudoCache[key] = cls
    }

    addClass(cls)
    return cls
  }

  ** Clear all style declarations.
  native This clear()

  ** Get the computed property value.
  native Obj? computed(Str name)

  **
  ** Get the effetive style property value, which is the most
  ** specific style or CSS rule in effect on this node. Returns
  ** 'null' if no rule in effect for given property.
  **
  ** This method is restricted to stylesheets that have originated
  ** from the same domain as the document. Any rules that may be
  ** applied from an external sheet will not be included.
  **
  native Obj? effective(Str name)

  ** Get the given property value.
  **   color := style["color"]
  @Operator native Obj? get(Str name)

  ** Set the given propery value.  If 'val' is null this
  ** property is removed.
  **   style["color"] = "#f00"
  @Operator This set(Str name, Obj? val)
  {
    if (val == null) { setProp(name, null); return this }

    sval := ""
    switch (val?.typeof)
    {
      case Duration#: sval = "${val->toMillis}ms"
      default:        sval = val.toStr
    }

    if (vendor.containsKey(name))
    {
      setProp("-webkit-$name", sval)
      setProp(   "-moz-$name", sval)
      setProp(    "-ms-$name", sval)
    }

    if (vendorVals.any |v| { sval.startsWith(v) })
    {
      setProp(name, "-webkit-$sval")
      setProp(name,    "-moz-$sval")
      setProp(name,     "-ms-$sval")
    }

    setProp(name, sval)
    return this
  }

  ** Set all the given property values.
  **   style.setAll(["color":"#f00", "font-weight":"bold"])
  This setAll(Str:Obj? map)
  {
    map.each |v,n| { set(n,v) }
    return this
  }

  ** Set properties via CSS text.
  **   style.setCss("color: #f00; font-weight: bold;")
  This setCss(Str css)
  {
    css.split(';').each |s|
    {
      if (s.isEmpty) return
      i := s.index(":")
      n := s[0..<i].trim
      v := s[i+1..-1].trim
      set(n, v)
    }
    return this
  }

  **
  ** Get or set an attribute.  Attribute names should be specifed
  ** in camel case:
  **    style->backgroundColor == style["background-color"]
  **
  override Obj? trap(Str name, Obj?[]? args := null)
  {
    name = fromCamel(name)
    if (args == null || args.isEmpty) return get(name)
    set(name, args.first)
    return null
  }

  ** Set CSS property.
  private native Void setProp(Str name, Str? val)

  ** Convert camel case to hyphen notation.
  private Str fromCamel(Str s)
  {
    h := StrBuf()
    s.each |ch|
    {
      if (ch.isUpper) h.addChar('-').addChar(ch.lower)
      else h.addChar(ch)
    }
    return h.toStr
  }

  ** Convenience for `toVendor` on a list.
  static internal Str[] toVendors(Str[] names)
  {
    acc := Str[,]
    names.each |n| { acc.addAll(toVendor(n)) }
    return acc
  }

  ** Break out standard CSS property into required vendor prefixes.
  static internal Str[] toVendor(Str name)
  {
    if (vendor.containsKey(name))
    {
      // 14-Aug-2015: Safari 8.0.7 chokes on foreign vendor prefixes when
      // a transition animatation is used directly in the 'style' attr
      w := Win.cur
      if (w.isWebkit)  return ["-webkit-$name"]
      if (w.isFirefox) return [   "-moz-$name", name]
      if (w.isIE)      return [    "-ms-$name", name]
    }
    return [name]
  }

  ** Property names that require vendor prefixes.
  private const static Str:Str[] vendor := [:].setList([
    "align-content",
    "align-items",
    "animation",
    "animation-delay",
    "animation-direction",
    "animation-duration",
    "animation-iteration-count",
    "animation-name",
    "animation-play-state",
    "animation-timing-function",
    "animation-fill-mode",
    "flex",
    "flex-direction",
    "flex-wrap",
    "justify-content",
    "transform",
    "user-select",
  ])

  ** Property values that require vendor prefixes.
  private const static Str[] vendorVals := [
    "linear-gradient"
  ]

  private static const AtomicInt counter := AtomicInt(0)
  private static Str:Str pseudoCache() { (pseudoCacheRef.val as Unsafe).val }
  private static const AtomicRef pseudoCacheRef := AtomicRef(Unsafe(Str:Str[:]))
}
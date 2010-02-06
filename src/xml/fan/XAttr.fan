//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    7 Nov 08  Brian Frank  Creation
//

**
** XAttr models an XML attribute in an element.  Attributes
** are immutable and may be shared across multiple XElem parents.
**
const class XAttr
{

  **
  ** Construct an element with unqualified local name, value,
  ** and optional XML namespace.  The XNs instance should be
  ** defined as an attribute on an ancestor element.  Throw
  ** ArgErr if an attempt is made to qualify the attribute by
  ** the default namespace with prefix of "".
  **
  new make(Str name, Str val, XNs? ns := null)
  {
    if (ns != null && ns.isDefault)
      throw ArgErr("Cannot define attr in default namespace")

    this.name = name
    this.val  = val
    this.ns   =  ns
  }

  **
  ** Construct an attribute which defines a namespace with
  ** "xmlns:<prefix>" name and uri value.  If prefix is "" then
  ** construct the default namespace attribute named "xmlns".
  **
  new makeNs(XNs ns)
  {
    this.name = ns.isDefault ? "xmlns" : "xmlns:$ns.prefix"
    this.val  = ns.uri.toStr
  }

  **
  ** Unqualified local name of the attribute.  If an XML namespace
  ** prefix was specified, then this is everything after the colon:
  **   foo='val'   =>  foo
  **   x:foo='val' =>  foo
  **
  ** Note that attributes which start with "xml:" are not treated
  ** as a namespace:
  **   xml:lang='en' => xml:lang
  **   XML:lang='en' => xml:lang
  **
  const Str name

  **
  ** The XML namespace which qualified this attribute's name.
  ** If the attribute name is unqualified return null.
  **
  const XNs? ns

  **
  ** If this attribute is qualified by an XML namespace then
  ** return the namespace's prefix.  Otherwise return null.
  ** Note an attribute can never be qualified by the default
  ** namespace.
  **
  Str? prefix()
  {
    return ns?.prefix
  }

  **
  ** If this element is qualified by an XML namespace then return
  ** the namespace's uri.  Otherwise return null.
  **
  Uri? uri()
  {
    return ns?.uri
  }

  **
  ** Qualified name of the attribute.  This is the full
  ** name including the XML namespace prefix:
  **   foo='val'   =>  foo
  **   x:foo='val' =>  x:foo
  **
  Str qname()
  {
    if (ns == null) return name
    return ns.prefix + ":" + name
  }

  **
  ** Value of the attribute.
  **
  const Str val

  **
  ** Return this attribute name/value pair as string.
  **
  override Str toStr()
  {
    return "$qname='$val.toXml'"
  }

  **
  ** Write this attribute to the output stream.
  **
  Void write(OutStream out)
  {
    if (ns != null) out.writeChars(ns.prefix).writeChar(':')
    out.writeXml(name)
       .writeChar('=')
       .writeChar('\'')
       .writeXml(val, OutStream.xmlEscQuotes.or(OutStream.xmlEscNewlines))
       .writeChar('\'')
  }

}
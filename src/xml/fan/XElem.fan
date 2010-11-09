//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    7 Nov 08  Brian Frank  Creation
//

**
** Models an XML element: its name, attributes, and children nodes.
**
class XElem : XNode
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct an element with unqualified local name and optional
  ** XML namespace.  The XNs instance should be defined as an
  ** attribute on this or an ancestor element (see `XAttr.makeNs`).
  **
  new make(Str name, XNs? ns := null)
  {
    this.name = name
    this.ns = ns
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the `XNodeType.elem`.  Note that during pull
  ** parsing XParser will return 'elemStart' and 'elemEnd'.
  **
  override XNodeType nodeType() { return XNodeType.elem }

  **
  ** Unqualified local name of the element.  If an XML namespace prefix
  ** was specified, then this is everything after the colon:
  **   <foo>    =>  foo
  **   <x:foo>  =>  foo
  **
  Str name

  **
  ** The XML namespace which qualified this element's name.
  ** If the element name is unqualified return null.
  **
  XNs? ns

  **
  ** If this element is qualified by an XML namespace then return
  ** the namespace's prefix.  Otherwise return null.  If the namespace
  ** is the default namespace then prefix is "".
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
  ** Qualified name of the element.  This is the full name including
  ** the XML namespace prefix:
  **   <foo>    =>  foo
  **   <x:foo>  =>  x:foo
  **
  Str qname()
  {
    if (ns == null || ns.isDefault) return name
    return ns.prefix + ":" + name
  }

  **
  ** Line number of XML element in source file or zero if unknown.
  **
  Int line

  **
  ** String representation is as a start tag.
  **
  override Str toStr()
  {
    s := StrBuf()
    s.addChar('<').add(qname)
    attrs.each |XAttr a| { s.addChar(' ').add(a) }
    s.addChar('>')
    return s.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  **
  ** Get this element's attributes as a readonly list.
  **
  XAttr[] attrs() { return attrList.ro }

  **
  ** Iterate each attribute in the `attrs` list.
  **
  Void eachAttr(|XAttr attr, Int index| f)
  {
    attrList.each(f)
  }

  **
  ** Get an attribute by its non-qualified local name.  If
  ** the attribute is not found and checked is false then
  ** return null otherwise throw XErr.
  **
  XAttr? attr(Str name, Bool checked := true)
  {
    attr := attrList.find |XAttr a->Bool| { return a.name == name }
    if (attr != null || !checked) return attr
    throw XErr("Missing attr '$name'", line)
  }

  **
  ** Get an attribute value by its non-qualified local name.
  ** If the attribute is not found and checked is false then
  ** return null otherwise throw XErr.
  **
  @Operator Str? get(Str name, Bool checked := true)
  {
    return attr(name, checked)?.val
  }

  **
  ** Add an attribute to this element.  Return this.
  ** This method is a convenience for:
  **   add(XAttr(name, val, ns))
  **
  This addAttr(Str name, Str val, XNs? ns := null)
  {
    return add(XAttr(name, val, ns))
  }

  **
  ** Remove the attribute from this element.  The attribute
  ** is matched by reference, so you must pass in the same XAttr
  ** contained by this element.  Return the removed attribute
  ** or null if no match.
  **
  XAttr? removeAttr(XAttr attr)
  {
    if (attrList.isEmpty) return null
    return attrList.removeSame(attr)
  }

  **
  ** Remove the attribute at the specified index into `attrs`.
  ** Return the removed attribute.
  **
  XAttr removeAttrAt(Int index)
  {
    return attrList.removeAt(index)
  }

  **
  ** Remove all the attributes.  Return this.
  **
  This clearAttrs()
  {
    attrList = noAttrs
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Children Nodes
//////////////////////////////////////////////////////////////////////////

  **
  ** Get this element's children elements, text, and PIs
  ** as a readonly list.
  **
  XNode[] children() { return childList.ro }

  **
  ** Iterate each child element, text, and PI node in
  ** the `children` list.
  **
  Void each(|XNode child, Int index| f)
  {
    childList.each(f)
  }

  **
  ** If child is a XAttr then add an attribute.  Otherwise it must be
  ** a XElem, XText, or XPi and is added a child node.  If the child node
  ** is already parented, then throw ArgErr.  Return this.
  **
  This add(Obj child)
  {
    if (child is XAttr)
    {
      if (attrList.isRO) attrList = XAttr[,] { capacity=4 }
      attrList.add(child)
    }
    else
    {
      node := (XNode)child
      if (node.parent != null) throw ArgErr("Node already parented: $child")
      node.parent = this
      if (childList.isRO) childList = XNode[,] { capacity=4 }
      childList.add(node)
    }
    return this
  }

  **
  ** Remove the child element, text, or PI from this element.
  ** The child is matched by reference, so you must pass in
  ** the same XNode contained by this element.  Return the
  ** removed node or null if no match.
  **
  XNode? remove(XNode child)
  {
    if (childList.isEmpty) return null
    if (childList.removeSame(child) !== child) return null
    child.parent = null
    return child
  }

  **
  ** Remove the child element, text, or PI at the specified
  ** index into `children`.  Return the removed node.
  **
  XNode removeAt(Int index)
  {
    child := childList.removeAt(index)
    child.parent = null
    return child
  }

  **
  ** Get the children elements.  If this element contains text
  ** or PI nodes, then they are excluded in the result.
  **
  XElem[] elems()
  {
    return childList.findType(XElem#)
  }

  **
  ** Find an element by its non-qualified local name.  If there
  ** are multiple child elements with the name, then the first one
  ** is returned.  If the element is not found and checked is false
  ** then return null otherwise throw XErr.
  **
  XElem? elem(Str name, Bool checked := true)
  {
    elem := childList.find |XNode n->Bool|
    {
      return n is XElem && ((XElem)n).name == name
    }
    if (elem != null || !checked) return elem
    throw XErr("Missing element '$name'", line)
  }

  **
  ** Return this element's child text node.  If this element contains
  ** multiple text nodes then return the first one.  If this element
  ** does not contain a text node return null.
  **
  XText? text()
  {
    return childList.find |XNode n->Bool| { return n is XText }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Make a shallow copy of this element.
  **
  This copy()
  {
    copy := XElem(name, ns)
    if (!attrList.isEmpty) copy.attrList = attrList.dup
    if (!childList.isEmpty) copy.childList = childList.dup
    return copy
  }

//////////////////////////////////////////////////////////////////////////
// Write
//////////////////////////////////////////////////////////////////////////

  **
  ** Write this node to the output stream.
  **
  override Void write(OutStream out) { doWrite(out, 0) }

  internal Void doWrite(OutStream out, Int indent)
  {
    // start element tag
    out.writeChar('<')
    if (ns != null && !ns.isDefault) out.writeChars(ns.prefix).writeChar(':')
    out.writeChars(name)
    attrList.each |XAttr attr| { out.writeChar(' '); attr.write(out) }

    // if empty element, then close element
    if (childList.isEmpty) { out.writeChar('/').writeChar('>'); return }

    // close start tag
    out.writeChar('>')

    // children elements
    indent++
    needIndent := childList.first isnot XText
    childList.each |XNode node|
    {
      isText := node is XText
      if (needIndent && !isText) { out.writeChar('\n').writeChars(Str.spaces(indent)) }
      needIndent = !isText
      if (node is XElem)
        ((XElem)node).doWrite(out, indent)
      else
        node.write(out)
    }
    indent--

    // closing element tag
    if (needIndent) out.writeChar('\n').writeChars(Str.spaces(indent))
    out.writeChar('<').writeChar('/')
    if (ns != null && !ns.isDefault) out.writeChars(ns.prefix).writeChar(':')
    out.writeChars(name).writeChar('>')
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // Immutable empty lists
  internal const static XElem[] noElems := XElem[,]
  internal const static XNode[] noNodes := XNode[,]
  internal const static XAttr[] noAttrs := XAttr[,]

  internal XAttr[] attrList  := noAttrs
  internal XNode[] childList := noNodes
}
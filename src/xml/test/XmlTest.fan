//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    11 Nov 08  Brian Frank  Creation
//

**
** XmlTest is base class for XML tests
**
abstract class XmlTest : Test
{

  **
  ** Verify two nodes are equal
  **
  Void verifyNode(XNode a, XNode b)
  {
    verifyEq(a.nodeType, b.nodeType)
    switch (Type.of(a))
    {
      case XDoc#:  verifyDoc(a, b)
      case XElem#: verifyElem(a, b)
      case XText#: verifyText(a, b)
      case XPi#:   verifyPi(a, b)
    }
  }

  **
  ** Verify two documents are equal
  **
  Void verifyDoc(XDoc a, XDoc b)
  {
    verifyEq(a.docType?.toStr, b.docType?.toStr)
    verifyPis(a.pis, b.pis)
    verifyElem(a.root, b.root)
  }

  **
  ** Verify two elements are equal
  **
  Void verifyElem(XElem? a, XElem? b)
  {
    if (a == null) { verify(b == null); return; }

    // naming
    verifyEq(a.prefix, b.prefix)
    verifyEq(a.name,   b.name)
    verifyEq(a.qname,  b.qname)
    verifyEq(a.ns,     b.ns)

    // attributes
    verifyEq(a.attrs.size, b.attrs.size)
    a.attrs.each |XAttr aa, Int i|
    {
      ba := b.attrs[i]
      verifyAttr(aa, ba)
    }

    // content
    verifyEq(a.children.size, b.children.size)
    a.children.each |XNode an, Int i|
    {
      bn := b.children[i]
      verifyNode(an, bn)
    }
  }

  **
  ** Verify two attributes are equal
  **
  Void verifyAttr(XAttr a, XAttr b)
  {
    verifyEq(a.name,  b.name)
    verifyEq(a.qname, b.qname)
    verifyEq(a.val,   b.val)
  }

  **
  ** Verify two text nodes are equal
  **
  Void verifyText(XText a, XText b)
  {
    verifyEq(a.val, b.val)
    verifyEq(a.cdata, b.cdata)
  }

  **
  ** Verify two processing instructions are equal
  **
  Void verifyPi(XPi a, XPi b)
  {
    verifyEq(a.target, b.target)
    verifyEq(a.val, b.val)
  }

  **
  ** Verify lists of two processing instructions are equal
  **
  Void verifyPis(XPi[] a, XPi[] b)
  {
    verifyEq(a.size, b.size)
    a.each |XPi ax, Int i| { verifyPi(ax, b[i]) }
  }


}
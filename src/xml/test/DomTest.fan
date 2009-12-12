//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    7 Nov 08  Brian Frank  Creation
//

**
** DomTest tests the tree model data structures
**
class DomTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  Void testAttrs()
  {
    x := XElem("foo")
    a := XAttr("a", "aval")
    b := XAttr("b", "bval")
    c := XAttr("c", "cval")

    verifyEq(x.attrs, XAttr[,])
    verifyEq(x.attrs.isRO, true)
    verifyEq(x.attr("a", false), null)
    verifyEq(x.get("a", false), null)
    verifyErr(XErr#) { x.attr("a") }
    verifyErr(XErr#) { x.attr("a", true) }
    verifyErr(XErr#) { x.get("a") }
    verifyErr(XErr#) { x.get("a", true) }

    verifySame(x.add(a), x)
    verifyEq(x.attrs, [a])
    verifyEq(x.attrs.isRO, true)
    verifySame(x.attr("a"), a)
    verifySame(x.attr("a", false), a)
    verifySame(x.attr("a", true), a)
    verifySame(x.get("a"), "aval")
    verifySame(x.get("a", false), "aval")
    verifySame(x.get("a", true), "aval")

    x.add(b).add(c)
    verifyEq(x.attrs, [a, b, c])
    verifyEq(x.attrs.isRO, true)
    verifySame(x.attr("a"), a)
    verifySame(x.attr("b"), b)
    verifySame(x.attr("c"), c)
    verifySame(x["a"], "aval")
    verifySame(x["b"], "bval")
    verifySame(x["c"], "cval")
    verifyEq(x.get("aa", false), null)
    verifyErr(XErr#) { x.attr("aa") }

    acc := XAttr[,]
    x.eachAttr |XAttr q| { acc.add(q) }
    verifyEq(acc, [a, b, c])

    verifySame(x.removeAttrAt(1), b)
    verifyEq(x.attrs, [a, c])
    verifySame(x.removeAttrAt(-1), c)
    verifyEq(x.attrs, [a])
    verifySame(x.removeAttr(a), a)
    verifyEq(x.attrs, XAttr[,])
    verifyEq(x.attrs.isRO, true)
    verifyEq(x.removeAttr(a), null)
    verifySame(x.add(b), x)
    verifyEq(x.attrs, [b])
    verifySame(x.get("a", false), null)
    verifySame(x.get("b", false), "bval")
    verifySame(x.get("c", false), null)
  }

//////////////////////////////////////////////////////////////////////////
// Children
//////////////////////////////////////////////////////////////////////////

  Void testChildren()
  {
    x  := XElem("x")
    a  := XElem("a")
    b  := XElem("b").add(XText("btext"))
    t  := XText("text")
    pi := XPi("pi", "pival")

    verifyEq(x.children, XNode[,])
    verifyEq(x.children.isRO, true)
    verifyEq(x.elems, XElem[,])
    verifyEq(x.elem("foo", false), null)
    verifyErr(XErr#) { x.elem("foo") }
    verifyErr(XErr#) { x.elem("foo", true) }
    verifyEq(x.text, null)

    x.add(pi)
    verifySame(pi.parent, x)
    verifyEq(x.children, XNode[pi])
    verifyEq(x.children.isRO, true)
    verifyEq(x.elems, XElem[,])
    verifyEq(x.text, null)

    x.add(a)
    verifySame(a.parent, x)
    verifyEq(x.children, XNode[pi, a])
    verifyEq(x.children.isRO, true)
    verifyEq(x.elems, [a])
    verifySame(x.elem("a", false), a)
    verifySame(x.elem("a", true), a)
    verifyEq(x.text, null)

    x.add(t)
    verifySame(t.parent, x)
    verifyEq(x.children, XNode[pi, a, t])
    verifyEq(x.elems, [a])
    verifySame(x.elem("a"), a)
    verifySame(x.text, t)

    x.add(b)
    verifySame(b.parent, x)
    verifyEq(x.children, XNode[pi, a, t, b])
    verifyEq(x.elems, [a, b])
    verifySame(x.elem("a"), a)
    verifySame(x.elem("b"), b)
    verifyEq(x.elem("foo", false), null)
    verifyErr(XErr#) { x.elem("foo") }
    verifyErr(XErr#) { x.elem("foo", true) }
    verifySame(x.text, t)

    // each
    acc := XNode[,]
    x.each |XNode n| { acc.add(n) }
    verifyEq(acc, [pi, a, t, b])

    // removeAt
    verifyErr(ArgErr#) { x.add(t) }
    verifySame(x.removeAt(-2), t)
    verifyEq(t.parent, null)

    // re-add
    x.add(t)
    verifyEq(x.children, XNode[pi, a, b, t])

    // remove
    verifySame(x.remove(t), t)
    verifySame(x.remove(pi), pi)
    verifySame(x.remove(pi), null)
    verifySame(x.remove(a), a)
    verifyEq(t.parent, null)
    verifyEq(a.parent, null)
    verifyEq(pi.parent, null)
    verifyEq(x.children, XNode[b])
    verifyEq(x.children.isRO, true)
    verifyEq(x.elems, [b])
  }

//////////////////////////////////////////////////////////////////////////
// Doc
//////////////////////////////////////////////////////////////////////////

  Void testDoc()
  {
    doc := XDoc()
    verifySame(doc.doc, doc)
    verifySame(doc.root.doc, doc)
    verifyEq(doc.root.name, "undefined")
    verifySame(doc.root.parent, doc)

    doc.root = XElem("root")
    {
      XElem("a")
      {
        XElem("b") { XText("text"), },
      },
      XElem("c"),
    }
    verifySame(doc.doc, doc)
    verifySame(doc.root.doc, doc)
    verifySame(doc.root.parent, doc)
    verifySame(doc.root.elem("a").doc, doc)
    verifySame(doc.root.elem("a").elem("b").doc, doc)
    verifySame(doc.root.elem("a").elem("b").text.doc, doc)
    verifyEq(XElem("x").doc, null)
    verifyErr(ArgErr#) { doc.root = doc.root.elem("a") }

    doc.add(XElem("newRoot"))
    verifyEq(doc.root.name, "newRoot")
    verifySame(doc.root.parent, doc)
    verifySame(doc.root.doc, doc)

    piA := XPi("a", "aval")
    piB := XPi("b", "bval")
    verifyEq(doc.pis, XPi[,])
    verifyEq(doc.pis.isRO, true)
    verifyEq(doc.removePi(piA), null)
    doc.add(piA)
    verifyEq(doc.pis, [piA])
    verifyEq(doc.pis.isRO, true)
    doc.add(piB)
    verifyEq(doc.pis, [piA, piB])
    verifyEq(doc.pis.isRO, true)
    verifySame(doc.removePi(piA), piA)
    verifyEq(doc.pis, [piB])
    verifyEq(doc.pis.isRO, true)
  }

//////////////////////////////////////////////////////////////////////////
// Namespaces
//////////////////////////////////////////////////////////////////////////

  Void testNsIdentity()
  {
    nsdef := XNs("", `http://foo/default`)
    nsq   := XNs("q", `http://foo/q`)

    verifyEq(nsdef.isDefault, true)
    verifyEq(nsq.isDefault, false)
    verifyEq(nsdef.prefix, "")
    verifyEq(nsq.prefix, "q")
    verifyEq(nsdef.uri, `http://foo/default`)
    verifyEq(nsdef, XNs("", `http://foo/default`))
    verifyEq(nsdef, XNs("foo", `http://foo/default`))
    verifyNotEq(nsdef, XNs("", `http://foo/diff/`))
  }

  Void testNsElem()
  {
    nsdef := XNs("", `http://foo/default`)
    nsq   := XNs("q", `http://foo/q`)

    u := XElem("u")
    verifyEq(u.name, "u")
    verifyEq(u.qname, "u")
    verifyEq(u.prefix, null)
    verifyEq(u.uri, null)
    verifyEq(u.ns, null)

    x := XElem("root", nsdef)
    verifyEq(x.name, "root")
    verifyEq(x.qname, "root")
    verifyEq(x.prefix, "")
    verifyEq(x.uri, `http://foo/default`)
    verifySame(x.ns, nsdef)

    a := XElem("a", nsq)
    verifyEq(a.name, "a")
    verifyEq(a.qname, "q:a")
    verifyEq(a.prefix, "q")
    verifyEq(a.uri, `http://foo/q`)
    verifySame(a.ns, nsq)
  }

  Void testNsAttr()
  {
    nsdef := XNs("", `http://foo/default`)
    nsq   := XNs("q", `http://foo/q`)

    u := XAttr("u", "uval")
    verifyEq(u.name, "u")
    verifyEq(u.qname, "u")
    verifyEq(u.prefix, null)
    verifyEq(u.uri, null)
    verifyEq(u.ns, null)

    a := XAttr("a", "aval", nsq)
    verifyEq(a.name, "a")
    verifyEq(a.qname, "q:a")
    verifyEq(a.prefix, "q")
    verifyEq(a.uri, `http://foo/q`)
    verifySame(a.ns, nsq)

    // don't allow since no prefix means no ns, not default ns
    verifyErr(ArgErr#) { x := XAttr("def", "defval", nsdef) }
  }

}
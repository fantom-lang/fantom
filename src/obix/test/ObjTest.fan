//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jan 09  Brian Frank  Creation
//

**
** ObjTest - child/parent test tree structure
**
class ObjTest : ObixTest
{

//////////////////////////////////////////////////////////////////////////
// Children
//////////////////////////////////////////////////////////////////////////

  Void testChildren()
  {
    // empty
    p := ObixObj()
    verifyChildren(p, ObixObj[,])

    // add a (unnamed)
    a := ObixObj()
    verifySame(p.add(a), p)
    verifyChildren(p, [a])

    // add b (named), c (unnamed), d (named)
    b := ObixObj { name = "b" }
    c := ObixObj {}
    d := ObixObj { name = "d" }
    p.add(b).add(c).add(d)
    verifyChildren(p, [a, b, c, d])

    // remove b
    verifySame(p.remove(b), p)
    verifyChildren(p, [a, c, d])
    verifyEq(b.parent, null)
    verifyEq(p["b"], null)

    // remove a
    verifySame(p.remove(a), p)
    verifyChildren(p, [c, d])
    verifyEq(p["d"], d)

    // clear
    verifySame(p.clear, p)
    verifyChildren(p, ObixObj[,])
    verifyEq(c.parent, null)
    verifyEq(d.parent, null)

    // verify we can read them
    p.add(d).add(c).add(b).add(a)
    verifyChildren(p, [d, c, b, a])

    // verify errors
    verifyErr(ArgErr#) |,| { p.add(b) }
    verifyErr(ArgErr#) |,| { p.add(ObixObj { name = "b"}) }
    verifyErr(ArgErr#) |,| { p.remove(ObixObj { name = "b"}) }
    verifyErr(UnsupportedErr#) |,| { b.name = "boo" }
  }

//////////////////////////////////////////////////////////////////////////
// Href
//////////////////////////////////////////////////////////////////////////

  Void testHref()
  {
    root := ObixObj { href = `http://foo/obix/` }
    a := ObixObj() { href = `a/` }; root.add(a)
    b := ObixObj() { }; a.add(b)
    c := ObixObj() { href = `b/c` }; b.add(c)

    // root
    verifySame(root.root, root)
    verifySame(a.root, root)
    verifySame(b.root, root)
    verifySame(c.root, root)

    // href
    verifySame(root.href, `http://foo/obix/`)
    verifySame(a.href, `a/`)
    verifySame(b.href, null)
    verifySame(c.href, `b/c`)

    // normalizedHref
    verifyEq(root.normalizedHref, `http://foo/obix/`)
    verifyEq(a.normalizedHref, `http://foo/obix/a/`)
    verifyEq(b.normalizedHref, null)
    verifyEq(c.normalizedHref, `http://foo/obix/b/c`)
  }

//////////////////////////////////////////////////////////////////////////
// Val
//////////////////////////////////////////////////////////////////////////

  Void testVal()
  {
    verifyVal("obj", null)
    verifyVal("bool", true)
    verifyVal("int", 72)
    verifyVal("real", 75f)
    verifyVal("str", "hi")
    verifyVal("uri", `http://host/`)
    verifyVal("abstime", DateTime.now)
    verifyVal("reltime", Duration.now)
    verifyVal("date", Date.today)
    verifyVal("time", Time.now)

    verifyErr(ArgErr#) |,| { ObixObj { val = this } }
    verifyErr(ArgErr#) |,| { ObixObj { val = Locale.current } }
  }

  Void verifyVal(Str elemName, Obj? val)
  {
    obj := ObixObj { val = val }
    verifyEq(obj.elemName, elemName)
    verifySame(obj.val, val)
  }
}
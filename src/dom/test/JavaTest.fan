//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 2017  Andy Frank  Creation
//

class JavaTest : Test
{
  Void testElemBasics()
  {
    elem := Elem {}
    verifyEq(elem.tagName, "div")
    verifyEq(elem.id,   "")
    verifyEq(elem->id,  "")
    verifyEq(elem.text, "")

    elem.id = "foo"
    elem.text = "yabba dabba"
    verifyEq(elem.id,   "foo")
    verifyEq(elem.text, "yabba dabba")

    a := Elem {}
    b := Elem {}
    c := Elem {}
    d := Elem {}
    e := Elem {}

    verifyEq(a.parent, null)
    verifyEq(elem.hasChildren, false)
    elem.add(a)
    verifyEq(elem.hasChildren, true)
    verifyEq(elem.children.size, 1)
    verifyEq(a.parent, elem)
    elem.add(b); verifyEq(elem.children.size, 2)
    elem.add(c); verifyEq(elem.children.size, 3)

    verifyEq(elem.firstChild, a)
    verifyEq(elem.lastChild,  c)
    verifyEq(elem.containsChild(b), true)
    verifyEq(a.prevSibling, null)
    verifyEq(b.prevSibling, a)
    verifyEq(b.nextSibling, c)
    verifyEq(c.nextSibling, null)

    elem.insertBefore(d, c)
    verifyEq(elem.children[2], d)

    elem.replace(d, e)
    verifyEq(elem.children[2], e)
    verifyEq(d.parent, null)
    verifyEq(elem.children.contains(d), false)

    elem.remove(a)
    verifyEq(a.parent, null)
    verifyEq(elem.children.contains(a), false)
  }

  Void testAttrs()
  {
    elem := Elem {}

    verifyEq(elem.attrs.size, 0)
    verifyEq(elem->foo, null)
    elem->foo = "bar"
    verifyEq(elem->foo, "bar")

    elem->bar = false
    elem.set("zoo", 12)
    verifyEq(elem->bar, false)
    verifyEq(elem->zoo, 12)

    attrs := elem.attrs
    verifyEq(attrs.size, 3)
    verifyEq(attrs["foo"], "bar")
    verifyEq(attrs["bar"], "false")
    verifyEq(attrs["zoo"], "12")

    elem->fooBar = "ok"
    verifyEq(elem->fooBar, "ok")
    verifyEq(elem["foo-bar"], "ok")
    verifyEq(elem.get("foo-bar"), "ok")

    elem.set("foo-bar", "ko")
    verifyEq(elem->fooBar, "ko")
    verifyEq(elem["foo-bar"], "ko")

    elem->fooBar = "xx"
    verifyEq(elem->fooBar, "xx")
    verifyEq(elem["foo-bar"], "xx")

    elem->_foo_bazPaw = "5"
    verifyEq(elem->_foo_bazPaw, "5")
    verifyEq(elem["_foo_baz-paw"], "5")
  }

  Void testStyleBasics()
  {
    elem := Elem {}
    s := elem.style
    verifyEq(s.classes.size, 0)

    s.addClass("foo")
    verifyEq(s.classes.size, 1)
    verifyEq(s.hasClass("foo"), true)
    verifyEq(s.hasClass("bar"), false)

    s.addClass("bar cool")
    verifyEq(s.classes.size, 3)
    verifyEq(s.hasClass("foo"),  true)
    verifyEq(s.hasClass("bar"),  true)
    verifyEq(s.hasClass("cool"), true)

    s.removeClass("bar")
    verifyEq(s.classes.size, 2)
    verifyEq(s.hasClass("foo"),  true)
    verifyEq(s.hasClass("bar"),  false)
    verifyEq(s.hasClass("cool"), true)

    s.removeClass("nada")
    verifyEq(s.classes.size, 2)

    verifyEq(s->background, null)
    s->background = "#eee"
    verifyEq(s->background, "#eee")
  }
}
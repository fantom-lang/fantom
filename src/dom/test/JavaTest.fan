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
    verifyEq(elem.ns, `http://www.w3.org/1999/xhtml`)
    verifyEq(elem.tagName, "div")
    verifyAttrProp(elem, "id", null, "")  // to match js behavoir
    verifyAttrProp(elem, "name", null)
    verifyEq(elem.text,  "")

    elem.id = "foo"
    elem.text = "yabba dabba"
    verifyAttrProp(elem, "id", "foo")
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

    // java setAttr will always also set the prop
    verifyEq(elem.attrs.size, 0)
    verifyAttrProp(elem, "foo", null)
    elem["foo"] = "bar"
    verifyAttrProp(elem, "foo", "bar")

    // java setProp will always also set the attr
    elem->bar = false
    elem->zoo = 12
    verifyAttrProp(elem, "bar", "false", false)
    verifyAttrProp(elem, "zoo", "12", 12)

    attrs := elem.attrs
    verifyEq(attrs.size, 3)
    verifyAttrProp(elem, "foo", "bar")
    verifyAttrProp(elem, "bar", "false", false)
    verifyAttrProp(elem, "zoo", "12", 12)

    // TODO: how do we handle camel case????
    // elem->fooBar = "ok"
    // verifyEq(elem->fooBar, "ok")
    // verifyEq(elem["foo-bar"], "ok")
    // verifyEq(elem.get("foo-bar"), "ok")
    //
    // elem.set("foo-bar", "ko")
    // verifyEq(elem->fooBar, "ko")
    // verifyEq(elem["foo-bar"], "ko")
    //
    // elem->fooBar = "xx"
    // verifyEq(elem->fooBar, "xx")
    // verifyEq(elem["foo-bar"], "xx")
    //
    // elem->_foo_bazPaw = "5"
    // verifyEq(elem->_foo_bazPaw, "5")
    // verifyEq(elem["_foo_baz-paw"], "5")
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

  Void testSvg()
  {
    a := Svg.line(0, 0, 10, 10)
    verifyEq(a.ns, `http://www.w3.org/2000/svg`)
    verifyEq(a.tagName, "line")

    // svg prop routes to attr
    verifyEq(a->x1, "0")
    verifyEq(a->y1, "0")
    verifyEq(a->x2, "10")
    verifyEq(a->y2, "10")

    // svg setProp routes to setAttr
    a->x1 = 5
    a->y1 = 5
    verifyEq(a->x1, "5")
    verifyEq(a->y1, "5")
  }

  private Void verifyAttrProp(Elem elem, Str name, Str? attrVal, Obj? propVal := null)
  {
    verifyAttr(elem, name, attrVal)
    verifyProp(elem, name, propVal ?: attrVal)
  }

  private Void verifyAttr(Elem elem, Str name, Str? val)
  {
    // echo("# $elem a[$name]: " + elem.attr(name) + "/" + elem.get(name))
    verifyEq(elem.attr(name), val)
    verifyEq(elem.get(name),  val)
    verifyEq(elem[name],      val)
  }

  private Void verifyProp(Elem elem, Str name, Obj? val)
  {
    // echo("# $elem p[$name]: " + elem.prop(name) + "/" + elem.trap(name))
    verifyEq(elem.prop(name), val)
    verifyEq(elem.trap(name), val)
  }
}
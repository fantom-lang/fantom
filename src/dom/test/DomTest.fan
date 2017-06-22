//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 09  Andy Frank  Creation
//

using graphics
using web

**************************************************************************
** DomTest
**************************************************************************

@NoDoc class DomTest : Weblet
{
  override Void onGet()
  {
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.docType
    out.html
    out.head
      .title.w("Dom Test").titleEnd
      .includeJs(`/pod/sys/sys.js`)
      .includeJs(`/pod/concurrent/concurrent.js`)
      .includeJs(`/pod/graphics/graphics.js`)
      .includeJs(`/pod/web/web.js`)
      .includeJs(`/pod/dom/dom.js`)
      .style.w(
       ".hidden { display: none; }")
      .styleEnd
      .script.w(
       "function print(name)
        {
          var p = document.getElementById('tests');
          p.innerHTML = p.innerHTML + ' -- ' + name + '...<'+'br/>';
         }
         window.onload = function() {
          var results = document.getElementById('results');
          try
          {
            var test = fan.dom.DomTestClient.make();
            print('testEmpty');     test.testEmpty();
            print('testBasics');    test.testBasics();
            print('testAttrs');     test.testAttrs();
            print('testCreate');    test.testCreate();
            print('testAddRemove'); test.testAddRemove();
            print('testStyle');     test.testStyle();
            print('testSvg');       test.testSvg();
            results.style.color = 'green';
            results.innerHTML = 'All tests passed! [' + test.m_verifies + ' verifies]';
          }
          catch (err)
          {
            results.style.color = 'red';
            results.innerHTML = 'Test failed - ' + err;
          }
        }")
       .scriptEnd
       .headEnd

    out.body
      .h1.w("Dom Test").h1End
      .hr

    // testEmpty (use raw html so no whitespace nodes)
    out.w("<div></div>").nl

    // testBasics
    out.div("id='testBasics' class='hidden'")
      .p.w("alpha").pEnd
      .span.w("beta-1").spanEnd
      .span.w("beta-2").spanEnd
      .a(`#`).w("gamma").aEnd
      .divEnd

    // testAttrs
    out.div("id='testAttrs' class='hidden'")
      .input("type='text' name='alpha' value='foo'")
      .checkbox("name='beta' checked='checked'")
      .checkbox
      .div("class='a'").divEnd
      .div("class='a b'").divEnd
      .div.divEnd
      .divEnd

    // testAttrs
    out.div("id='testStyle' class='hidden'")
      .div("class='a'").divEnd
      .div("class='a b'").divEnd
      .div.divEnd
      .divEnd

    out.p.w("Running...").pEnd
     .p("id='tests'").pEnd
     .p("id='results'").pEnd

    out.bodyEnd.htmlEnd
  }
}

**************************************************************************
** DomTestClient
**************************************************************************

@Js @NoDoc internal class DomTestClient
{

//////////////////////////////////////////////////////////////////////////
// testEmpty
//////////////////////////////////////////////////////////////////////////

  Void testEmpty()
  {
    elem := Win.cur.doc.body.querySelector("div")  // testEmpty must be first div
    verifyEq(elem.ns,  `http://www.w3.org/1999/xhtml`)
    verifyEq(elem.id,  null)
    verifyEq(elem->id, "")
    verifyEq(elem.attrs.size, 0)
    verifyEq(elem.hasChildren, false)
    verifyEq(elem.text,   "")
    verifyEq(elem.size.h, 0f)  // w will vary...
  }

//////////////////////////////////////////////////////////////////////////
// testBasics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    elem := Win.cur.doc.elemById("testBasics")
    verify(elem != null)
    verifyEq(elem.size, Size(0,0))

    kids := elem.children
    verifyEq(kids.size, 4)
    verifyEq(kids[0].html.trim, "alpha")
    verifyEq(kids[1].html, "beta-1")
    verifyEq(kids[2].html, "beta-2")
    verifyEq(kids[3].html, "gamma")

    a := Win.cur.doc.querySelector("#testBasics :last-child")
    verify(a != null)
    verifyEq(a.tagName, "a")
    verifyEq(a.parent.id, "testBasics")

    spans := Win.cur.doc.querySelectorAll("#testBasics span")
    verifyEq(spans.size, 2)
    verifyEq(spans[0].tagName, "span")
    verifyEq(spans[1].tagName, "span")
  }

//////////////////////////////////////////////////////////////////////////
// testAttrs
//////////////////////////////////////////////////////////////////////////

  Void testAttrs()
  {
    top := Win.cur.doc.elemById("testAttrs")
    verify(top != null)

    // top <div>
    verifyEq(top.tagName, "div")
    verifyAttrProp(top, "id",    "testAttrs")
    verifyAttrProp(top, "name",  null)
    verifyAttrProp(top, "yabba", null)
    verifyEq(top->offsetTop, 0)
    verify(top->innerHTML.toStr.contains("<input type="))

    a := top.children[0]  // <input>
    b := top.children[1]  // <checkbox>
    c := top.children[2]  // <checkbox>
    d := top.children[3]  // <div>
    e := top.children[4]  // <div>
    f := top.children[5]  // <div>

    // a:<input>
    try
    {
      verifyEq(a.tagName, "input")
      verifyAttrProp(a, "id",       null, "")   // null for attr, "" for prop
      verifyAttrProp(a, "type",     "text")
      verifyAttrProp(a, "name",     "alpha")
      verifyAttrProp(a, "tabIndex", null, 0)    // <input> tab defaults to 0
      a->tabIndex = 1
      verifyAttrProp(a, "tabIndex", "1", 1)     // set prop updates both attr/prop
      verifyAttrProp(a, "value", "foo")
      a->value = "bar"                          // setting prop does not modify attr
      verifyAttrProp(a, "value", "foo", "bar")  //   orig="foo", modified="bar"
      verifyEq(a["value"], "foo")               //   orig
      verifyEq(a->defaultValue, "foo")          //   orig
    }
    finally { a->value = "foo" }  // make firefox re-entrant...

    // b:<checkbox>
    try
    {
      verifyEq(b.tagName, "input")
      verifyAttrProp(b, "type",  "checkbox")
      verifyAttrProp(b, "name",  "beta")
      verifyAttrProp(b, "value", null, "on")          // value attr not defined
      verifyAttrProp(b, "checked", "checked", true)   // bool attrs mirror name
      b->checked = false                              // setting prop does not modify attr
      verifyAttrProp(b, "checked", "checked", false)  //   orig=true, modified=false
      verifyEq(b["checked"], "checked")               //   orig
      verifyEq(b->defaultChecked, true)               //   orig
      b["checked"] = "checked"                        // setting attr does not modify prop
      verifyAttrProp(b, "checked", "checked", false)  //   same prop
    }
    finally { b->checked = true }  // make firefox re-entrant...

    // c:<checkbox>
    verifyEq(c.tagName, "input")
    verifyAttrProp(c, "type",  "checkbox")
    verifyAttrProp(c, "name",  null, "")       // name attr null; prop is "" for <inputs>
    verifyAttrProp(c, "value", null, "on")     // value prop appears meaningless across browsers for <checkbox>?
    verifyAttrProp(c, "checked", null, false)  // bool attrs mirror name

    // d:<div>
    verifyEq(d.tagName, "div")
    verifyAttrProp(d, "tabIndex", null, -1)    // non-inputs default to null/-1
    d->tabIndex = 0
    verifyAttrProp(d, "tabIndex", "0", 0)      // set prop updates both attr/prop

    // e:<div>
    verifyEq(e.tagName, "div")
    verifyAttr(e, "x", null)
    e["x"] = "123";    verifyAttr(e, "x", "123")
    e.removeAttr("x"); verifyAttr(e, "x", null)
    e["x"] = "abc";    verifyAttr(e, "x", "abc")
    e["x"] = null;     verifyAttr(e, "x", null)

    // f:<div>
    verifyEq(f.tagName, "div")
  }

//////////////////////////////////////////////////////////////////////////
// testCreate
//////////////////////////////////////////////////////////////////////////

  Void testCreate()
  {
    elem := Elem {}
    verifyEq(elem.ns, `http://www.w3.org/1999/xhtml`)
    verifyEq(elem.tagName, "div")

    elem = Elem("table") {}
    verifyEq(elem.tagName, "table")

    elem = Win.cur.doc.createElem("div")
    verifyEq(elem.ns, `http://www.w3.org/1999/xhtml`)
    verifyEq(elem.tagName, "div")

    elem = Win.cur.doc.createElem("div", ["class":"foo"])
    verifyEq(elem.tagName, "div")
    verifyEq(elem.style.classes, ["foo"])

    elem = Win.cur.doc.createElem("div", ["id":"cool", "name":"yay", "class":"foo"])
    verifyEq(elem.tagName, "div")
    verifyEq(elem["id"], "cool")
    verifyEq(elem["name"], "yay")
    verifyEq(elem["class"], "foo")

    // TODO: create with namespace
    // TODO: some SVG tests
  }

//////////////////////////////////////////////////////////////////////////
// testAddRemove
//////////////////////////////////////////////////////////////////////////

  Void testAddRemove()
  {
    elem := Elem {}
    verifyEq(elem.children.size, 0)
    verifyEq(elem.hasChildren, false)

    a := Elem { it.style.addClass("a") }
    b := Elem { it.style.addClass("b") }
    c := Elem { it.style.addClass("c") }

    elem.add(a)
    verifyEq(elem.children.size, 1)
    verifyEq(elem.children.first.style.classes, ["a"])

    elem.add(b)
    elem.add(c)
    verifyEq(elem.children.size, 3)
    verifyEq(elem.children[1].style.classes, ["b"])
    verifyEq(elem.children[2].style.classes, ["c"])

    elem.remove(b)
    verifyEq(elem.children.size, 2)
    verifyEq(elem.children[0].style.classes, ["a"])
    verifyEq(elem.children[1].style.classes, ["c"])

    elem.remove(c)
    verifyEq(elem.children.size, 1)
    verifyEq(elem.children[0].style.classes, ["a"])

    elem.remove(elem.children.first)
    verifyEq(elem.children.size, 0)

    elem.addAll([b,c])
    verifyEq(elem.children.size, 2)
    verifyEq(elem.hasChildren, true)
    elem.insertBefore(a, b)
    verifyEq(elem.children.size, 3)
    verifyEq(elem.children[0].style.classes, ["a"])
    verifyEq(elem.children[1].style.classes, ["b"])
    verifyEq(elem.children[2].style.classes, ["c"])

    elem.removeAll
    verifyEq(elem.children.size, 0)
    verifyEq(elem.hasChildren, false)
  }

//////////////////////////////////////////////////////////////////////////
// testStyle
//////////////////////////////////////////////////////////////////////////

  Void testStyle()
  {
    top := Win.cur.doc.elemById("testStyle")

    // class tests
    a := top.children[0]
    b := top.children[1]
    c := top.children[2]

    verifyEq(a.style.hasClass("a"), true)
    verifyEq(a.style.hasClass("b"), false)
    verifyEq(a.style.hasClass("c"), false)
    verifyEq(b.style.hasClass("a"), true)
    verifyEq(b.style.hasClass("b"), true)
    verifyEq(b.style.hasClass("c"), false)
    verifyEq(c.style.hasClass("a"), false)
    a.style.addClass("c")
    b.style.addClass("c")
    c.style.addClass("c")
    verifyEq(a.style.hasClass("c"), true)
    verifyEq(b.style.hasClass("c"), true)
    verifyEq(c.style.hasClass("c"), true)
    a.style.removeClass("a")
    b.style.removeClass("a")
    verifyEq(a.style.hasClass("a"), false)
    verifyEq(b.style.hasClass("a"), false)
    c.style.removeClass("c")
    verifyEq(c.style.hasClass("c"), false)
    verifyEq(b.style.classes, ["b", "c"])
    b.style.addClass("b")
    verifyEq(b.style.classes, ["b", "c"])
    b.style.removeClass("x")
    verifyEq(b.style.classes, ["b", "c"])

    // legacy test -- keep supporting this
    a.style.addClass("x y z")
    verifyEq(a.style.hasClass("x"), true)
    verifyEq(a.style.hasClass("y"), true)
    verifyEq(a.style.hasClass("z"), true)
    a.style.removeClass("y z")
    verifyEq(a.style.hasClass("x"), true)
    verifyEq(a.style.hasClass("y"), false)
    verifyEq(a.style.hasClass("z"), false)

    // style tests
    x := Elem {}
    x.style["padding"] =  "10px"; verifyEq(x.style["padding"], "10px")
    x.style->padding = "20px";    verifyEq(x.style->padding, "20px")

    x.style["background-color"] = "#f00"; verifyEq(x.style["background-color"], "rgb(255, 0, 0)")
    x.style->backgroundColor = "#0f0";    verifyEq(x.style->backgroundColor, "rgb(0, 255, 0)")

    x.style["border-bottom-color"] = "#00f"
    verifyEq(x.style->borderBottomColor, "rgb(0, 0, 255)")

    x.style.setAll([
      "padding": "3px",
      "margin":  "6px",
      "border":  "2px dotted #ff0"
    ])
    verifyEq(x.style->padding, "3px")
    verifyEq(x.style->margin,  "6px")
    verifyEq(x.style->border,  "2px dotted rgb(255, 255, 0)")

    x.style.setCss("padding: 5px; margin: 10px; border: 1px solid #0f0")
    verifyEq(x.style->padding, "5px")
    verifyEq(x.style->margin,  "10px")
    verifyEq(x.style->border,  "1px solid rgb(0, 255, 0)")
  }

//////////////////////////////////////////////////////////////////////////
// testSvg
//////////////////////////////////////////////////////////////////////////

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

    // svg classNames
    verifyEq(a.style.classes, Str#.emptyList)
    a.style.addClass("a b c")
    verifyEq(a.style.classes, ["a", "b", "c"])
    verifyEq(a.style.hasClass("a"), true)
    verifyEq(a.style.hasClass("b"), true)
    verifyEq(a.style.hasClass("c"), true)
    a.style.removeClass("b c")
    verifyEq(a.style.classes, ["a"])
    verifyEq(a.style.hasClass("a"), true)
    verifyEq(a.style.hasClass("b"), false)
    verifyEq(a.style.hasClass("c"), false)
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private Void verify(Bool v)
  {
    if (v) verifies++
    else throw Err("Test failed")
  }

  private Void verifyEq(Obj? a, Obj? b)
  {
    if (a == b) verifies++
    else throw Err("$a != $b")
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

  private Int verifies := 0
}


//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 09  Andy Frank  Creation
//

using web

@NoDoc
class DomTest : Weblet
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
      .includeJs(`/pod/gfx/gfx.js`)
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
            print('testAttrs');     test.testAttrs();
            print('testBasics');    test.testBasics();
            print('testCreate');    test.testCreate();
            print('testAddRemove'); test.testAddRemove();
            print('testStyle');     test.testStyle();
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

    // testAttrs
    out.div("id='testAttrs' class='hidden'")
      .input("type='text' name='alpha' value='foo'")
      .checkbox("name='beta' checked='checked'")
      .checkbox
      .div("class='a'").divEnd
      .div("class='a b'").divEnd
      .div.divEnd
      .divEnd

    // testBasics
    out.div("id='testBasics' class='hidden'")
      .p.w("alpha").pEnd
      .span.w("beta").spanEnd
      .a(`#`).w("gamma").aEnd
      .divEnd

    out.p.w("Running...").pEnd
     .p("id='tests'").pEnd
     .p("id='results'").pEnd

    out.bodyEnd.htmlEnd
  }
}

@Js
@NoDoc
internal class DomTestClient
{
  Void testAttrs()
  {
    elem := Win.cur.doc.elem("testAttrs")
    verify(elem != null)

    verifyEq(elem.id,    "testAttrs")
    verifyEq(elem["id"], "testAttrs")
    verifyEq(elem->id,   "testAttrs")

    verifyEq(elem.style.classes, ["hidden"])
    verifyEq(elem["class"],   "hidden")
    verifyEq(elem->className, "hidden")

    f := elem.firstChild
    verifyEq(f->name,  "alpha")
    verifyEq(f.prevSibling, null)
    verifyEq(f.nextSibling->name, "beta")
    verifyEq(f.nextSibling.nextSibling.tagName, "input")
    verifyEq(f.nextSibling.nextSibling.nextSibling.style.classes, ["a"])
    verifyEq(f.nextSibling.nextSibling.nextSibling.nextSibling.style.classes, ["a", "b"])
    verifyEq(elem.lastChild.prevSibling.style.classes, ["a", "b"])
    verifyEq(elem.lastChild.tagName, "div")
    verifyEq(elem.lastChild.nextSibling, null)

    verifyEq(elem.querySelector("input[name='beta']")->name, "beta")
    verifyEq(elem.querySelectorAll("input").size, 3)

    verifyEq(Win.cur.doc.querySelector("input[name='beta']")->name, "beta")
    verifyEq(Win.cur.doc.querySelectorAll("input").size, 3)

    a := elem.children[3]
    b := elem.children[4]
    c := elem.children[5]

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

    verifyEq(elem->value,     null)
    verifyEq(elem["value"],   null)
    verifyEq(elem->checked,   null)
    verifyEq(elem["checked"], null)
    verifyEq(elem.children[0]->name,     "alpha")
    verifyEq(elem.children[0]["name"],   "alpha")
    verifyEq(elem.children[0]->value,    "foo")
    verifyEq(elem.children[0]["value"],  "foo")
    verifyEq(elem.children[1]->name,      "beta")
    verifyEq(elem.children[1]["name"],    "beta")
    verifyEq(elem.children[1]->checked,   true)
    verifyEq(elem.children[1]["checked"], true)
    verifyEq(elem.children[2]->checked,   false)
    verifyEq(elem.children[2]["checked"], false)

    verifyEq(elem["foo"],     null)
    verifyEq(elem.get("foo"), null)
    verifyEq(elem.get("foo", "bar"), "bar")

    verifyEq(elem->offsetTop, 0)
    verifyEq(elem->innerHTML.toStr[0..12].trim,  "<input type=")

    input := Win.cur.doc.querySelector("input[name='alpha']")
    verifyEq(input->value, "foo")
    input->value = "bar"
    verifyEq(input->value, "bar")
  }

  Void testBasics()
  {
    elem := Win.cur.doc.elem("testBasics")
    verify(elem != null)
    kids := elem.children
    verifyEq(kids.size, 3)
    verifyEq(kids[0].html.trim, "alpha")
    verifyEq(kids[1].html, "beta")
    verifyEq(kids[2].html, "gamma")
  }

  Void testCreate()
  {
    elem := Win.cur.doc.createElem("div")
    verifyEq(elem.tagName, "div")

    elem = Win.cur.doc.createElem("div", ["class":"foo"])
    verifyEq(elem.tagName, "div")
    verifyEq(elem.style.classes, ["foo"])

    elem = Win.cur.doc.createElem("div", ["id":"cool", "name":"yay", "class":"foo"])
    verifyEq(elem.tagName, "div")
    verifyEq(elem["id"], "cool")
    verifyEq(elem["name"], "yay")
    verifyEq(elem["class"], "foo")
  }

  Void testAddRemove()
  {
    doc  := Win.cur.doc
    elem := doc.createElem("div")
    elem.add(doc.createElem("div", ["class":"a"]))
    verifyEq(elem.children.size, 1)
    verifyEq(elem.children.first.style.classes, ["a"])

    b := doc.createElem("div", ["class":"b"]); elem.add(b)
    c := doc.createElem("div", ["class":"c"]); elem.add(c)
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
  }

  Void testStyle()
  {
    a := Elem {}

    a.style["padding"] =  "10px"; verifyEq(a.style["padding"], "10px")
    a.style->padding = "20px";    verifyEq(a.style->padding, "20px")

    a.style["background-color"] = "#f00"; verifyEq(a.style["background-color"], "rgb(255, 0, 0)")
    a.style->backgroundColor = "#0f0";    verifyEq(a.style->backgroundColor, "rgb(0, 255, 0)")

    a.style["border-bottom-color"] = "#00f"
    verifyEq(a.style->borderBottomColor, "rgb(0, 0, 255)")

    a.style.setAll([
      "padding": "3px",
      "margin":  "6px",
      "border":  "2px dotted #ff0"
    ])
    verifyEq(a.style->padding, "3px")
    verifyEq(a.style->margin,  "6px")
    verifyEq(a.style->border,  "2px dotted rgb(255, 255, 0)")

    a.style.setCss("padding: 5px; margin: 10px; border: 1px solid #0f0")
    verifyEq(a.style->padding, "5px")
    verifyEq(a.style->margin,  "10px")
    verifyEq(a.style->border,  "1px solid rgb(0, 255, 0)")
  }

  Void verify(Bool v)
  {
    if (v) verifies++
    else throw Err("Test failed")
  }

  Void verifyEq(Obj? a, Obj? b)
  {
    if (a == b) verifies++
    else throw Err("$a != $b")
  }

  Int verifies := 0
}


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
            print('testAttrs');  test.testAttrs();
            print('testBasics'); test.testBasics();
            print('testCreate'); test.testCreate();
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

    verifyEq(elem.className, "hidden")
    verifyEq(elem["class"],  "hidden")

    a := elem.children[3]
    b := elem.children[4]
    c := elem.children[5]

    verifyEq(a.hasClassName("a"), true)
    verifyEq(a.hasClassName("b"), false)
    verifyEq(a.hasClassName("c"), false)
    verifyEq(b.hasClassName("a"), true)
    verifyEq(b.hasClassName("b"), true)
    verifyEq(b.hasClassName("c"), false)
    verifyEq(c.hasClassName("a"), false)
    a.addClassName("c")
    b.addClassName("c")
    c.addClassName("c")
    verifyEq(a.hasClassName("c"), true)
    verifyEq(b.hasClassName("c"), true)
    verifyEq(c.hasClassName("c"), true)
    a.removeClassName("a")
    b.removeClassName("a")
    verifyEq(a.hasClassName("a"), false)
    verifyEq(b.hasClassName("a"), false)
    c.removeClassName("c")
    verifyEq(c.hasClassName("c"), false)
    verifyEq(b.className, "b c")
    b.addClassName("b")
    verifyEq(b.className, "b c")
    b.removeClassName("x")
    verifyEq(b.className, "b c")

    /*
    NOTE: "style.cssText" is not supported in Opera

    verifyEq(elem.style->cssText, "")
    elem.style->color = "red"
    str := (elem.style->cssText as Str).lower.trim
    verify(str.contains("color: red"))
    */

    verifyEq(elem.val,        null)
    verifyEq(elem["value"],   null)
    verifyEq(elem.checked,    null)
    verifyEq(elem["checked"], null)
    verifyEq(elem.children[0].name,      "alpha")
    verifyEq(elem.children[0]["name"],   "alpha")
    verifyEq(elem.children[0].val,       "foo")
    verifyEq(elem.children[0]["value"],  "foo")
    verifyEq(elem.children[1].name,       "beta")
    verifyEq(elem.children[1]["name"],    "beta")
    verifyEq(elem.children[1].checked,    true)
    verifyEq(elem.children[1]["checked"], true)
    verifyEq(elem.children[2].checked,    false)
    verifyEq(elem.children[2]["checked"], false)

    verifyEq(elem["foo"],     null)
    verifyEq(elem.get("foo"), null)
    verifyEq(elem.get("foo", "bar"), "bar")
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
    verifyEq(elem.className, "foo")

    elem = Win.cur.doc.createElem("div", ["id":"cool", "name":"yay", "class":"foo"])
    verifyEq(elem.tagName, "div")
    verifyEq(elem["id"], "cool")
    verifyEq(elem["name"], "yay")
    verifyEq(elem["class"], "foo")
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


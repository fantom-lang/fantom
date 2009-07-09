//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 09  Andy Frank  Creation
//

using dom
using web
using webapp

class DomTest : Widget
{
  override Void onGet()
  {
    head.title.w("Dom Test").titleEnd
    head.includeJs(`/sys/pod/sys/sys.js`)
    head.includeJs(`/sys/pod/dom/dom.js`)
    head.includeJs(`/sys/pod/testWeb/testWeb.js`)
    head.w(
      "<style type='text/css'>
         .hidden { display: none; }
       </style>
       <script type='text/javascript'>
         function print(name)
         {
           var p = document.getElementById('tests');
           p.innerHTML = p.innerHTML + ' -- ' + name + '...<'+'br/>';
         }
         window.onload = function() {
           var results = document.getElementById('results');
           try
           {
             var test = testWeb_TestClient.make();
             print('testAttrs');  test.testAttrs();
             print('testBasics'); test.testBasics();
             print('testCreate'); test.testCreate();
             results.style.color = 'green';
             results.innerHTML = 'All tests passed! [' + test.verifies + ' verifies]';
           }
           catch (err)
           {
             results.style.color = 'red';
             results.innerHTML = 'Test failed - ' + err;
           }
         }
       </script>").nl

    body.h1.w("Dom Test").h1End
    body.hr

    // testAttrs
    body.div("id='testAttrs' class='hidden'")
    body.input("type='text' name='alpha' value='foo'")
    body.checkbox("name='beta' checked='checked'")
    body.checkbox
    body.div("class='a'").divEnd
    body.div("class='a b'").divEnd
    body.div.divEnd
    body.divEnd

    // testBasics
    body.div("id='testBasics' class='hidden'")
    body.p.w("alpha").pEnd
    body.span.w("beta").spanEnd
    body.a(`#`).w("gamma").aEnd
    body.divEnd

    body.p.w("Running...").pEnd
    body.p("id='tests'").pEnd
    body.p("id='results'").pEnd
  }
}

@js
class TestClient
{
  Void testAttrs()
  {
    elem := Doc.elem("testAttrs")
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

    verifyEq(elem.value,      null)
    verifyEq(elem["value"],   null)
    verifyEq(elem.checked,    null)
    verifyEq(elem["checked"], null)
    verifyEq(elem.children[0].name,      "alpha")
    verifyEq(elem.children[0]["name"],   "alpha")
    verifyEq(elem.children[0].value,     "foo")
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
    elem := Doc.elem("testBasics")
    verify(elem != null)
    kids := elem.children
    verifyEq(kids.size, 3)
    verifyEq(kids[0].html.trim, "alpha")
    verifyEq(kids[1].html, "beta")
    verifyEq(kids[2].html, "gamma")
  }

  Void testCreate()
  {
    elem := Doc.createElem("div")
    verifyEq(elem.tagName, "div")

    elem = Doc.createElem("div", ["class":"foo"])
    verifyEq(elem.tagName, "div")
    verifyEq(elem.className, "foo")

    elem = Doc.createElem("div", ["id":"cool", "name":"yay", "class":"foo"])
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
#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 09  Andy Frank  Creation
//

using web
using webapp
using webappClient

class WebappClientTest : Widget
{
  override Void onGet()
  {
    head.title("webappClient Test")
    head.js(`/sys/pod/webappClient/webappClient.js`)
    head.js(`/sys/pod/testWeb/testWeb.js`)
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

    body.h1("webappClient Test")
    body.hr

    // testAttrs
    body.div("id='testAttrs' class='hidden'")
    body.input("type='text' value='foo'")
    body.checkbox("checked='checked'")
    body.checkbox
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

@javascript
class TestClient
{
  Void testAttrs()
  {
    elem := Doc.getById("testAttrs")
    verify(elem != null)

    verifyEq(elem.id,    "testAttrs")
    verifyEq(elem["id"], "testAttrs")

    verifyEq(elem.className, "hidden")
    verifyEq(elem["class"],  "hidden")

    verifyEq(elem.style->cssText, "")
    elem.style->color = "red"
    str := (elem.style->cssText as Str).lower.trim
    verify(str.contains("color: red"))

    verifyEq(elem.value,      null)
    verifyEq(elem["value"],   null)
    verifyEq(elem.checked,    null)
    verifyEq(elem["checked"], null)
    verifyEq(elem.children[0].value,     "foo")
    verifyEq(elem.children[0]["value"],  "foo")
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
    elem := Doc.getById("testBasics")
    verify(elem != null)
    kids := elem.children
    verifyEq(kids.size, 3)
    verifyEq(kids[0].html.trim, "alpha")
    verifyEq(kids[1].html, "beta")
    verifyEq(kids[2].html, "gamma")
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
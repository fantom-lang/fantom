#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jan 09  Andy Frank  Creation
//

using web
using webapp
using webappClient

class CallTest : Widget
{
  override Void onGet()
  {
    head.title("Call Test")
    head.js(`/sys/pod/webappClient/webappClient.js`)
    head.js(`/sys/pod/testWeb/testWeb.js`)

    body.h1("Call Test")

    body.h3("GET")
    body.ul
    doCall("GET", "Alpha", #alpha)
    doCall("GET", "Beta", #beta)
    doCall("GET", "Error", `/call?webappWidgetCall=testWeb::CallTest.noexist`)
    doCall("GET", "Error", `/call?webappWidgetCall=sys::Obj.echo`)
    body.ulEnd

    body.h3("POST")
    body.ul
    doCall("POST", "Gamma", #gamma)
    doCall("POST", "Error", `/call?webappWidgetCall=testWeb::CallTest.noexist`)
    doCall("POST", "Error", `/call?webappWidgetCall=sys::Obj.echo`)
    body.ulEnd

    try
    {
      call(Obj#echo)
      throw Err("Should not be allowed")
    }
    catch (ArgErr e) {}
  }

  Void doCall(Str method, Str name, Obj obj)
  {
    uri := (obj is Method) ? call(obj as Method) : (obj as Uri)
    body.li
    if (method == "GET")
      body.a(uri)
    else
      body.a(`#`, "onclick='testWeb_CallTestClient.testPost(\"$uri\"); return false;'")
    body.w(name).aEnd.w(" - $uri.encode.toXml").liEnd
  }

  Void alpha() { head.title("CallTest#alpha"); body.h1("CallTest#alpha") }
  Void beta()  { head.title("CallTest#beta"); body.h1("CallTest#beta") }
  Void gamma() { body.w("CallTest#gamma") }
}

@javascript
class CallTestClient
{
  static Void testPost(Str uri)
  {
    HttpReq(uri).send("") |HttpRes res|
    {
      Window.alert(res.content)
    }
  }
}
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
    head.title.w("Call Test").titleEnd
    head.includeJs(`/sys/pod/webappClient/webappClient.js`)
    head.includeJs(`/sys/pod/testWeb/testWeb.js`)

    body.h1.w("Call Test").h1End

    body.h3.w("GET").h3End
    body.ul
    doCall("GET", "Alpha", #alpha)
    doCall("GET", "Beta", #beta)
    doCall("GET", "Error", `/call?webappWidgetCall=testWeb::CallTest.noexist`)
    doCall("GET", "Error", `/call?webappWidgetCall=sys::Obj.echo`)
    body.ulEnd

    body.h3.w("POST").h3End
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
      body.a(`#`, "onclick='testWeb_CallTestClient.testPost(sys_Uri.make(\"$uri\")); return false;'")
    body.w(name).aEnd.w(" - $uri.encode.toXml").liEnd
  }

  Void alpha() { head.title.w("CallTest#alpha").titleEnd; body.h1.w("CallTest#alpha").h1End }
  Void beta()  { head.title.w("CallTest#beta").titleEnd; body.h1.w("CallTest#beta").h1End }
  Void gamma() { body.w("CallTest#gamma") }
}

@javascript
class CallTestClient
{
  static Void testPost(Uri uri)
  {
    HttpReq(uri).send("") |HttpRes res|
    {
      Window.alert(res.content)
    }
  }
}
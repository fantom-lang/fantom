#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 09  Andy Frank  Creation
//

using fand
using wisp
using web
using webapp
using webappClient
using testWeb

class Boot : BootScript
{
  override Thread[] services :=
  [
    // WebService
    WispService("web")
    {
      port = 8080
      pipeline =
      [
        FindResourceStep {},
        FindViewStep {},
        ServiceViewStep {},
      ]
    },
  ]

  override Void setup()
  {
    Sys.ns.create(`/homePage`, Index#)
    Sys.ns.create(`/webappClient`, WebappClientTest#)
    Sys.ns.create(`/call`,         CallTest#)
  }
}

class Index : Widget
{
  override Void onGet()
  {
    head.title("testWeb Tests")
    body.h1("testWeb Tests")
    body.ul
    body.li.a(`/webappClient`).w("webappClient unit tests").aEnd.liEnd
    body.li.a(`/call`).w("Call tests").aEnd.liEnd
    body.ulEnd
  }
}
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
    Sys.ns.create(`/homePage`, WebappClientTest#)
  }
}
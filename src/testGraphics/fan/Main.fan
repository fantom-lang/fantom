//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Feb 2022  Brian Frank  Creation
//

using graphics
using web
using wisp

class Main : Test
{
  Void main(Str[] args := [,])
  {
    launchDom
    launchJava(args.first)
  }

  Void launchDom()
  {
    WispService
    {
      it.httpPort = 8080
      it.root = MainDomMod()
    }.start
  }

  Void launchJava(Str? typeName)
  {
    MainJava.run(typeName)
  }
}


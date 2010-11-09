//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Mar 08  Brian Frank  Creation
//

using web
using concurrent

internal class WispSession : WebSession
{
  new make(Str id, Str:Obj? map) { this.id = id; this.map = map }

  override Void delete()
  {
    isDeleted = true
    WispRes res := Actor.locals["web.res"]
    res.cookies.add(Cookie("fanws", id) { maxAge=0sec })
  }

  override const Str id
  override Str:Obj? map := Str:Obj[:]
  internal Bool isDeleted := false
}


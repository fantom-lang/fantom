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

  override Void each(|Obj?,Str| f)
  {
    map.each(f)
  }

  override Obj? get(Str name, Obj? def := null)
  {
    map.get(name, def)
  }

  override Void set(Str name, Obj? val)
  {
    if (map[name] == val) return
    if (val != null && !val.isImmutable)
      throw NotImmutableErr("WebSession value not immutable: $val")
    modify
    map[name] = val
  }

  override Void remove(Str name)
  {
    if (!map.containsKey(name)) return
    modify
    map.remove(name)
  }

  // TODO: deprecated
  override Str:Obj? map := Str:Obj[:]

  private This modify()
  {
    if (map.isRO) map = map.rw
    return this
  }

  internal Bool isDeleted := false
}


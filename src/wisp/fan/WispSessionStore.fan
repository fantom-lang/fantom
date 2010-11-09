//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Nov 10  Brian Frank  Creation
//

using concurrent
using web

**
** Pluggable hooks for Wisp session storage.
**
const mixin WispSessionStore
{
  ** Callback when WispService is started
  virtual Void onStart() {}

  ** Callback when WispService is stopped
  virtual Void onStop() {}

  ** Load the session map for the given id, or if it
  ** doesn't exist then create a new one.
  abstract Str:Obj? load(Str id)

  ** Save the given session map by session id.
  abstract Void save(Str id, Str:Obj? map)

  ** Delete any resources used by the given session id
  abstract Void delete(Str id)


  internal WispSession doLoad(WebReq req)
  {
    WispSession? ws := null

    // try to lookup existing session via cookie
    id := req.cookies["fanws"]
    if (id != null)
    {
      map := load(id)
      ws = WispSession(id, map)
    }

    // create new session, and add cookie to response
    else
    {
      ws = WispSession(Uuid.make.toStr, Str:Obj?[:])
      WispRes res := Actor.locals["web.res"]
      res.cookies.add(Cookie("fanws", ws.id))
    }

    // store in actor loical
    Actor.locals["web.session"] = ws
    return ws
  }

  internal Void doSave()
  {
    try
    {
      WispSession? ws := Actor.locals.remove("web.session")
      if (ws != null)
      {
        if (ws.isDeleted)
          delete(ws.id)
        else
          save(ws.id, ws.map)
      }
    }
    catch (Err e)
    {
      WispService.log.err("WispSession save", e)
    }
  }
}
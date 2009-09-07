//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Mar 08  Brian Frank  Creation
//

**
** WebSession provides a name/value map associated with
** a specific browser "connection" to the web server.  Any
** values stored in a WebSession must be serializable.
** Get the current WebSession via `WebReq.session`.
**
** See [docLib::Web]`docLib::Web#sessions`
**
@serializable
class WebSession
{

  **
  ** Internal make
  **
  internal new make(Str? id := null)
  {
    if (id != null) this.id = id
  }

  **
  ** Get the unique id used to identify this session.
  **
  const Str id := ""

  **
  ** Return `id`.
  **
  override Str toStr() { return id }

  **
  ** Convenience for 'map.get(name, def)'.
  **
  Obj? get(Str name, Obj? def := null) { return map.get(name, def) }

  **
  ** Convenience for 'map.set(name, val)'.
  **
  Void set(Str name, Obj? val) { map[name] = val }

  **
  ** Application name/value pairs which are persisted
  ** between HTTP requests.  The values stored in this
  ** map must be serializable.
  **
  readonly Str:Obj? map := Str:Obj[:]

  **
  ** Delete this web session which clears both the user
  ** agent cookie and the server side session instance.
  ** This method must be called before the WebRes is
  ** committed - if not the server side instance is cleared,
  ** but the user agent cookie will remain uncleared.
  **
  Void delete()
  {
    isDeleted = true
    WebRes res := Actor.locals["web.res"]
    res.cookies.add(Cookie("fanws", id) { maxAge=0sec })
  }

  internal Bool isDeleted := false
  internal Duration lastAccess := Duration.defVal

}

**************************************************************************
** WebSessionMgr
**************************************************************************

**
** WebSessionMgr is a pod internal class which is a background
** thread used to manage WebSession storage and cleanup.
**
internal const class WebSessionMgr : ActorPool
{
  const Actor actor := Actor(this) |msg,cx| { receive(msg, cx) }

  const Duration houseKeepingPeriod := 1min

  new make()
  {
    actor.sendLater(houseKeepingPeriod, "_houseKeeping")
  }

  WebSession load(WebReq req)
  {
    WebSession? ws := null

    // try to lookup existing session via cookie
    cookie := req.cookies["fanws"]
    if (cookie != null)
    {
      ws = actor.send(cookie).get
    }

    // if we still don't have a session, we need to
    // create one and add the cookie to the response
    if (ws == null)
    {
      ws = actor.send("_new").get
      WebRes res := Actor.locals["web.res"]
      res.cookies.add(Cookie("fanws", ws.id))
    }

    Actor.locals["web.session"] = ws
    return ws
  }

  Void save()
  {
    try
    {
      WebSession? ws := Actor.locals.remove("web.session")
      if (ws != null) actor.send(ws)
    }
    catch (Err e)
    {
      WebService.log.error("WebSession save", e)
    }
  }

  Obj? receive(Obj? msg, Context cx)
  {
    [Str:WebSession]? sessions := cx["sessions"]
    if (sessions == null) cx["sessions"] = sessions = Str:WebSession[:]

    // generate new session
    if (msg === "_new")
    {
      while (true)
      {
        id := Buf.random(12).toHex
        if (sessions[id] != null) continue
        ws := WebSession(id)
        ws.lastAccess = Duration.now
        sessions[id] = ws
        return ws
      }
    }

    // for now clean-up old sessions after 24 hours
    if (msg === "_houseKeeping")
    {
      now := Duration.now
      old := sessions.findAll |WebSession s->Bool|
      {
        return now - s.lastAccess > 24hr
      }
      old.each |WebSession s| { sessions.remove(s.id) }
      actor.sendLater(houseKeepingPeriod, "_houseKeeping")
      return null
    }

    // str message is load
    id := msg as Str
    if (id != null)
    {
      return sessions[id]
    }

    // session message is save
    ws := msg as WebSession
    if (ws != null)
    {
      ws.lastAccess = Duration.now
      if (ws.isDeleted)
        sessions.remove(ws.id)
      else
        sessions[ws.id] = ws
      return null
    }

    echo("WebSessionMgr.unknown msg: $msg")
    return null
  }

}
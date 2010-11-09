//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Mar 08  Brian Frank  Creation
//

using concurrent
using web

**
** WispSession
**
@Serializable
internal class WispSession : WebSession
{

  new make(Str? id := null) : super(id) {}

  override Void delete()
  {
    isDeleted = true
    WispRes res := Actor.locals["web.res"]
    res.cookies.add(Cookie("fanws", id) { maxAge=0sec })
  }

  internal Bool isDeleted := false
  internal Duration lastAccess := Duration.defVal

}

**************************************************************************
** WispSessionMgr
**************************************************************************

**
** WispSessionMgr manages WispSession storage and cleanup.
**
internal const class WispSessionMgr : ActorPool
{
  const Actor actor := Actor(this) |msg| { receive(msg) }

  const Duration houseKeepingPeriod := 1min

  new make(|This|? f := null) : super(f)
  {
    actor.sendLater(houseKeepingPeriod, "_houseKeeping")
  }

  WispSession load(WebReq req)
  {
    WispSession? ws := null

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
      WispRes res := Actor.locals["web.res"]
      res.cookies.add(Cookie("fanws", ws.id))
    }

    Actor.locals["web.session"] = ws
    return ws
  }

  Void save()
  {
    try
    {
      WispSession? ws := Actor.locals.remove("web.session")
      if (ws != null) actor.send(ws)
    }
    catch (Err e)
    {
      WispService.log.err("WispSession save", e)
    }
  }

  Obj? receive(Obj? msg)
  {
    [Str:WispSession]? sessions := Actor.locals["wisp.sessions"]
    if (sessions == null) Actor.locals["wisp.sessions"] = sessions = Str:WispSession[:]

    // generate new session
    if (msg === "_new")
    {
      while (true)
      {
        id := Buf.random(12).toHex
        if (sessions[id] != null) continue
        ws := WispSession(id)
        ws.lastAccess = Duration.now
        sessions[id] = ws
        return ws
      }
    }

    // for now clean-up old sessions after 24 hours
    if (msg === "_houseKeeping")
    {
      now := Duration.now
      old := sessions.findAll |WispSession s->Bool|
      {
        return now - s.lastAccess > 24hr
      }
      old.each |WispSession s| { sessions.remove(s.id) }
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
    ws := msg as WispSession
    if (ws != null)
    {
      ws.lastAccess = Duration.now
      if (ws.isDeleted)
        sessions.remove(ws.id)
      else
        sessions[ws.id] = ws
      return null
    }

    echo("WispSessionMgr.unknown msg: $msg")
    return null
  }

}
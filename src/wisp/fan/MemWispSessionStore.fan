//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Mar 08  Brian Frank  Creation
//

using concurrent
using web

**
** Default memory based web session storage
**
internal const class MemWispSessionStore : WispSessionStore
{
  override Void onStart() { actor.sendLater(houseKeepingPeriod, "_houseKeeping") }

  override Void onStop() { actorPool.stop }

  override Str:Obj? load(Str id) { actor.send(id).get(timeout) }

  override Void save(Str id, Str:Obj? map) { actor.send(map.set("__id", id)) }

  override Void delete(Str id) { actor.send(["__id":id, "__delete":true]) }

  Obj? receive(Obj? msg)
  {
    [Str:Map]? sessions := Actor.locals["wisp.sessions"]
    if (sessions == null) Actor.locals["wisp.sessions"] = sessions = Str:Map[:]

    // clean-up old sessions after expiration period
    if (msg === "_houseKeeping")
    {
      now := Duration.now
      expired := Str[,]
      sessions.each |Str:Obj? map, Str id|
      {
        lastAccess := map["__lastAccess"] as Duration
        if (lastAccess != null && now - lastAccess > expirationPeriod)
          expired.add(id)
      }
      expired.each |id|
      {
        sessions.remove(id)
      }
      actor.sendLater(houseKeepingPeriod, "_houseKeeping")
      return null
    }

    // Str id is a load
    if (msg is Str)
    {
      Str id := msg
      return sessions[msg] ?: Str:Obj?[:]
    }

    // Map is save or delete
    if (msg is Map)
    {
      Str:Obj? map := msg
      Str id := map.remove("__id")
      if (map["__delete"] == true)
      {
        sessions.remove(id)
      }
      else
      {
        map["__lastAccess"] = Duration.now
        sessions[id] = map
      }
      return null
    }


    echo("WispSessionMgr.unknown msg: $msg")
    return null
  }

  const ActorPool actorPool := ActorPool()
  const Actor actor := Actor(actorPool) |msg| { receive(msg) }
  const Duration houseKeepingPeriod := 1min
  const Duration timeout := 15sec
  const Duration expirationPeriod := 24hr
}


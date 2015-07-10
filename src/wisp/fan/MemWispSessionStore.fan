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
internal const class MemWispSessionStore : Actor, WispSessionStore
{
  new make() : super(ActorPool { it.name = "WispServiceSessions" }) {}

  override Void onStart() { sendLater(houseKeepingPeriod, Msg("houseKeeping")) }

  override Void onStop() { pool.stop }

  override Str:Obj? load(Str id) { send(Msg("load", id)).get(timeout) }

  override Void save(Str id, Str:Obj? map) { send(Msg("save", id, map)) }

  override Void delete(Str id) { send(Msg("delete", id)) }

  override Obj? receive(Obj? msgObj)
  {
    try
    {
      msg := (Msg)msgObj

      // init or lookup map of sessions
      sessions := Actor.locals["wisp.sessions"] as Str:MemStoreSession
      if (sessions == null) Actor.locals["wisp.sessions"] = sessions = Str:MemStoreSession[:]

      // dispatch msg to handler method
      switch(msg.cmd)
      {
        case "houseKeeping": return onHouseKeeping(sessions)
        case "load":         return onLoad(sessions, msg)
        case "save":         return onSave(sessions, msg)
        case "delete":       return onDelete(sessions, msg)
      }

      echo("Unhandled msg: $msg.cmd")
    }
    catch (Err e) e.trace
    return null
  }

  private Obj? onHouseKeeping(Str:MemStoreSession sessions)
  {
    // clean-up old sessions after expiration period
    now := Duration.nowTicks
    expired := Str[,]
    sessions.each |session|
    {
      if (now - session.lastAccess > expirationPeriod.ticks)
        expired.add(session.id)
    }
    expired.each |id| { sessions.remove(id) }
    sendLater(houseKeepingPeriod, Msg("houseKeeping"))
    return null
  }

  private Map onLoad(Str:MemStoreSession sessions, Msg msg)
  {
    sessions[msg.id]?.map ?: emptyMap
  }

  private Obj? onSave(Str:MemStoreSession sessions, Msg msg)
  {
    session := sessions[msg.id]
    if (session == null) sessions[msg.id] = session = MemStoreSession(msg.id)
    session.map = msg.map
    session.lastAccess = Duration.nowTicks
    return null
  }

  private Obj? onDelete(Str:MemStoreSession sessions, Msg msg)
  {
    sessions.remove(msg.id)
    return null
  }

  const Duration houseKeepingPeriod := 1min
  const Duration expirationPeriod := 24hr
  const Duration timeout := 15sec
  const Str:Obj? emptyMap := [:]
}

internal const class Msg
{
  new make(Str c, Str? i := null, Map? m := null) { cmd = c; id = i; map = m }
  const Str cmd
  const Str? id
  const Map? map
}

internal class MemStoreSession
{
  new make(Str id) { this.id = id }
  const Str id
  Map? map
  Int lastAccess
}


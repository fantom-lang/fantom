//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 07  Brian Frank  Creation
//

using web
using inet

**
** Wisp implementation of WebService.
**
const class WispService : WebService
{

  **
  ** Well known TCP port for HTTP traffic.
  **
  const Int port := 80

  override Void onStart()
  {
    super.onStart
    Actor(listenerGroup, &listen).send(null)
  }

  override Void onStop()
  {
    listenerGroup.stop
    processorGroup.stop
  }

  internal Void listen()
  {
    listener := TcpListener()
    listener.bind(null, port)
    log.info("WispService started on port ${port}")

    numReqs := 0
    Sys.ns.create(`/wisp/numReqs`, numReqs)

    while (!listenerGroup.isStopped)
    {
      socket := listener.accept
      WispActor(this, socket).send(null)

      numReqs++
      Sys.ns.put(`/wisp/numReqs`, numReqs)
    }
  }

  const ActorGroup listenerGroup := ActorGroup()
  const ActorGroup processorGroup := ActorGroup()

}
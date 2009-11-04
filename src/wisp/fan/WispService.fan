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

  new make(|This|? f := null) { if (f != null) f(this) }

  override Void onStart()
  {
    super.onStart
    Actor(listenerPool, |,| { listen }).send(null)
  }

  override Void onStop()
  {
    listenerPool.stop
    processorPool.stop
  }

  internal Void listen()
  {
    listener := TcpListener()
    listener.bind(null, port)
    log.info("WispService started on port ${port}")

    while (!listenerPool.isStopped)
    {
      socket := listener.accept
      WispActor(this, socket).send(null)
    }
  }

  const ActorPool listenerPool  := ActorPool()
  const ActorPool processorPool := ActorPool()

}
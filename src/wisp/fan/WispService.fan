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

  **
  ** Constructor with thread name.
  **
  new make(Str? name := null) : super.make(name) {}

  **
  ** Main loop.
  **
  override Obj? run()
  {
    listener := TcpListener.make
    listener.bind(null, port)
    log.info("WispService started on port ${port}")

    numReqs := 0
    Sys.ns.create(`/wisp/numReqs`, numReqs)

    while (isRunning)
    {
      socket := listener.accept
      WispThread(this, socket).start

      numReqs++
      Sys.ns.put(`/wisp/numReqs`, numReqs)
    }
    return null
  }

}
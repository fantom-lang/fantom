//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jun 24  Brian Frank  Creation
//

**
** SqlConnPool manages a pool of reusable SQL connections
**
const class SqlConnPool
{
  ** It-block construtor
  new make(|This|? f) { if (f != null) f(this) }

  ** Connection URI
  const Str uri

  ** Connection username
  const Str? username

  ** Connection password
  const Str? password

  ** Max number of simultaneous connections to allow before blocking threads
  const Int maxConns := 100

  ** Max time to block waiting for a connection before raising TimeoutErr
  const Duration timeout := 30sec

  ** Time to linger an idle connection before closing it.  An external
  ** actor must call checkLinger periodically to close idle connetions.
  const Duration linger := 5min

  ** Logger
  const Log log := Log.get("sqlPool")

  ** Allocate a SQL connection inside the given callback.  If a connection
  ** cannot be acquired before `timeout` elapses then a TimeoutErr is raised.
  ** Do not close the connection inside the callback.
  native Void execute(|SqlConn| f)

  ** Close idle connections that have lingered past the linger timeout.
  native Void checkLinger()

  ** Return if `close` has been called.
  native Bool isClosed()

  ** Close all connections and raise exception on any new executes
  native Void close()

  ** Return debug dump string for current state
  @NoDoc native Str debug()
}


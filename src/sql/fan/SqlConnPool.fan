//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jun 24  Brian Frank  Creation
//

using concurrent

**
** SqlConnPool manages a pool of reusable SQL connections
**
const class SqlConnPool
{
  ** It-block construtor
  new make(|This|? f)
  {
    if (f != null) f(this)
    startBookkeeping
  }

  ** Connection URI
  const Str uri

  ** Connection username
  const Str? username

  ** Connection password
  const Str? password

  ** Max number of simultaneous connections to allow before blocking threads
  const Int maxConns := 10

  ** Max time to block waiting to check out a connection from the pool
  ** before raising TimeoutErr.  This is the wait for an available
  ** connection, not the time to open a new one; see `connectTimeout`.
  const Duration checkoutTimeout := 30sec

  ** Max time to wait when opening a new connection to the database before
  ** raising TimeoutErr.  This bounds this pool only; it does not depend on
  ** driver support and is not a JVM wide setting.  If null then a connect
  ** blocks for as long as the driver allows.  A connect that lands after
  ** its timeout is closed rather than pooled, so a slow database cannot
  ** leak connections.
  const Duration? connectTimeout := null

  ** Time to linger an idle connection before closing it.
  const Duration linger := 5min

  ** Max lifetime of a connection before it is retired, regardless of
  ** how recently it was used.  This protects against database and
  ** network infrastructure that kills long lived connections.
  ** Connections in use are never retired until released back to the pool.
  const Duration maxLifetime := 30min

  ** Time a connection may be held by an execute callback before a warning
  ** is logged that it may be stuck or leaked.  The warning is logged once
  ** per checkout.
  const Duration leakWarn := 2min

  ** Only ping a connection on checkout if it has been idle at least this
  ** long.  A connection used moments ago is almost certainly still good,
  ** and the ping costs a database round trip on every checkout.  If null
  ** then connections are never pinged on checkout.  Note this governs
  ** checkout only: a connection is always validated after an execute
  ** callback raises, since there the error is evidence something broke.
  const Duration? validateAfterIdle := 500ms

  ** Max time the liveness ping may take before the connection is treated
  ** as broken.  JDBC resolves this in whole seconds, so anything under a
  ** second is rounded up to one second.
  const Duration validationTimeout := 3sec

  ** How often the pool runs its own bookkeeping: close connections idle
  ** past `linger`, retire connections older than `maxLifetime`, and warn
  ** about connections held past `leakWarn`.  The pool schedules this
  ** itself; callers never drive it.
  const Duration bookkeepingInterval := 30sec

  ** onOpen is invoked just after a connection is opened by the pool.
  protected virtual Void onOpen(SqlConn c) {}

  ** onClose is invoked just before a connection is closed by the pool.
  protected virtual Void onClose(SqlConn c) {}

  ** Logger
  const Log log := Log.get("sqlPool")

  ** autoCommit sets the autoCommit mode used by connections in the pool.
  ** It is applied when a connection is opened and restored every time a
  ** connection is released back to the pool, so a callback that changes
  ** the mode cannot leak it to the next borrower.  Changing this at
  ** runtime takes effect for each pooled connection the next time it is
  ** released.
  **
  ** If auto-commit is true then each statement is executed and committed
  ** as an individual transaction.  Otherwise statements are grouped into
  ** transaction which must be closed via [SqlConn.commit] or [SqlConn.rollback].
  Bool autoCommit
  {
    get { return isAutoCommit.val }
    set { isAutoCommit.val = it }
  }
  private const AtomicBool isAutoCommit := AtomicBool(false)

  ** Allocate a SQL connection inside the given callback.  If a connection
  ** cannot be acquired before [checkoutTimeout] elapses then a TimeoutErr
  ** is raised.  Do not close the connection inside the callback.
  native Void execute(|SqlConn| f)

  ** Return if [close] has been called.
  native Bool isClosed()

  ** Close all connections, stop bookkeeping, and raise exception on any
  ** new executes
  native Void close()

  ** Return debug dump string for current state
  @NoDoc native Str debug()

  ** Start the pool's bookkeeping timer; called once from the constructor
  ** after the it-block has run so the configuration is in place.
  @NoDoc native Void startBookkeeping()

  ** One bookkeeping pass.  Scheduled by the pool itself every
  ** `bookkeepingInterval`; exposed only so tests can drive it
  ** deterministically.
  @NoDoc native Void onBookkeeping()
}


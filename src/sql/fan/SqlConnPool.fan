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
    ka := keepaliveInterval
    if (ka != null && ka >= linger)
      log.warn("SqlConnPool keepaliveInterval ($ka) must be less than linger ($linger) to take effect")
    startHouseKeeping
  }

  ** Connection URI
  const Str uri

  ** Connection username
  const Str? username

  ** Connection password
  const Str? password

  ** Max number of simultaneous connections to allow before blocking threads
  const Int maxConns := 10

  ** Max time to block waiting for a connection to become available in the
  ** pool before raising TimeoutErr.  Opening a new connection is bounded
  ** separately by `connectTimeout`.
  const Duration checkoutTimeout := 30sec

  ** Max time to wait when opening a new connection before raising
  ** TimeoutErr, or null to wait as long as the driver allows.  Scoped to
  ** this pool and enforced without driver support.  A connect that
  ** completes after the timeout is closed rather than pooled.
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

  ** Default timeout applied to every statement created on connections from
  ** this pool, or null for no timeout.  Applies per execution, so a batch
  ** must complete within it.  JDBC resolves it in whole seconds; anything
  ** under a second is rounded up to one second.
  const Duration? queryTimeout := 60sec

  ** How long an idle connection may sit before houseKeeping pings it, or
  ** null to never ping idle connections.  A failed ping evicts the
  ** connection.  Must be less than `linger` to have any effect.  A ping
  ** does not count as a use and does not defer `linger`.
  const Duration? keepaliveInterval := 2min

  ** Ping a connection on checkout only if it has been idle at least this
  ** long, or null to never ping on checkout.  The ping costs a database
  ** round trip.  Governs checkout only: a connection is always validated
  ** after an execute callback raises.
  const Duration? validateAfterIdle := 500ms

  ** Max time a liveness ping may take before the connection is treated as
  ** broken.  JDBC resolves this in whole seconds; anything under a second
  ** is rounded up to one second.
  const Duration validationTimeout := 3sec

  ** How often the pool runs houseKeeping: close connections idle past
  ** `linger`, retire connections older than `maxLifetime`, ping idle
  ** connections due a keepalive, and warn about connections held past
  ** `leakWarn`.  Scheduled by the pool; callers do not drive it.
  const Duration houseKeepingInterval := 30sec

  ** onOpen is invoked just after a connection is opened by the pool.
  protected virtual Void onOpen(SqlConn c) {}

  ** onClose is invoked just before a connection is closed by the pool.
  protected virtual Void onClose(SqlConn c) {}

  ** Capture a stack trace at every checkout and include it in the
  ** `leakWarn` warning.  Costs a stack fill per checkout, so it is off by
  ** default.
  const Bool leakTrace := false

  ** Logger
  const Log log := Log.get("sqlPool")

  ** autoCommit sets the autoCommit mode used by connections in the pool.
  ** Applied when a connection is opened and restored when it is released,
  ** so a callback cannot leave the mode changed for the next borrower.
  ** Changing it at runtime takes effect per connection on its next
  ** release.
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

  ** Close all connections, stop houseKeeping, and raise exception on any
  ** new executes
  native Void close()

  ** Snapshot of the pool's gauges and cumulative counters
  native SqlConnPoolStats stats()

  ** Return debug dump string for current state
  @NoDoc native Str debug()

  ** Start the houseKeeping timer.  Must be called after the it-block has
  ** run, since it reads `houseKeepingInterval`.
  @NoDoc native Void startHouseKeeping()

  ** Run one houseKeeping pass.  Called on the timer; exposed so tests can
  ** drive it directly.
  @NoDoc native Void onHouseKeeping()
}


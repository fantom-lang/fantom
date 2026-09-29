//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jun 24  Brian Frank  Creation
//

**
** SqlConnPoolStats is an immutable snapshot of a `SqlConnPool`.  Gauges
** are as of the snapshot; counters are cumulative since the pool was
** created and are never reset.
**
const class SqlConnPoolStats
{
  @NoDoc new make(Int total, Int active, Int idle, Int waiting, Int maxConns,
                  Int checkouts, Int checkoutTimeouts, Int opened,
                  Int retired, Int evicted, Int leakWarnings)
  {
    this.total            = total
    this.active           = active
    this.idle             = idle
    this.waiting          = waiting
    this.maxConns         = maxConns
    this.checkouts        = checkouts
    this.checkoutTimeouts = checkoutTimeouts
    this.opened           = opened
    this.retired          = retired
    this.evicted          = evicted
    this.leakWarnings     = leakWarnings
  }

  ** Connections the pool holds, including slots still being opened
  const Int total

  ** Connections currently checked out.  A slot reserved for a connection
  ** that is still opening counts here.
  const Int active

  ** Connections available for checkout.  A connection held by a keepalive
  ** ping counts here.
  const Int idle

  ** Threads blocked waiting for a connection
  const Int waiting

  ** `SqlConnPool.maxConns`
  const Int maxConns

  ** Connections handed to an execute callback
  const Int checkouts

  ** Checkouts that gave up after `SqlConnPool.checkoutTimeout`
  const Int checkoutTimeouts

  ** Connections opened against the database
  const Int opened

  ** Connections closed for age: idle past `SqlConnPool.linger`, or older
  ** than `SqlConnPool.maxLifetime`
  const Int retired

  ** Connections closed as broken: failed validation on checkout, failed
  ** after an execute callback raised, or failed a keepalive ping
  const Int evicted

  ** Warnings logged for connections held past `SqlConnPool.leakWarn`
  const Int leakWarnings

  override Str toStr()
  {
    "SqlConnPoolStats { total=$total active=$active idle=$idle waiting=$waiting " +
    "maxConns=$maxConns checkouts=$checkouts checkoutTimeouts=$checkoutTimeouts " +
    "opened=$opened retired=$retired evicted=$evicted leakWarnings=$leakWarnings }"
  }
}


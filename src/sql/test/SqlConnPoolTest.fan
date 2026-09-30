//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jun 24  Brian Frank  Creation
//

using concurrent

**
** SqlConnPoolTest
**
class SqlConnPoolTest : Test
{
  Void test()
  {
    // this test verifies connection ids by name, so reset the id
    // counter in case other test methods already created connections
    TestSqlConn.idCounter.val = 0

    cp := SqlConnPool
    {
      it.uri      = "test"
      it.maxConns = 2
      it.linger   = 200ms
      it.keepAliveFreq = null
      it.checkoutTimeout  = 300ms
      it.houseKeepingFreq = 1hr
    }


    ap := ActorPool()
    a1 := SqlConnPoolTestActor(ap, cp, "a1")
    a2 := SqlConnPoolTestActor(ap, cp, "a2")
    a3 := SqlConnPoolTestActor(ap, cp, "a3")
    a4 := SqlConnPoolTestActor(ap, cp, "a4")
    actors := [a1, a2, a3, a4]
    reset := |->| { actors.each |a| { a.lastName.val = null } }

    // initial state
    verifyPool(cp, actors, 0, 0, [null, null, null, null])

    // run one quickly
    a1.send(1ms).get
    verifyPool(cp, actors, 0, 1, ["0", null, null, null])

    // run one slower and verify inUse
    f1 := execute(a1, 50ms)
    verifyPool(cp, actors, 1, 0, ["0", null, null, null])
    f1.get

    // run two slowly and verify both inUse
    reset()
    f1  = execute(a1, 50ms)
    f2 := execute(a2, 100ms)
    verifyPool(cp, actors, 2, 0, ["0", "1", null, null])
    f1.get
    verifyPool(cp, actors, 1, 1, ["0", "1", null, null])
    f2.get
    verifyPool(cp, actors, 0, 2, ["0", "1", null, null])

    // run one and make sure most recently used connection used
    reset()
    f1 = execute(a1, 50ms)
    verifyPool(cp, actors, 1, 1, ["1", null, null, null])
    f1.get
    verifyPool(cp, actors, 0, 2, ["1", null, null, null])

    // now run all four and verify a3, a4 block until conn frees up
    reset()
    f1  = execute(a1, 50ms)
    f2  = execute(a2, 100ms)
    f3 := a3.send(100ms)
    f4 := a4.send(100ms)
    verifyPool(cp, actors, 2, 0, ["1", "0", null, null])
    verifyEq(a1.isExecuting, true)
    verifyEq(a2.isExecuting, true)
    verifyEq(a3.isExecuting, false)
    verifyEq(a4.isExecuting, false)
    f1.get
    Actor.sleep(10ms)
    verifyEq(a1.isExecuting, false)
    verifyEq(a2.isExecuting, true)
    verifyEq(a3.isExecuting.xor(a4.isExecuting), true) // one or other should be running now
    f2.get
    Actor.sleep(10ms)
    verifyEq(a1.isExecuting, false)
    verifyEq(a2.isExecuting, false)
    verifyEq(a3.isExecuting, true)
    verifyEq(a4.isExecuting, true)
    verifyPool(cp, actors, 2, 0, ["1", "0", "x", "x"])
    f3.get
    f4.get
    verifyPool(cp, actors, 0, 2, ["1", "0", "x", "x"])

    // wait for linger time and verify conns are closed
    reset()
    Actor.sleep(cp.linger)
    cp.onHouseKeeping
    verifyPool(cp, actors, 0, 0, [null, null, null, null])

    // run one quickly
    a3.send(1ms).get
    verifyPool(cp, actors, 0, 1, [null, null, "2", null])

    // verify timeouts
    reset()
    f1 = execute(a1, cp.checkoutTimeout+40ms)
    f2 = execute(a2, cp.checkoutTimeout+40ms)
    f3 = a3.send(1sec)
    f4 = a4.send(1sec)
    verifyPool(cp, actors, 2, 0, ["2", "3", null, null])
    verifyErr(TimeoutErr#) { f3.get }
    verifyErr(TimeoutErr#) { f4.get }

    // close
    reset()
    verifyEq(cp.isClosed, false)
    cp.close
    verifyEq(cp.isClosed, true)
    verifyPool(cp, actors, 0, 0, [null, null, null, null])
  }

  Void testValidateOnBorrow()
  {
    cp := SqlConnPool { it.uri = "test" }
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }

    // recently used connections are reused without validation
    c1.valid = false
    TestSqlConn? c2 := null
    cp.execute |c| { c2 = c }
    verifySame(c1, c2)

    // once idle past the validation threshold, the broken
    // connection is evicted and replaced with a fresh one
    Actor.sleep(600ms)
    TestSqlConn? c3 := null
    cp.execute |c| { c3 = c }
    verifyNotSame(c1, c3)
    verifyEq(c1.isClosed, true)
    verifyEq(debugInt(cp.debug, "entries"), 1)
    cp.close
  }

  Void testEvictOnError()
  {
    cp := SqlConnPool { it.uri = "test" }
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }

    // callback error with healthy connection: released for reuse
    verifyErr(IOErr#) { cp.execute |c| { throw IOErr("boom") } }
    verifyEq(c1.isClosed, false)
    TestSqlConn? c2 := null
    cp.execute |c| { c2 = c }
    verifySame(c1, c2)

    // callback error with broken connection: evicted
    verifyErr(IOErr#) { cp.execute |c| { ((TestSqlConn)c).valid = false; throw IOErr("boom") } }
    verifyEq(c1.isClosed, true)
    verifyEq(debugInt(cp.debug, "entries"), 0)
    TestSqlConn? c3 := null
    cp.execute |c| { c3 = c }
    verifyNotSame(c1, c3)
    cp.close
  }

  Void testRollbackOnRelease()
  {
    // pool defaults to autoCommit false: every release rolls back
    cp := SqlConnPool { it.uri = "test" }
    verifyEq(cp.autoCommit, false)
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }
    verifyEq(c1.rollbacks, 1)
    verifyEq(c1.autoCommit, false)
    cp.execute |c| {}
    verifyEq(c1.rollbacks, 2)
    cp.close

    // auto-commit pool: no rollback on release
    cp2 := SqlConnPool { it.uri = "test"; it.houseKeepingFreq = 1hr; it.autoCommit = true }
    TestSqlConn? c2 := null
    cp2.execute |c| { c2 = c }
    verifyEq(c2.rollbacks, 0)
    verifyEq(c2.autoCommit, true)

    // callback flips into transaction mode and leaves dangling
    // work: release must rollback before restoring auto-commit,
    // since setAutoCommit(true) would commit the dangling txn
    c2.ops.clear
    cp2.execute |c| { c.autoCommit = false }
    verifyEq(c2.ops, ["autoCommit(false)", "rollback", "autoCommit(true)"])
    cp2.close
  }

  Void testMaxLifetime()
  {
    cp := SqlConnPool { it.uri = "test"; it.houseKeepingFreq = 1hr; it.keepAliveFreq = null; it.linger = 1min; it.maxLifetime = 100ms }
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }

    // keep connection busy so linger never applies
    5.times { Actor.sleep(30ms); cp.execute |c| { verifySame(c, c1) } }

    // retired by age even though never idle
    cp.onHouseKeeping
    verifyEq(c1.isClosed, true)
    verifyEq(debugInt(cp.debug, "entries"), 0)
    cp.close
  }

  Void testInUseNotReaped()
  {
    cp := SqlConnPool { it.uri = "test"; it.houseKeepingFreq = 1hr; it.keepAliveFreq = null; it.linger = 50ms; it.maxLifetime = 50ms }
    ap := ActorPool()
    a := SqlConnPoolTestActor(ap, cp, "a")

    // conn is past linger and maxLifetime but in use; not reaped
    f := execute(a, 200ms)
    Actor.sleep(100ms)
    cp.onHouseKeeping
    verifyEq(debugInt(cp.debug, "entries"), 1)
    verifyEq(debugInt(cp.debug, "inUse"), 1)
    f.get

    // once released and idle it is reaped
    Actor.sleep(60ms)
    cp.onHouseKeeping
    verifyEq(debugInt(cp.debug, "entries"), 0)
    cp.close
  }

  Void testHouseKeepingRuns()
  {
    // houseKeeping runs on the pool's own timer
    cp := SqlConnPool { it.uri = "test"; it.houseKeepingFreq = 50ms; it.keepAliveFreq = null; it.linger = 50ms }
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }
    verifyEq(debugInt(cp.debug, "entries"), 1)

    // idle past linger; reaped without any call to onHouseKeeping
    endTime := Duration.now + 5sec
    while (debugInt(cp.debug, "entries") > 0 && Duration.now < endTime)
      Actor.sleep(20ms)
    verifyEq(debugInt(cp.debug, "entries"), 0)
    verifyEq(c1.isClosed, true)

    // and the timer stops with the pool
    cp.close
    verifyEq(cp.isClosed, true)
  }

  Void testOpenOutsideLock()
  {
    // four slow opens must overlap.  Under the pool lock they would
    // serialize and take at least 4 x openDelay.
    cp := SlowOpenPool { it.uri = "test"; it.houseKeepingFreq = 1hr; it.maxConns = 4 }
    cp.slow.val = true
    ap := ActorPool()
    actors := SqlConnPoolTestActor[,]
    4.times |i| { actors.add(SqlConnPoolTestActor(ap, cp, "a" + i)) }

    t1 := Duration.now
    futures := Future[,]
    actors.each |a| { futures.add(a.send(10ms)) }
    futures.each |f| { f.get(10sec) }
    elapsed := Duration.now - t1

    verifyEq(cp.opens.val, 4)
    verify(elapsed < 900ms, "opens serialized: $elapsed")
    verifyEq(debugInt(cp.debug, "entries"), 4)
    cp.close
  }

  Void testOpenFailureReleasesSlot()
  {
    // the slot is reserved before the open runs, so a failed open must
    // release it
    cp := SlowOpenPool { it.uri = "test"; it.houseKeepingFreq = 1hr; it.maxConns = 1 }

    cp.failNext.val = true
    verifyErr(IOErr#) { cp.execute |c| {} }
    verifyEq(debugInt(cp.debug, "entries"), 0)

    // capacity intact
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }
    verifyNotNull(c1)
    verifyEq(debugInt(cp.debug, "entries"), 1)
    cp.close
  }

  Void testSlowOpenStress()
  {
    // the reservation protocol under contention.  Opens are slow so the
    // window between reserving a slot and filling it is wide enough for
    // other threads to hit it.
    before := TestSqlConn.openCount.val
    cp := SlowOpenPool
    {
      it.uri = "test"
      it.houseKeepingFreq = 1hr
      it.keepAliveFreq = null
      it.maxConns = 3
      it.checkoutTimeout = 10sec
      it.linger = 100ms
      it.openDelay = 30ms
    }
    cp.slow.val = true

    ap := ActorPool()
    actors := SqlConnPoolStressActor[,]
    8.times { actors.add(SqlConnPoolStressActor(ap, cp)) }
    futures := Future[,]
    actors.each |a| { 30.times { futures.add(a.send("go")) } }
    futures.each |f| { verifyEq(f.get(60sec), "ok") }

    // maxConns held and everything is back in the pool
    st := cp.stats
    verify(st.total <= 3, "total=$st.total")
    verifyEq(st.active, 0)
    verifyEq(st.waiting, 0)

    cp.close
    verifyEq(debugInt(cp.debug, "entries"), 0)

    // no connection was left open
    verifyEq(TestSqlConn.openCount.val, before)
  }

  Void testCloseDuringConnect()
  {
    // a connect in flight when the pool closes must not leave a live
    // connection behind
    before := TestSqlConn.openCount.val
    cp := SqlConnPool { it.uri = "test:400"; it.houseKeepingFreq = 1hr; it.keepAliveFreq = null }
    ap := ActorPool()
    a := SqlConnPoolTestActor(ap, cp, "a")
    f := a.send(10ms)

    // close while the connect is still running
    Actor.sleep(100ms)
    cp.close
    verifyErr(Err#) { f.get(10sec) }

    Actor.sleep(600ms)
    verifyEq(debugInt(cp.debug, "entries"), 0)
    verifyEq(TestSqlConn.openCount.val, before)
  }

  Void testCloseDuringKeepalive()
  {
    // a connection held by an in flight keepAlive ping must not survive
    // the close either
    before := TestSqlConn.openCount.val
    cp := SqlConnPool
    {
      it.uri = "test"
      it.houseKeepingFreq = 1hr
      it.linger = 1hr
      it.keepAliveFreq = 50ms
    }
    cp.execute |c| {}
    Actor.sleep(100ms)

    ap := ActorPool()
    pinger := SqlConnPoolBookkeepActor(ap, cp)
    pf := pinger.send("go")
    cp.close
    pf.get(10sec)

    verifyEq(debugInt(cp.debug, "entries"), 0)
    verifyEq(TestSqlConn.openCount.val, before)
  }

  Void testStatsWaitingAndLeaks()
  {
    cp := SqlConnPool
    {
      it.uri = "test"
      it.houseKeepingFreq = 1hr
      it.keepAliveFreq = null
      it.maxConns = 1
      it.checkoutTimeout = 2sec
      it.leakWarn = 50ms
    }
    ap := ActorPool()
    a := SqlConnPoolTestActor(ap, cp, "a")
    b := SqlConnPoolTestActor(ap, cp, "b")

    // a holds the only connection; b blocks
    f := execute(a, 400ms)
    bf := b.send(1ms)
    endTime := Duration.now + 5sec
    while (cp.stats.waiting == 0 && Duration.now < endTime) Actor.sleep(10ms)
    verifyEq(cp.stats.waiting, 1)

    // held past leakWarn
    Actor.sleep(100ms)
    cp.onHouseKeeping
    verifyEq(cp.stats.leakWarnings, 1)

    f.get
    bf.get
    verifyEq(cp.stats.waiting, 0)
    cp.close
  }

  Void testKeepaliveCountsEviction()
  {
    // eviction through the keepAlive path
    cp := SqlConnPool
    {
      it.uri = "test"
      it.houseKeepingFreq = 1hr
      it.linger = 1hr
      it.keepAliveFreq = 50ms
    }
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }
    c1.valid = false

    Actor.sleep(100ms)
    cp.onHouseKeeping
    st := cp.stats
    verifyEq(st.evicted, 1)
    verifyEq(st.retired, 0)
    verifyEq(st.total, 0)
    cp.close
  }

  Void testStats()
  {
    cp := SqlConnPool
    {
      it.uri = "test"
      it.houseKeepingFreq = 1hr
      it.keepAliveFreq = null
      it.maxConns = 1
      it.checkoutTimeout = 100ms
      it.linger = 50ms
    }
    st := cp.stats
    verifyEq(st.total, 0)
    verifyEq(st.checkouts, 0)
    verifyEq(st.opened, 0)
    verifyEq(st.maxConns, 1)

    // one checkout opens one connection, left idle
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }
    st = cp.stats
    verifyEq(st.checkouts, 1)
    verifyEq(st.opened, 1)
    verifyEq(st.total, 1)
    verifyEq(st.active, 0)
    verifyEq(st.idle, 1)

    // held by an actor, so a second caller times out
    ap := ActorPool()
    a := SqlConnPoolTestActor(ap, cp, "a")
    f := execute(a, 400ms)
    verifyEq(cp.stats.active, 1)
    verifyErr(TimeoutErr#) { cp.execute |c| {} }
    verifyEq(cp.stats.checkoutTimeouts, 1)
    f.get

    // closed for age counts as retired
    Actor.sleep(60ms)
    cp.onHouseKeeping
    st = cp.stats
    verifyEq(st.total, 0)
    verifyEq(st.retired, 1)
    verifyEq(st.evicted, 0)

    // a broken connection counts as evicted
    TestSqlConn? c2 := null
    cp.execute |c| { c2 = c }
    verifyErr(IOErr#) { cp.execute |c| { ((TestSqlConn)c).valid = false; throw IOErr("boom") } }
    st = cp.stats
    verifyEq(st.evicted, 1)
    verifyEq(st.retired, 1)
    cp.close
  }

  Void testLeakTrace()
  {
    count := AtomicInt()
    lastTrace := AtomicRef("")
    handler := |LogRec rec|
    {
      if (!rec.msg.contains("held in-use")) return
      count.increment
      lastTrace.val = rec.err?.traceToStr ?: ""
    }
    Log.addHandler(handler)
    try
    {
      // off: no trace on the warning
      cp := SqlConnPool { it.uri = "test"; it.houseKeepingFreq = 1hr; it.leakWarn = 50ms }
      ap := ActorPool()
      a := SqlConnPoolTestActor(ap, cp, "a")
      f := execute(a, 300ms)
      Actor.sleep(100ms)
      cp.onHouseKeeping
      verifyEq(count.val, 1)
      verifyEq(lastTrace.val, "")
      f.get
      cp.close

      // on: the warning carries the checkout stack
      cp2 := SqlConnPool { it.uri = "test"; it.houseKeepingFreq = 1hr; it.leakWarn = 50ms; it.leakTrace = true }
      a2 := SqlConnPoolTestActor(ap, cp2, "a2")
      f2 := execute(a2, 300ms)
      Actor.sleep(100ms)
      cp2.onHouseKeeping
      verifyEq(count.val, 2)
      verify(lastTrace.val.toStr.contains("checked out here"))
      f2.get
      cp2.close
    }
    finally { Log.removeHandler(handler) }
  }

  Void testQueryTimeout()
  {
    // connections inherit the pool's default
    cp := SqlConnPool { it.uri = "test"; it.houseKeepingFreq = 1hr; it.queryTimeout = 45sec }
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }
    verifyEq(c1.queryTimeout, 45sec)
    cp.close

    // null leaves statements unbounded
    cp2 := SqlConnPool { it.uri = "test"; it.houseKeepingFreq = 1hr; it.queryTimeout = null }
    TestSqlConn? c2 := null
    cp2.execute |c| { c2 = c }
    verifyNull(c2.queryTimeout)
    cp2.close
  }

  Void testKeepalive()
  {
    // idle connections are pinged, and a failed ping evicts
    cp := SqlConnPool
    {
      it.uri = "test"
      it.houseKeepingFreq = 1hr
      it.linger = 1hr
      it.keepAliveFreq = 50ms
      it.validationTimeout = 250ms
    }
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }
    verifyNull(c1.lastValidateTimeout)

    // idle past keepAliveFreq: pinged and kept
    Actor.sleep(100ms)
    cp.onHouseKeeping
    verifyEq(c1.lastValidateTimeout, 250ms)
    verifyEq(debugInt(cp.debug, "entries"), 1)
    verifyEq(c1.isClosed, false)

    // dead connection: the next ping evicts it with no checkout involved
    c1.valid = false
    Actor.sleep(60ms)
    cp.onHouseKeeping
    verifyEq(debugInt(cp.debug, "entries"), 0)
    verifyEq(c1.isClosed, true)
    cp.close
  }

  Void testKeepaliveDoesNotDeferLinger()
  {
    // linger measures from the last use; a ping must not defer it
    cp := SqlConnPool
    {
      it.uri = "test"
      it.houseKeepingFreq = 1hr
      it.linger = 300ms
      it.keepAliveFreq = 50ms
    }
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }

    // ping repeatedly across the linger window
    6.times { Actor.sleep(60ms); cp.onHouseKeeping }

    verifyEq(debugInt(cp.debug, "entries"), 0)
    verifyEq(c1.isClosed, true)
    cp.close
  }

  Void testValidateAfterIdle()
  {
    // shorter than the 500ms default
    cp := SqlConnPool
    {
      it.uri = "test"
      it.houseKeepingFreq = 1hr
      it.validateAfterIdle = 50ms
      it.validationTimeout = 250ms
    }
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }
    c1.valid = false

    Actor.sleep(100ms)
    TestSqlConn? c2 := null
    cp.execute |c| { c2 = c }
    verifyNotSame(c1, c2)
    verifyEq(c1.isClosed, true)

    // the pool's validationTimeout reaches the connection
    verifyEq(c1.lastValidateTimeout, 250ms)
    cp.close
  }

  Void testValidateDisabled()
  {
    // null: never ping on checkout, however long the connection sat idle
    cp := SqlConnPool { it.uri = "test"; it.houseKeepingFreq = 1hr; it.validateAfterIdle = null }
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }
    c1.valid = false

    Actor.sleep(600ms)
    TestSqlConn? c2 := null
    cp.execute |c| { c2 = c }
    verifySame(c1, c2)
    verifyNull(c1.lastValidateTimeout)

    // a callback error still validates; that path is not idle gated
    verifyErr(IOErr#) { cp.execute |c| { throw IOErr("boom") } }
    verifyEq(c1.isClosed, true)
    verifyEq(debugInt(cp.debug, "entries"), 0)
    cp.close
  }

  Void testConnectTimeout()
  {
    // the connect takes 400ms and ignores interrupt
    cp := SqlConnPool
    {
      it.uri = "test:400"
      it.houseKeepingFreq = 1hr
      it.maxConns = 1
      it.connectTimeout = 100ms
    }
    before := TestSqlConn.openCount.val

    verifyErr(TimeoutErr#) { cp.execute |c| {} }

    // the slot is released while the connect is still running
    verifyEq(debugInt(cp.debug, "entries"), 0)

    // the abandoned connect lands late; its connection must be closed
    Actor.sleep(600ms)
    verifyEq(TestSqlConn.openCount.val, before)
    cp.close
  }

  Void testOpenFailureClosesConn()
  {
    // onOpen throws after a successful connect, so open must close the
    // connection before propagating
    cp := SlowOpenPool { it.uri = "test"; it.houseKeepingFreq = 1hr }
    before := TestSqlConn.openCount.val
    cp.failNext.val = true
    verifyErr(IOErr#) { cp.execute |c| {} }
    verifyEq(TestSqlConn.openCount.val, before)
    cp.close
  }

  Void testLeakWarn()
  {
    cp := SqlConnPool { it.uri = "test"; it.houseKeepingFreq = 1hr; it.leakWarn = 50ms }
    count := AtomicInt()
    handler := |LogRec rec| { if (rec.msg.contains("held in-use")) count.increment }
    Log.addHandler(handler)
    try
    {
      ap := ActorPool()
      a := SqlConnPoolTestActor(ap, cp, "a")

      // hold past leakWarn; warns once even with multiple checks
      f := execute(a, 200ms)
      Actor.sleep(100ms)
      cp.onHouseKeeping
      cp.onHouseKeeping
      verifyEq(count.val, 1)
      f.get

      // next long checkout warns again
      f = execute(a, 200ms)
      Actor.sleep(100ms)
      cp.onHouseKeeping
      verifyEq(count.val, 2)
      f.get
    }
    finally Log.removeHandler(handler)
    cp.close
  }

  Void testCloseFailFast()
  {
    cp := SqlConnPool { it.uri = "test"; it.houseKeepingFreq = 1hr; it.maxConns = 1; it.checkoutTimeout = 5sec }
    ap := ActorPool()
    a1 := SqlConnPoolTestActor(ap, cp, "a1")
    a2 := SqlConnPoolTestActor(ap, cp, "a2")

    // a1 holds the only conn; a2 blocks waiting for it
    f1 := execute(a1, 300ms)
    f2 := a2.send(1ms)
    Actor.sleep(50ms)

    // close must wake a2 immediately, not wait out the timeout
    start := Duration.now
    cp.close
    verifyErr(Err#) { f2.get }
    verify(Duration.now - start < 2sec)
    f1.get
  }

  Void testStress()
  {
    cp := SqlConnPool { it.uri = "test"; it.houseKeepingFreq = 1hr; it.keepAliveFreq = null; it.maxConns = 3; it.checkoutTimeout = 10sec; it.linger = 100ms }
    ap := ActorPool { it.maxThreads = 8 }
    actors := SqlConnPoolStressActor[,]
    8.times { actors.add(SqlConnPoolStressActor(ap, cp)) }

    // fire away with random sleeps, errors, and broken conns
    futures := Future[,]
    actors.each |a| { 50.times { futures.add(a.send("go")) } }
    futures.each |f| { verifyEq(f.get(30sec), "ok") }

    // pool bounded and fully released, then drains after linger
    verify(debugInt(cp.debug, "entries") <= 3)
    verifyEq(debugInt(cp.debug, "inUse"), 0)
    Actor.sleep(150ms)
    cp.onHouseKeeping
    verifyEq(debugInt(cp.debug, "entries"), 0)
    cp.close
  }

  private Future execute(SqlConnPoolTestActor a, Duration wait)
  {
    f := a.send(wait)
    while (!a.isExecuting) Actor.sleep(10ms)
    return f
  }

  private Void verifyPool(SqlConnPool cp, SqlConnPoolTestActor[] actors, Int inUse, Int idle, Str?[] expect)
  {
    // parse debug to get internal details
    d      := cp.debug
    dIdle  := debugInt(d, "idle")
    dInUse := debugInt(d, "inUse")
    verifyEq(dIdle,  idle,  "idle")
    verifyEq(dInUse, inUse, "inUse")

    actors.each |actor, i|
    {
      e := expect[i]
      a := actor.lastName.val?.toStr ?: ""
      // echo("  ~~ $actor.name | $a ?= $e")
      if (e == null) verifyEq(a, "", actor.name)
      else if (e == "x") verify(a != null, actor.name)
      else verify(a.endsWith("-$e"), actor.name)
    }
  }

  Int debugInt(Str d, Str key)
  {
    line := d.splitLines.find { it.trimStart.startsWith("${key}:") } ?: throw Err(key)
    return line[line.index(":")+1..-1].trim.toInt
  }
}

internal const class SqlConnPoolTestActor : Actor
{
  new make(ActorPool ap, SqlConnPool cp, Str n) : super(ap) { this.cp = cp; name = n }

  const SqlConnPool cp

  const Str name

  const AtomicRef lastName := AtomicRef()

  Bool isExecuting() { isExecutingRef.val }
  const AtomicBool isExecutingRef := AtomicBool()

  override Str toStr() { "$name isExecuting=$isExecuting" }

  override Obj? receive(Obj? msg)
  {
    wait := (Duration)msg
    cp.execute |c|
    {
      isExecutingRef.val = true
      // cp.log.info("SqlConnPoolTestActor.execute $name | $c | $wait")
      lastName.val = c.toStr
      Actor.sleep(wait)
    }
    isExecutingRef.val = false
    return null
  }

}

internal const class SqlConnPoolStressActor : Actor
{
  new make(ActorPool ap, SqlConnPool cp) : super(ap) { this.cp = cp }

  const SqlConnPool cp

  override Obj? receive(Obj? msg)
  {
    try
    {
      cp.execute |c|
      {
        r := Int.random(0..9)
        if (r > 6) Actor.sleep(1ms * (r-6).toFloat)
        if (r == 0) { ((TestSqlConn)c).valid = false; throw Err("chaos") }
      }
    }
    catch (Err e) { if (e.msg != "chaos") throw e }
    return "ok"
  }
}


**************************************************************************
** SlowOpenPool
**************************************************************************

** Pool whose onOpen can be made slow or made to fail.
internal const class SlowOpenPool : SqlConnPool
{
  new make(|This| f) : super(f) {}

  const Duration openDelay := 300ms
  const AtomicBool slow := AtomicBool(false)
  const AtomicBool failNext := AtomicBool(false)
  const AtomicInt opens := AtomicInt()

  protected override Void onOpen(SqlConn c)
  {
    opens.increment
    if (failNext.compareAndSet(true, false)) throw IOErr("open failed")
    if (slow.val) Actor.sleep(openDelay)
  }
}

**************************************************************************
** SqlConnPoolBookkeepActor
**************************************************************************

** Runs one houseKeeping pass off the test thread, so the pool can be
** closed while a keepAlive ping is in flight.
internal const class SqlConnPoolBookkeepActor : Actor
{
  new make(ActorPool ap, SqlConnPool cp) : super(ap) { this.cp = cp }

  const SqlConnPool cp

  override Obj? receive(Obj? msg)
  {
    cp.onHouseKeeping
    return "ok"
  }
}

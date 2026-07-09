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
      it.timeout  = 300ms
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
    cp.checkLinger
    verifyPool(cp, actors, 0, 0, [null, null, null, null])

    // run one quickly
    a3.send(1ms).get
    verifyPool(cp, actors, 0, 1, [null, null, "2", null])

    // verify timeouts
    reset()
    f1 = execute(a1, cp.timeout+40ms)
    f2 = execute(a2, cp.timeout+40ms)
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
    cp2 := SqlConnPool { it.uri = "test"; it.autoCommit = true }
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
    cp := SqlConnPool { it.uri = "test"; it.linger = 1min; it.maxLifetime = 100ms }
    TestSqlConn? c1 := null
    cp.execute |c| { c1 = c }

    // keep connection busy so linger never applies
    5.times { Actor.sleep(30ms); cp.execute |c| { verifySame(c, c1) } }

    // retired by age even though never idle
    cp.checkLinger
    verifyEq(c1.isClosed, true)
    verifyEq(debugInt(cp.debug, "entries"), 0)
    cp.close
  }

  Void testInUseNotReaped()
  {
    cp := SqlConnPool { it.uri = "test"; it.linger = 50ms; it.maxLifetime = 50ms }
    ap := ActorPool()
    a := SqlConnPoolTestActor(ap, cp, "a")

    // conn is past linger and maxLifetime but in use; not reaped
    f := execute(a, 200ms)
    Actor.sleep(100ms)
    cp.checkLinger
    verifyEq(debugInt(cp.debug, "entries"), 1)
    verifyEq(debugInt(cp.debug, "inUse"), 1)
    f.get

    // once released and idle it is reaped
    Actor.sleep(60ms)
    cp.checkLinger
    verifyEq(debugInt(cp.debug, "entries"), 0)
    cp.close
  }

  Void testLeakWarn()
  {
    cp := SqlConnPool { it.uri = "test"; it.leakWarn = 50ms }
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
      cp.checkLinger
      cp.checkLinger
      verifyEq(count.val, 1)
      f.get

      // next long checkout warns again
      f = execute(a, 200ms)
      Actor.sleep(100ms)
      cp.checkLinger
      verifyEq(count.val, 2)
      f.get
    }
    finally Log.removeHandler(handler)
    cp.close
  }

  Void testCloseFailFast()
  {
    cp := SqlConnPool { it.uri = "test"; it.maxConns = 1; it.timeout = 5sec }
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
    cp := SqlConnPool { it.uri = "test"; it.maxConns = 3; it.timeout = 10sec; it.linger = 100ms }
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
    cp.checkLinger
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


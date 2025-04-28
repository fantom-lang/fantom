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


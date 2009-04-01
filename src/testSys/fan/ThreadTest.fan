//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 07  Brian Frank  Creation
//

**
** ThreadTest
**
class ThreadTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  Void testIdentity()
  {
    // make
    a := Thread.make("testSys.foo")
    b := Thread.make("testSys.bar")
    c := Thread.make
    d := Thread.make
    verifyErr(ArgErr#) |,|  { Thread.make("testSys.foo") }
    verifyErr(ArgErr#) |,|  { Thread.make(c.name) }
    verifyErr(NameErr#) |,| { Thread.make("a b") }

    // name
    verifyEq(a.name, "testSys.foo")
    verifyEq(b.name, "testSys.bar")
    verify(c.name != d.name)

    // uri
// TODO
//    verifySame("/sys/threads/$a.name".toUri.resolve.obj, a)
//    verifySame("/sys/threads/$b.name".toUri.resolve.obj, b)

    // equals
    verify(a == a)
    verify(a != b)

    // hash
    verifyEq(a.hash, a.name.hash)
    verifyEq(b.hash, b.name.hash)

    // toStr
    verifyEq(a.toStr, "testSys.foo")
    verifyEq(d.name, d.toStr)

    // find
    verifySame(Thread.find("testSys.foo"), a)
    verifySame(Thread.find(d.name), d)
    verifyEq(Thread.find("testSys.forget it", false), null)
    verifyErr(UnknownServiceErr#) |,| { Thread.find("testSys.forget it") }
    verifyErr(UnknownServiceErr#) |,| { Thread.find("testSys.forget it", true) }

    // list
    verify(Thread.list.isRO)
    verifyEq(Thread.list.type, Thread[]#)
    verify(Thread.list.contains(a))
    verify(Thread.list.contains(b))
    verify(Thread.list.contains(c))
    verify(Thread.list.contains(d))

    // current
    verifyEq(Thread.current.name, "FantMain")
    verifyEq(Thread.current.isNew, false)
    verifyEq(Thread.current.isRunning, true)
    verifyEq(Thread.current.isDead, false)
  }

//////////////////////////////////////////////////////////////////////////
// Count
//////////////////////////////////////////////////////////////////////////

  Void testCount()
  {
    // create it
    t := ThreadCount.make
    verifyEq(t.name, "ThreadCount")
    verifyEq(t.isNew, true)
    verifyEq(t.isRunning, false)
    verifyEq(t.isDead, false)
    verifySame(Thread.find("ThreadCount"), t)
    verifyErr(ArgErr#) |,| { ThreadCount.make }

    // stop it
    t.stop
    verifyEq(t.isNew, false)
    verifyEq(t.isRunning, false)
    verifyEq(t.isDead, true)
    verifyEq(Thread.find("ThreadCount", false), null)
    old := t

    // create new one
    t = ThreadCount.make
    verify(t !== old)
    verifyEq(t.name, "ThreadCount")
    verifyEq(t.isNew, true)

    // start it
    t.start
    verifyEq(t.isNew, false)
    verifyEq(t.isRunning, true)
    verifyEq(t.isDead, false)
    verifySame(Thread.find("ThreadCount"), t)
    verifyErr(Err#) |,| { t.start }

    // join until counter done
    Thread.sleep(500ms)
    verifyEq(t.isNew, false)
    verifyEq(t.isRunning, false)
    verifyEq(t.isDead, true)
    verifyEq(Thread.find("ThreadCount", false), null)
    verifyErr(Err#) |,| { t.start }
    t.join  // ignored
    t.stop  // ignored
  }

//////////////////////////////////////////////////////////////////////////
// Messaging
//////////////////////////////////////////////////////////////////////////

  Void testMessaging()
  {
    // verify run is checked for immutable
    verifyErr(NotImmutableErr#) |,|
    {
      Thread.make("testSys.testMessaging") |Thread thread| { fail }
    }

    // verify this thread can't call t's loop
    t := Thread("testSys.testMessagingBadLoop", &runMessaging).start
    verifyErr(Err#) |,| { t.loop |Obj m->Obj| { return m } }

    // create fresh thread, which takes an Int msg and doubles it
    t = Thread("testSys.testMessaging", &runMessaging).start

    // send some sync messages
    10.times |Int i|
    {
      Int r := t.sendSync(i)
      verifyEq(r, i*2)
    }

    // send serialized req/res
    Msg req := Msg { a="a"; b="b" }
    Msg res := t.sendSync(req)
    verifyEq(req, Msg { a="a"; b="b" })
    verifyEq(res, Msg { a="(a)"; b="(b)"; c="(null)" })

    // verify exception raised to me
    verifyErr(IOErr#) |,| { t.sendSync("throw") }

    // verify messages must immutable
    verifyErr(IOErr#) |,| { t.sendSync(this) }
    verifyErr(IOErr#) |,| { t.sendAsync(this) }
    verifyErr(IOErr#) |,| { t.sendSync("mutable") }
    //t.sendAsync("mutable")
    //t.sendAsync("throw")
    t.sendSync("die")

    verify(t.isDead)
  }

  static Void runMessaging(Thread t)
  {
    t.loop |Obj? msg->Obj?|
    {
      if (msg is Int) return (Int)msg * 2

      if (msg is Msg)
      {
        res := msg as Msg
        res.a = "($res.a)"
        res.b = "($res.b)"
        res.c = "($res.c)"
        return res
      }

      switch (msg)
      {
        case "throw":    throw IOErr.make()
        case "mutable":  return ThreadTest.make
        case "die":      t.kill; return null
      }

      return null
    }
  }

//////////////////////////////////////////////////////////////////////////
// Join
//////////////////////////////////////////////////////////////////////////

  Void testJoin()
  {
    t := Thread.make(null, &runJoin("six")).start
    verifyEq(t.join(2sec), 6)
    verifyEq(t.join(2sec), null)

    t = Thread.make(null, &runJoin("mutable")).start
    verifyEq(t.join(2sec)->readAllStr, "abc")
    verifyEq(t.join(2sec), null)
  }

  static Obj runJoin(Str mode)
  {
    switch (mode)
    {
      case "six":     return 6
      case "mutable": return Buf.make.print("abc").flip
      default:        throw UnsupportedErr.make
    }
  }

//////////////////////////////////////////////////////////////////////////
// StopKill
//////////////////////////////////////////////////////////////////////////

  Void testStopKill()
  {
    a := Thread(null, &runStopKill).start
    b := Thread(null, &runStopKill).start

    // fire off a bunch of messages accumlated by thread
    1000.times |Int i| { a.sendAsync(i); b.sendAsync(i) }

    // stop a, kill b
    a.stop.stop.stop
    b.kill

    // a should have accumulated all 1000, b might or might not since it was killed
    Int aNum := a.join->size
    verifyEq(aNum, 1000)

    Int? bNum := b.join?->size
    verifyEq(bNum <= 1000, true)

    verifyEq(a.isDead, true)
    verifyEq(b.isDead, true)
  }

  static Obj runStopKill(Thread t)
  {
    acc := Obj[,]
    try
    {
      Thread.sleep(50ms)
      t.loop |Obj msg| { acc.add(msg) }
    }
    catch (InterruptedErr e) {}
    return acc
  }

//////////////////////////////////////////////////////////////////////////
// Sync Kill
//////////////////////////////////////////////////////////////////////////

  Void testSyncKill()
  {
    verifySyncKill(true)
    verifySyncKill(false)
  }

  Void verifySyncKill(Bool explicitStop)
  {
    x := Thread(null, &runSyncKillMain).start
    a := Thread(null, &runSyncKill(x)).start
    b := Thread(null, &runSyncKill(x)).start
    c := Thread(null, &runSyncKill(x)).start

    if (explicitStop)
    {
      Thread.sleep(50ms)
      x.kill
    }
    else
    {
      x.join
    }

    t1 := Duration.now
    verify(a.join is InterruptedErr)
    verify(b.join is InterruptedErr)
    verify(c.join is InterruptedErr)
    t2 := Duration.now
    verify(t2-t1 < 50ms)
  }

  static Void runSyncKillMain(Thread t)
  {
    try
    {
      Thread.sleep(100ms)
    }
    catch (InterruptedErr e)
    {
    }
  }

  static Obj? runSyncKill(Thread main, Thread t)
  {
    try
    {
      main.sendSync("x")
      return null
    }
    catch (Err e)
    {
      return e
    }
  }

//////////////////////////////////////////////////////////////////////////
// OnCallbacks
//////////////////////////////////////////////////////////////////////////

  Void testOnCallbacks()
  {
    Sys.ns.create(`/testSys/onStart`, false)
    Sys.ns.create(`/testSys/run`, false)
    Sys.ns.create(`/testSys/onStop`, false)
    try
    {
      3.times |Int mode|
      {
        t := ThreadCallbacks.make(mode)

        t.start
        Thread.sleep(20ms)
        verifyEq(Sys.ns[`/testSys/onStart`], true)

        if (mode.isOdd) t.kill; else t.stop
        Thread.sleep(20ms)
        verifyEq(Sys.ns[`/testSys/onStart`], true)
        verifyEq(Sys.ns[`/testSys/run`],     mode >= 1)
        verifyEq(Sys.ns[`/testSys/onStop`],  true)
      }
    }
    finally
    {
      Sys.ns.delete(`/testSys/onStart`)
      Sys.ns.delete(`/testSys/run`)
      Sys.ns.delete(`/testSys/onStop`)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Timer
//////////////////////////////////////////////////////////////////////////

  Void testTimer()
  {
    try
    {
      x := Thread.make(null, &runTimerTest)
      x.start.join
      Thread.sleep(50ms)
      Obj[][] results := Sys.ns[`/testSys/timer`]
      verifyTimer(results[0], 100ms, "100ms")
      verifyTimer(results[1], 100ms, "100ms repeat")
      verifyTimer(results[2], 200ms, "200ms")
      verifyTimer(results[3], 200ms, "100ms repeat")
      verifyTimer(results[4], 300ms, "300ms")
      verifyTimer(results[5], 400ms, "400ms")
      verifyTimer(results[6], 500ms, "500ms")
    }
    finally
    {
      try { Sys.ns.delete(`/testSys/timer`) } catch {}
    }
  }

  Void verifyTimer(Obj[] results, Duration d, Str msg)
  {
    Duration a := results[0]
    verify(a.ticks.minus(d.ticks).abs < 20ms.ticks)
    verifyEq(results[1], msg)
  }

  static Obj? runTimerTest(Thread t)
  {
    t.sendLater(100ms, "100ms")
    t.sendLater(200ms, "200ms")
    t.sendLater(300ms, "300ms")
    t.sendLater(400ms, "400ms")
    ticket := t.sendLater(100ms, "100ms repeat", true)
    t.sendLater(500ms, "500ms")

    start := Duration.now
    results := [,]
    t.loop |Obj msg|
    {
      results.add([Duration.now-start, msg])
      if (msg == "300ms") t.cancelLater(ticket)
      if (msg == "500ms") t.stop
    }

    Sys.ns.create(`/testSys/timer`, results)
    return null
  }

//////////////////////////////////////////////////////////////////////////
// Loop Coalescing
//////////////////////////////////////////////////////////////////////////

  Void testLoopCoalescing()
  {
    try
    {
      x := Thread.make(null, &runCoalesce)
      x.start
      Thread.sleep(100ms)
      x.sendAsync(100ms)
      x.sendAsync("one")
      x.sendAsync("two")
      x.sendAsync("one")
      x.sendAsync("two")
      x.sendAsync("three")
      x.sendAsync("four")
      x.sendAsync("one")
      x.sendAsync("four")
      x.sendAsync("three")
      x.sendAsync(null)
      x.join
      Thread.sleep(100ms)
      Obj[] results := Sys.ns[`/testSys/coalesce`]
      verifyEq(results, ["one", "two", "three", "four"])
    }
    finally
    {
      try { Sys.ns.delete(`/testSys/coalesce`) } catch {}
    }
  }

  static Void runCoalesce(Thread t)
  {
    msgs := Str[,]
    t.loopCoalescing(null, null) |Obj? msg|
    {
      if (msg == null) { t.stop; return }
      if (msg is Duration) { Thread.sleep(msg); return }
      msgs.add(msg)
    }
    Sys.ns.create(`/testSys/coalesce`, msgs)
  }

  Void testLoopCoalescingFuncs()
  {
    try
    {
      x := Thread.make(null, &runCoalesceFuncs)
      x.start
      Thread.sleep(100ms)
      x.sendAsync(100ms)
      x.sendAsync(["a", 2])
      x.sendAsync(["b", 10])
      x.sendAsync(["a", 3])
      x.sendAsync(["a", 4])
      x.sendAsync(["b", 20])
      x.sendAsync(["c", 100])
      x.sendAsync(["a", 5])
      x.sendAsync(["c", 200])
      x.sendAsync(null)
      x.join
      Thread.sleep(100ms)
      Obj[] results := Sys.ns[`/testSys/coalesce`]
      verifyEq(results,
        [["a", 2, 3, 4, 5],
         ["b", 10, 20],
         ["c", 100, 200]])
    }
    finally
    {
      try { Sys.ns.delete(`/testSys/coalesce`) } catch {}
    }
  }

  static Void runCoalesceFuncs(Thread t)
  {
    msgs := Obj[][,]
    toKey := |Obj? msg->Obj?| { msg is List ? msg->get(0): null }
    coalesce := |Obj[] a, Obj[] b->Obj| { Obj[,].add(a[0]).addAll(a[1..-1]).addAll(b[1..-1]) }
    t.loopCoalescing(toKey, coalesce) |Obj? msg|
    {
      if (msg == null) { t.stop; return }
      if (msg is Duration) { Thread.sleep(msg); return }
      msgs.add(msg)
    }
    Sys.ns.create(`/testSys/coalesce`, msgs)
  }

//////////////////////////////////////////////////////////////////////////
// Thread Locals
//////////////////////////////////////////////////////////////////////////

  Void testLocals()
  {
    Actor.locals["testSys.x"] = "main"
    verifyEq(Actor.locals["testSys.x"], "main")

    a := Thread.make(null, &runLocal("alpha")).start
    b := Thread.make(null, &runLocal("beta")).start
    c := Thread.make(null, &runLocal("gamma")).start

    verifyEq(a.join, "alpha")
    verifyEq(b.join, "beta")
    verifyEq(c.join, "gamma")
    verifyEq(Actor.locals["testSys.x"], "main")
  }

  static Obj runLocal(Str val)
  {
    r := val
    3.times |,|
    {
      Actor.locals["testSys.x"] = val
      if (Actor.locals["testSys.x"] != val)
      {
        Err.make.trace
        r = "bad bad bad"
      }
      Thread.sleep(10ms)
    }
    return r
  }

//////////////////////////////////////////////////////////////////////////
// Trace
//////////////////////////////////////////////////////////////////////////

  Void testTrace()
  {
    buf := Buf.make

    // trace new and dead thread
    t := Thread.make(null)
    t.trace(buf.out)
    t.stop
    t.trace(buf.out)
    verifyEq(buf.size, 0)

    // trace current
    traceA(buf.out)

    lines := buf.flip.readAllLines
    start := lines.find |Str s->Bool| { return s.contains("traceB") }
    verify(start != null)
    i := lines.index(start)
    verify(lines[i+0].contains("testSys::ThreadTest.traceB"))
    verify(lines[i+1].contains("testSys::ThreadTest.traceA"))
    verify(lines[i+2].contains("testSys::ThreadTest.testTrace"))
  }

  Void traceA(OutStream out) { traceB(out) }
  Void traceB(OutStream out) { Thread.current.trace(out) }

//////////////////////////////////////////////////////////////////////////
// Service
//////////////////////////////////////////////////////////////////////////

/* Moved to ServiceTest
  Void testService()
  {
    n := ThreadCount.make
    a := TestService.make
    b := TestService.make
    c := TestService.make
    d := TestService.make

    verifyService(ThreadCount#,  null)
    verifyService(TestService#,  a)
    verifyService(ATestService#, a)
    verifyService(MTestService#, a)

    n.start
    a.start.stop.join

    verifyService(TestService#,  b)
    verifyService(ATestService#, b)
    verifyService(MTestService#, b)

    c.start.stop.join

    verifyService(TestService#,  b)
    verifyService(ATestService#, b)
    verifyService(MTestService#, b)

    b.start.stop.join

    verifyService(TestService#,  d)
    verifyService(ATestService#, d)
    verifyService(MTestService#, d)

    d.start.stop.join

    verifyService(TestService#,  null)
    verifyService(ATestService#, null)
    verifyService(MTestService#, null)
    verifyService(ThreadCount#,  null)
  }

  Void verifyService(Type t, Thread? s)
  {
    uri := "/sys/service/$t.qname".toUri
    if (s == null)
    {
      verifyEq(Thread.findService(t, false), null)
      verifyErr(UnknownThreadErr#) |,| { Thread.findService(t) }
      verifyErr(UnknownThreadErr#) |,| { Thread.findService(t, true) }

      verifyEq(Sys.ns.get(uri, false), null)
      verifyErr(UnresolvedErr#) |,| { Sys.ns.get(uri) }
      verifyErr(UnresolvedErr#) |,| { Sys.ns.get(uri, true) }
    }
    else
    {
      verifySame(Thread.findService(t), s)
      verifySame(Thread.findService(t, false), s)
      verifySame(Thread.findService(t, true), s)

      verifySame(Sys.ns[uri], s)
      verifySame(Sys.ns.get(uri, false), s)
      verifySame(Sys.ns.get(uri, true), s)
    }
  }
*/

}

**************************************************************************
** ThreadCount
**************************************************************************

const class ThreadCount : Thread
{
  new make() : super("ThreadCount") {}

  override Obj? run()
  {
    3.times |Int c| { sleep(100ms) }
    return null
  }
}

**************************************************************************
** Msg
**************************************************************************

@serializable
class Msg
{
  override Int hash() { return toStr.hash }
  override Bool equals(Obj? obj) { return obj is Msg && obj.toStr == toStr }
  override Str toStr() { return "a=$a b=$b c=$c" }
  Str a
  Str b
  Str c
}

**************************************************************************
** ThreadCallbacks
**************************************************************************

const class ThreadCallbacks : Thread
{
  new make(Int mode) : super(null) { this.mode = mode }

  override Obj? run()
  {
    Sys.ns.put(`/testSys/run`, true)
    if (mode == 1) ThreadTest.make.fail
    loop |Obj? req->Obj?|
    {
      echo("  req: $req")
      return null
    }
    return null
  }

  override Void onStart()
  {
    Sys.ns.put(`/testSys/onStart`, true)
    if (mode == 0) ThreadTest.make.fail
  }

  override Void onStop()
  {
    Sys.ns.put(`/testSys/onStop`, true)
    if (mode == 2) ThreadTest.make.fail
  }

  const Int mode
}

**************************************************************************
** TestService
**************************************************************************

/* TODO Moved to ServiceTest
mixin MTestService {}
const class ATestService : Thread { new make() : super() {} }
const class TestService : ATestService, MTestService
{
  override Bool isService() { return true }
  override Obj? run() { while (isRunning) sleep(20ms); return null }
}
*/
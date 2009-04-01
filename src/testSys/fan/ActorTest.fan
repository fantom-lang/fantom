//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 07  Brian Frank  Creation
//   26 Mar 09  Brian Frank  Split from old ThreadTest
//

**
** ActorTest
**
class ActorTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Setup/Teardown
//////////////////////////////////////////////////////////////////////////

  ActorGroup group

  override Void setup() { group = ActorGroup() }

  override Void teardown() { group.kill }

//////////////////////////////////////////////////////////////////////////
// Make
//////////////////////////////////////////////////////////////////////////

  Void testMake()
  {
    mutable := |Context cx, Obj? msg->Obj?| { fail; return null }
    verifyErr(ArgErr#) |,| { Actor(group) }
    verifyErr(NotImmutableErr#) |,| { Actor(group, mutable) }
  }

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    // create actor which increments an Int
    g := ActorGroup();
    a := Actor(group, &incr)

    // verify basic identity
    verifyEq(g.type, ActorGroup#)
    verifyEq(a.type, Actor#)
    verifySame(a.group, group)
    verifyEq(g.isStopped, false)
    verifyEq(g.isDone, false)

    // fire off a bunch of Ints and verify
    futures := Future[,]
    100.times |Int i| { futures.add(a.send(i)) }
    futures.each |Future f, Int i|
    {
      verifyEq(f.type, Future#)
      verifyEq(f.get, i+1)
      verify(f.isDone)
      verify(!f.isCancelled)
      verifyEq(f.get, i+1)
    }
  }

  static Int incr(Context cx, Int msg)
  {
    if (cx.type != Context#) echo("ERROR: Context.type hosed")
    return msg+1
  }

//////////////////////////////////////////////////////////////////////////
// Ordering
//////////////////////////////////////////////////////////////////////////

  Void testOrdering()
  {
    // build a bunch actors
    actors := Actor[,]
    200.times |,| { actors.add(Actor(group, &order)) }

    // randomly send increasing ints to the actors
    100_000.times |Int i| { actors[Int.random(0...actors.size)].send(i) }

    // get the results
    futures := Future[,]
    actors.each |Actor a, Int i| { futures.add(a.send("result-$i")) }

    futures.each |Future f, Int i|
    {
      Int[] r := f.get
      r.each |Int v, Int j| { if (j > 0) verify(v > r[j-1]) }
    }
  }

  static Obj? order(Context cx, Obj msg)
  {
    Int[]? r := cx.get("foo")
    if (r == null) cx.set("foo", r = Int[,])
    if (msg.toStr.startsWith("result")) return r
    r.add(msg)
    return null
  }

//////////////////////////////////////////////////////////////////////////
// Messaging
//////////////////////////////////////////////////////////////////////////

  Void testMessaging()
  {
    a := Actor(group, &messaging)

    // const
    f := a.send("const")
    verifySame(f.get, a)
    verifySame(f.get, a)
    verify(f.isDone)

    // serializable
    f = a.send("serial")
    verifyEq(f.get, SerA { i = 123_321 })
    verifyEq(f.get, SerA { i = 123_321 })
    verifyNotSame(f.get, f.get)
    verify(f.isDone)

    // non-serializable mutables
    verifyErr(IOErr#) |,| { a.send(this) }
    verifyErr(IOErr#) |,| { a.send("mutable").get }

    // receive raises error
    f = a.send("throw")
    verifyErr(UnknownServiceErr#) |,| { f.get }
    verifyErr(UnknownServiceErr#) |,| { f.get }
    verify(f.isDone)
  }

  static Obj? messaging(Context cx, Str msg)
  {
    switch (msg)
    {
      case "const":   return cx.actor
      case "serial":  return SerA { i = 123_321 }
      case "throw":   throw UnknownServiceErr()
      case "mutable": return cx
      default: return "?"
    }
  }

//////////////////////////////////////////////////////////////////////////
// Timeout/Cancel
//////////////////////////////////////////////////////////////////////////

  Void testTimeoutCancel()
  {
    a := Actor(group, &sleep)
    f := a.send(1sec)

    // get with timeout
    t1 := Duration.now
    verifyErr(TimeoutErr#) |,| { f.get(50ms) }
    t2 := Duration.now
    verify(t2-t1 < 70ms, (t2-t1).toLocale)

    // launch an actor to cancel the future
    Actor(group, &cancel).send(f)

    // block on future until canceled
    verifyErr(CancelledErr#) |,| { f.get }
    verifyErr(CancelledErr#) |,| { f.get }
    verify(f.isDone)
    verify(f.isCancelled)
  }

  static Obj? sleep(Context cx, Obj? msg)
  {
    if (msg is Duration) Thread.sleep(msg)
    return msg
  }

  static Obj? cancel(Context cx, Future f)
  {
    Thread.sleep(20ms)
    f.cancel
    return f
  }

//////////////////////////////////////////////////////////////////////////
// Stop
//////////////////////////////////////////////////////////////////////////

  Void testStop()
  {
    // launch a bunch of threads which sleep for a random time
    actors := Actor[,]
    durs := Duration[,]
    futures := Future[,]
    scheduled := Future[,]
    20.times |Int i|
    {
      actor := Actor(group, &sleep)
      actors.add(actor)

      // send some dummy messages
      Int.random(100...1000).times |Int j| { actor.send(j) }

      // send sleep duration 0 to 300ms
      dur := 1ms * Int.random(0...300).toFloat
      if (i == 0) dur = 300ms
      durs.add(dur)
      futures.add(actor.send(dur))

      // schedule some messages in future well after we stop
      3.times |Int j| { scheduled.add(actor.sendLater(10sec + 1sec * j.toFloat, j)) }
    }

    // still running
    verifyEq(group.isStopped, false)
    verifyEq(group.isDone, false)

    // join with timeout
    t1 := Duration.now
    verifyErr(TimeoutErr#) |,| { group.stop.join(100ms) }
    t2 := Duration.now
    verify(t2 - t1 <= 120ms)
    verifyEq(group.isStopped, true)
    verifyEq(group.isDone, false)

    // verify can't send or schedule anymore
    actors.each |Actor a|
    {
      verifyErr(Err#) |,| { a.send(10sec) }
      verifyErr(Err#) |,| { a.sendLater(1sec, 1sec) }
    }

    // stop again, join with no timeout
    group.stop.join
    t2 = Duration.now
    verify(t2 - t1 <= 340ms, (t2-t1).toLocale)
    verifyEq(group.isStopped, true)
    verifyEq(group.isDone, true)

    // verify all futures have completed
    futures.each |Future f| { verify(f.isDone) }
    futures.each |Future f, Int i| { verifyEq(f.get, durs[i]) }

    // verify all scheduled messages were canceled
    verifyAllCancelled(scheduled)
  }

  Void verifyAllCancelled(Future[] futures)
  {
    futures.each |Future f|
    {
      verify(f.isDone)
      verify(f.isCancelled)
      verifyErr(CancelledErr#) |,| { f.get }
      verifyErr(CancelledErr#) |,| { f.get(200ms) }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Kill
//////////////////////////////////////////////////////////////////////////

  Void testKill()
  {
    // spawn off a bunch of actors and sleep messages
    futures := Future[,]
    durs := Duration[,]
    scheduled := Future[,]
    200.times |,|
    {
      actor := Actor(group, &sleep)

      // send 6x 0ms - 50ms, max 600ms
      6.times |Int i|
      {
        dur := 1ms * Int.random(0...50).toFloat
        futures.add(actor.send(dur))
        durs.add(dur)
      }

      // schedule some messages in future well after we stop
      scheduled.add(actor.sendLater(3sec, actor))
    }

    verifyEq(group.isStopped, false)
    verifyEq(group.isDone, false)

    // kill
    t1 := Duration.now
    group.kill
    verifyEq(group.isStopped, true)

    // verify can't send anymore
    verifyErr(Err#) |,| { Actor(group, &sleep).send(10sec) }

    // join
    group.join
    t2 := Duration.now
    verify(t2-t1 < 50ms, (t2-t1).toLocale)
    verifyEq(group.isStopped, true)
    verifyEq(group.isDone, true)

    // verify all futures must now be done one of three ways:
    //  1) completed successfully
    //  2) were interrupted (if running during kill)
    //  3) were cancelled (if pending)
    futures.each |Future f, Int i| { verify(f.isDone, "$i ${durs[i]}") }
    futures.each |Future f, Int i|
    {
      // each future either
      if (f.isCancelled)
      {
        verifyErr(CancelledErr#) |,| { f.get }
      }
      else
      {
        try
          verifyEq(f.get, durs[i])
        catch (InterruptedErr e)
          verifyErr(InterruptedErr#) |,| { f.get }
      }
    }

    // verify all scheduled messages were canceled
    verifyAllCancelled(scheduled)
  }

//////////////////////////////////////////////////////////////////////////
// Later
//////////////////////////////////////////////////////////////////////////

  Void testLater()
  {
    // warm up a threads with dummy requests
    5.times |,| { Actor(group, &returnNow).sendLater(10ms, "dummy") }

    start := Duration.now
    x100 := Actor(group, &returnNow).sendLater(100ms, null)
    x150 := Actor(group, &returnNow).sendLater(150ms, null)
    x200 := Actor(group, &returnNow).sendLater(200ms, null)
    x250 := Actor(group, &returnNow).sendLater(250ms, null)
    x300 := Actor(group, &returnNow).sendLater(300ms, null)
    verifyLater(start, x100, 100ms)
    verifyLater(start, x150, 150ms)
    verifyLater(start, x200, 200ms)
    verifyLater(start, x250, 250ms)
    verifyLater(start, x300, 300ms)

    start = Duration.now
    x100 = Actor(group, &returnNow).sendLater(100ms, null)
    verifyLater(start, x100, 100ms)

    start = Duration.now
    x300 = Actor(group, &returnNow).sendLater(300ms, null)
    x200 = Actor(group, &returnNow).sendLater(200ms, null)
    x100 = Actor(group, &returnNow).sendLater(100ms, null)
    x150 = Actor(group, &returnNow).sendLater(150ms, null)
    x250 = Actor(group, &returnNow).sendLater(250ms, null)
    verifyLater(start, x100, 100ms)
    verifyLater(start, x150, 150ms)
    verifyLater(start, x200, 200ms)
    verifyLater(start, x250, 250ms)
    verifyLater(start, x300, 300ms)
  }

  Void testLaterRand()
  {
    // warm up a threads with dummy requests
    5.times |,| { Actor(group, &returnNow).sendLater(10ms, "dummy") }

    // schedule a bunch of actors and messages with random times
    start := Duration.now
    actors := Actor[,]
    futures := Future[,]
    durs := Duration?[,]
    5.times |,|
    {
      a := Actor(group, &returnNow)
      10.times |,|
      {
        // schedule something randonly between 0ms and 1sec
        Duration? dur := 1ms * Int.random(0...1000).toFloat
        f := a.sendLater(dur, dur)

        // cancel some anything over 500ms
        if (dur > 500ms) { f.cancel; dur = null }

        durs.add(dur)
        futures.add(f)
      }
    }

    // verify cancellation or that scheduling was reasonably accurate
    futures.each |Future f, Int i| { verifyLater(start, f, durs[i], 100ms) }
  }

  Void verifyLater(Duration start, Future f, Duration? expected, Duration tolerance := 20ms)
  {
    if (expected == null)
    {
      verify(f.isCancelled)
      verify(f.isDone)
      verifyErr(CancelledErr#) |,| { f.get }
    }
    else
    {
      Duration actual := (Duration)f.get(3sec) - start
      diff := (expected - actual).abs
      // echo("$expected.toLocale != $actual.toLocale ($diff.toLocale)")
      verify(diff < tolerance, "$expected.toLocale != $actual.toLocale ($diff.toLocale)")
    }
  }

  static Obj? returnNow(Context cx, Obj? msg) { Duration.now }

//////////////////////////////////////////////////////////////////////////
// Coalescing (no funcs)
//////////////////////////////////////////////////////////////////////////

  Void testCoalescing()
  {
    a := Actor.makeCoalescing(group, null, null, &coalesce)
    fstart  := a.send(100ms)

    f1s := Future[,]
    f2s := Future[,]
    f3s := Future[,]
    f4s := Future[,]
    ferr := Future[,]
    fcancel := Future[,]

    f1s.add(a.send("one"))
    fcancel.add(a.send("cancel"))
    f2s.add(a.send("two"))
    f1s.add(a.send("one"))
    f2s.add(a.send("two"))
    f3s.add(a.send("three"))
    ferr.add(a.send("throw"))
    f4s.add(a.send("four"))
    fcancel.add(a.send("cancel"))
    f1s.add(a.send("one"))
    ferr.add(a.send("throw"))
    f4s.add(a.send("four"))
    fcancel.add(a.send("cancel"))
    fcancel.add(a.send("cancel"))
    f3s.add(a.send("three"))
    ferr.add(a.send("throw"))
    ferr.add(a.send("throw"))

    fcancel.first.cancel

    a.send(10ms).get(2sec) // wait until completed

    verifyAllSame(f1s)
    verifyAllSame(f2s)
    verifyAllSame(f3s)
    verifyAllSame(f4s)
    verifyAllSame(ferr)
    verifyAllSame(fcancel)

    f1s.each |Future f| { verify(f.isDone); verifyEq(f.get, ["one"]) }
    f2s.each |Future f| { verify(f.isDone); verifyEq(f.get, ["one", "two"]) }
    f3s.each |Future f| { verify(f.isDone); verifyEq(f.get, ["one", "two", "three"]) }
    f4s.each |Future f| { verify(f.isDone); verifyEq(f.get, ["one", "two", "three", "four"]) }
    ferr.each |Future f| { verify(f.isDone); verifyErr(IndexErr#) |,| { f.get } }
    verifyAllCancelled(fcancel)
  }

  static Obj? coalesce(Context cx, Obj? msg)
  {
    if (msg is Duration) { Thread.sleep(msg); cx["msgs"] = Str[,]; return msg }
    if (msg == "throw") throw IndexErr("foo bar")
    Str[] msgs := cx.get("msgs")
    msgs.add(msg)
    return msgs
  }

  Void verifyAllSame(Obj[] list)
  {
    x := list.first
    list.each |Obj y| { verifySame(x, y) }
  }

//////////////////////////////////////////////////////////////////////////
// Coalescing (with funcs)
//////////////////////////////////////////////////////////////////////////

  Void testCoalescingFunc()
  {
    a := Actor.makeCoalescing(group, &coalesceKey, &coalesceCoalesce, &coalesceReceive)

    fstart  := a.send(100ms)

    f1s := Future[,]
    f2s := Future[,]
    f3s := Future[,]
    ferr := Future[,]
    fcancel := Future[,]

    ferr.add(a.send(["throw"]))
    f1s.add(a.send(["1", 1]))
    f2s.add(a.send(["2", 10]))
    f2s.add(a.send(["2", 20]))
    ferr.add(a.send(["throw"]))
    f2s.add(a.send(["2", 30]))
    fcancel.add(a.send(["cancel"]))
    fcancel.add(a.send(["cancel"]))
    f3s.add(a.send(["3", 100]))
    f1s.add(a.send(["1", 2]))
    f3s.add(a.send(["3", 200]))
    fcancel.add(a.send(["cancel"]))
    ferr.add(a.send(["throw"]))

    fcancel.first.cancel

    a.send(10ms).get(2sec) // wait until completed

    verifyAllSame(f1s)
    verifyAllSame(f2s)
    verifyAllSame(f3s)
    verifyAllSame(ferr)
    verifyAllSame(fcancel)

    f1s.each |Future f| { verify(f.isDone); verifyEq(f.get, ["1", 1, 2]) }
    f2s.each |Future f| { verify(f.isDone); verifyEq(f.get, ["2", 10, 20, 30]) }
    f3s.each |Future f| { verify(f.isDone); verifyEq(f.get, ["3", 100, 200]) }
    ferr.each |Future f| { verify(f.isDone); verifyErr(IndexErr#) |,| { f.get } }
    verifyAllCancelled(fcancel)
  }

  static Obj? coalesceKey(Obj? msg)
  {
    msg is List ? msg->get(0): null
  }

  static Obj? coalesceCoalesce(Obj[] a, Obj[] b)
  {
    Obj[,].add(a[0]).addAll(a[1..-1]).addAll(b[1..-1])
  }

  static Obj? coalesceReceive(Context cx, Obj? msg)
  {
    if (msg is Duration) { Thread.sleep(msg); return msg }
    if (msg->first == "throw") throw IndexErr("foo bar")
    return msg
  }

}
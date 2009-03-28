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
    20.times |Int i|
    {
      dur := 1ms * Int.random(0...300).toFloat
      if (i == 0) dur = 300ms
      actor := Actor(group, &sleep)
      actors.add(actor)
      durs.add(dur)
      Int.random(100...1000).times |Int j| { actor.send(j) }
      futures.add(actor.send(dur))
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

    // verify can't send anymore
    actors.each |Actor a| { verifyErr(Err#) |,| { a.send(10sec) } }

    // stop again, join with no timeout
    group.stop.join
    t2 = Duration.now
    verify(t2 - t1 <= 320ms, (t2-t1).toLocale)
    verifyEq(group.isStopped, true)
    verifyEq(group.isDone, true)

    // verify all futures have completed
    futures.each |Future f| { verify(f.isDone) }
    futures.each |Future f, Int i| { verifyEq(f.get, durs[i]) }
  }

//////////////////////////////////////////////////////////////////////////
// Kill
//////////////////////////////////////////////////////////////////////////

  Void testKill()
  {
    // spawn off a bunch of actors and sleep messages
    futures := Future[,]
    durs := Duration[,]
    200.times |,|
    {
      actor := Actor(group, &sleep)
      6.times |Int i|  // 6x 0ms - 50ms, max 600ms
      {
        dur := 1ms * Int.random(0...50).toFloat
        futures.add(actor.send(dur))
        durs.add(dur)
      }
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
  }

}
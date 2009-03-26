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
    // TODO: make this a 100 and we are broke
    actors := Actor[,]
    90.times |,| { actors.add(Actor(group, &order)) }

    // randomly send increasing ints to the actors
    100_000.times |Int i| { actors[Int.random(0...actors.size)].send(i) }

    // get the results
    futures := Future[,]
    actors.each |Actor a| { futures.add(a.send("result")) }

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
    if (msg == "result") return r
    r.add(msg)
    return null
  }

}
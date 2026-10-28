//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Feb 16  Brian Frank  Creation
//

**
** LockTest
**
class LockTest : Test
{
  Void test()
  {
    pool := ActorPool()
    lock := Lock.makeReentrant()

    a := LockTestActor(pool, "A", true, lock)
    b := LockTestActor(pool, "B", false, lock)

    // lock/unlock
    buf := StrBuf()
    fa := a.send(Unsafe(buf))
    fb := b.send(Unsafe(buf))
    Future.waitForAll([fa, fb])
    verifyEq(fa.get, "A")
    verifyEq(fb.get, "B")
    actual := buf.toStr
    verify(actual == "A0 A1 A2 B0 B1 B2" || actual == "B0 B1 B2 A0 A1 A2")

    // tryLock; A holds lock until we release it
    fa = a.send("tryLock and hold")
    while (!a.held.val) Actor.sleep(1ms)
    fb = b.send(null)
    verify(fb.get < 100ms)
    fb = b.send(10ms)
    verify(fb.get >= 10ms && fb.get < 1sec)
    a.release.val = true
    fa.get
  }
}

internal const class LockTestActor : Actor
{
  new make(ActorPool pool, Str name, Bool toggle, Lock lock) : super(pool)
  {
    this.name   = name
    this.lock   = lock
    this.toggle = toggle
  }

  const Str name
  const Lock lock
  const Bool toggle
  const AtomicBool held := AtomicBool()
  const AtomicBool release := AtomicBool()

  override Obj? receive(Obj? msg)
  {
    // lock/unlock test
    if (msg is Unsafe)
    {
      buf := (StrBuf)((Unsafe)msg).val

      if (toggle)
      {
        return lock.withLock |->Str|
        {
          3.times |i|
          {
            buf.join("$name$i", " ")
            Actor.sleep(50ms)
          }
          return name
        }
      }
      else
      {
        lock.lock
        3.times |i|
        {
          buf.join("$name$i", " ")
          Actor.sleep(50ms)
        }
        lock.unlock
        return name
      }
    }

    // tryLock for A
    if (msg == "tryLock and hold")
    {
      if (lock.tryLock != true) throw Err("boom!")
      held.val = true
      while (!release.val) Actor.sleep(1ms)
      lock.unlock
      return null
    }

    // tryLock for B
    dur := msg as Duration
    t1 := Duration.now
    if (lock.tryLock(dur) != false) throw Err("boom!")
    t2 := Duration.now
    return t2 - t1
  }
}


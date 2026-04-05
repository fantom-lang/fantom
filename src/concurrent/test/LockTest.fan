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

    // tryLock
    fa = a.send("tryLock and sleep")
    fb = b.send(null)
    verify(fb.get < 1ms)
    fb = b.send(10ms)
    verify(fb.get > 10ms && fb.get < 20ms)
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
    if (msg == "tryLock and sleep")
    {
      if (lock.tryLock != true) throw Err("boom!")
      Actor.sleep(100ms)
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


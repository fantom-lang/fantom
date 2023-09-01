//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Sep 23 Brian Frank  Creation
//
package fan.concurrent;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Condition;
import fan.sys.*;

public final class Lock
  extends FanObj
  implements java.util.concurrent.locks.Lock
{
  public static Lock makeReentrant()
  {
    return new Lock(new java.util.concurrent.locks.ReentrantLock());
  }

  private Lock(java.util.concurrent.locks.Lock java)
  {
    this.java = java;
  }

  public Type typeof()
  {
    if (type == null) type = Type.find("concurrent::Lock");
    return type;
  }
  private static Type type;

  public final void lock()
  {
    this.java.lock();
  }

  public final void lockInterruptibly()
  {
    try
    {
      this.java.lockInterruptibly();
    }
    catch (InterruptedException e)
    {
      throw InterruptedErr.make(e);
    }
  }

  public final Condition newCondition()
  {
    return this.java.newCondition();
  }

  public final boolean tryLock(Duration timeout)
  {
    if (timeout == null || timeout.ticks() <= 0L)
      return tryLock();
    else
      return tryLock(timeout.ticks(), TimeUnit.NANOSECONDS);
  }

  public final boolean tryLock()
  {
    return this.java.tryLock();
  }

  public final boolean tryLock(long time, TimeUnit unit)
  {
    try
    {
      return this.java.tryLock(time, unit);
    }
    catch (InterruptedException e)
    {
      throw InterruptedErr.make(e);
    }
  }

  public final void  unlock()
  {
    this.java.unlock();
  }

  private final java.util.concurrent.locks.Lock java;

}
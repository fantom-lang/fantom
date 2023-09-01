//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Sep 23  Brian Frank  Creation
//

**
** Lock for synchronization between actors.
**
native const class Lock
{
  ** Construct mutual exclusion lock.
  static Lock makeReentrant()

  ** Private constructor
  private new make()

  ** Acquire the lock; if not available then block forever until its available.
  Void lock()

  ** Release the lock.  Raise exception if not holding the lock.
  Void unlock()

  ** Acquire the lock if its free and immediately return true.
  ** Or if the lock is not available and timeout is null, then
  ** immediately return false.  If timeout is non-null, then block
  ** up to the given timeout waiting for the lock and return true
  ** if lock acquired or false on timeout.
  Bool tryLock(Duration? timeout := null)
}



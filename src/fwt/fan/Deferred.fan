//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Mar 2013  Andy Frank  Creation
//

**************************************************************************
** Deferred
**************************************************************************

** Deferred.
@Js
class Deferred
{

//////////////////////////////////////////////////////////////////////////
// Callbacks
//////////////////////////////////////////////////////////////////////////

  ** Add a callback to be invoked when this Deferred
  ** is [resolved]`#resolve`.
  This onDone(|Obj?| doneCallback)
  {
    if (isResolved)
    {
      // invoke immediately
      doneCallback(arg)
    }
    else
    {
      // queue callback
      _onDone.add(doneCallback)
    }
    return this
  }

  ** Add a callback to be invoked when this Deferred is
  ** [rejected]`#reject`.
  This onFail(|Obj?| failCallback)
  {
    if (isRejected)
    {
      // invoke immediately
      failCallback(arg)
    }
    else
    {
      // queue callback
      _onFail.add(failCallback)
    }
    return this
  }

  ** Add a callback that will always be invoked, regardless
  ** if Deferred is [resolved]`#resolve` or [rejected]`#reject`.
  This onAlways(|Obj?| alwaysCallback)
  {
    if (!isPending)
    {
      // invoke immediately
      alwaysCallback(arg)
    }
    else
    {
      // queue callback
      _onAlways.add(alwaysCallback)
    }
    return this
  }

  ** Convenience for `#onDone` and `#onFail` together.
  This then(|Obj?| doneCallback, |Obj?|? failCallback := null)
  {
    onDone(doneCallback)
    if (failCallback != null) onFail(failCallback)
    return this
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  ** True until `#resolve` or `#reject` have been invoked.
  Bool isPending() { state === "pending" }

  ** True if `#resolve` has been invoked on this Deferred.
  Bool isResolved() { state === "resolved" }

  ** True if `#reject` has been invoked on this Deferred.
  Bool isRejected() { state === "rejected" }

//////////////////////////////////////////////////////////////////////////
// Actions
//////////////////////////////////////////////////////////////////////////

  ** Resolve this Deferred and invoke all its `#onDone` callbacks
  ** with given argment.
  Void resolve(Obj? obj := null)
  {
    if (!isPending) throw Err("Deferred already $state")
    state = "resolved"
    arg   = obj
    _onDone.each |f| { f(obj) }
    _onAlways.each |f| { f(obj) }
  }

  ** Reject this Deferred and invoke all its `#onFail` callbacks
  ** with given argment.
  Void reject(Obj? obj := null)
  {
    if (!isPending) throw Err("Deferred already $state")
    state = "rejected"
    arg   = obj
    _onFail.each |f| { f(obj) }
    _onAlways.each |f| { f(obj) }
  }

//////////////////////////////////////////////////////////////////////////
// Promise
//////////////////////////////////////////////////////////////////////////

  ** Return a new Promise wrapper for this Deferred.
  Promise promise() { Promise(this) }

//////////////////////////////////////////////////////////////////////////
// Private
//////////////////////////////////////////////////////////////////////////

  private Str state := "pending"    // pending, resolved, rejected
  private Obj? arg := null          // cached resolve/reject arg

  private Func[] _onDone   := [,]
  private Func[] _onFail   := [,]
  private Func[] _onAlways := [,]
}

**************************************************************************
** Promise
**************************************************************************

** Promise exposes a Deferred as a read-only wrapper.
@Js
class Promise
{
  ** Internal ctor.
  internal new make(Deferred deferred)
  {
    this.deferred = deferred
  }

  ** Add a callback to be invoked when this Promise is resolved.
  This onDone(|Obj?| doneCallback)
  {
    deferred.onDone(doneCallback)
    return this
  }

  ** Add a callback to be invoked when this Deferred is rejected.
  This onFail(|Obj?| failCallback)
  {
    deferred.onFail(failCallback)
    return this
  }

  ** Add a callback that will always be invoked, regardless
  ** if Promise is resolved or rejected.
  This onAlways(|Obj?| alwaysCallback)
  {
    deferred.onAlways(alwaysCallback)
    return this
  }

  ** Convenience for `#onDone` and `#onFail` together.
  This then(|Obj?| doneCallback, |Obj?|? failCallback := null)
  {
    deferred.then(doneCallback, failCallback)
    return this
  }

  ** True until Promise is resolved or rejected.
  Bool isPending() { deferred.isPending }

  ** True if Promise is resolved.
  Bool isResolved() { deferred.isResolved }

  ** True if Promise is rejected.
  Bool isRejected() { deferred.isRejected }

  private Deferred deferred
}

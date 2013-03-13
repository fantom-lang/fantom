//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Mar 2013  Andy Frank  Creation
//

**
** AsyncTask models an asynchronous operation's progress and provides
** a list of callback handlers when the task completes (either successfully
** or fails).
**
@Js
class AsyncTask
{

//////////////////////////////////////////////////////////////////////////
// Callbacks
//////////////////////////////////////////////////////////////////////////

  ** Add a callback to be invoked when this task completes successfully.
  This onDone(|Obj?| doneCallback)
  {
    if (isDone)
    {
      // invoke immediately
      doneCallback(arg)
    }
    else
    {
      // queue callback
      (parent?._onDone ?: _onDone).add(doneCallback)
    }
    return this
  }

  ** Add a callback to be invoked when this task fails.
  This onErr(|Obj?| errCallback)
  {
    if (isErr)
    {
      // invoke immediately
      errCallback(arg)
    }
    else
    {
      // queue callback
      (parent?._onErr ?: _onErr).add(errCallback)
    }
    return this
  }

  ** Add a callback that will always be invoked, regardless
  ** if task completes successfully or fails.
  This onDoneOrErr(|Obj?| doneOrErrCallback)
  {
    if (!isPending)
    {
      // invoke immediately
      doneOrErrCallback(arg)
    }
    else
    {
      // queue callback
      (parent?._onDoneOrErr ?: _onDoneOrErr).add(doneOrErrCallback)
    }
    return this
  }

  ** Convenience for `onDone` and `onErr` together.
  This then(|Obj?| doneCallback, |Obj?|? errCallback := null)
  {
    onDone(doneCallback)
    if (errCallback != null) onErr(errCallback)
    return this
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  ** True until `markDone` or `markErr` invoked.
  Bool isPending() { parent==null ? (!isDone && !isErr) : parent.isPending }

  ** True if `markDone` has been invoked.
  Bool isDone() { parent==null ? state === "done" : parent.isDone }

  ** True if `markErr` has been invoked.
  Bool isErr() { parent==null ? state === "err" : parent.isErr }

//////////////////////////////////////////////////////////////////////////
// Actions
//////////////////////////////////////////////////////////////////////////

  ** Mark this Task as 'done' and invoke all its `onDone`
  ** callbacks with given argment.
  Void markDone(Obj? obj := null)
  {
    if (isRO) throw Err("Task is readonly")
    if (!isPending) throw Err("Task already completed as '$state'")
    state = "done"
    arg   = obj
    _onDone.each |f| { f(obj) }
    _onDoneOrErr.each |f| { f(obj) }
  }

  ** Mark this Task as 'erred' and invoke all its `onErr`
  ** callbacks with given argment.
  Void markErr(Obj? obj := null)
  {
    if (isRO) throw Err("Task is readonly")
    if (!isPending) throw Err("Task already completed as '$state'")
    state = "err"
    arg   = obj
    _onErr.each |f| { f(obj) }
    _onDoneOrErr.each |f| { f(obj) }
  }

//////////////////////////////////////////////////////////////////////////
// RO
//////////////////////////////////////////////////////////////////////////

  ** Is this instance read-only.  Read-only tasks may not
  ** be marked as done or err.
  Bool isRO() { parent != null }

  ** Return a new read-only wrapper for this task.  Read-only
  ** tasks may not be marked as done or err.
  AsyncTask ro() { parent == null ? AsyncTask { it.parent=this } : this }

//////////////////////////////////////////////////////////////////////////
// Private
//////////////////////////////////////////////////////////////////////////

  private AsyncTask? parent   // parent task for ro wrapper

  private Str state := "pending"    // pending, done, err
  private Obj? arg := null          // cached done/err arg

  private Func[] _onDone      := [,]
  private Func[] _onErr       := [,]
  private Func[] _onDoneOrErr := [,]
}

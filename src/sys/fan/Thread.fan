//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 06  Brian Frank  Stub
//   28 Jan 07  Brian Frank  Implement threading model
//

**
** Thread models a thread of execution within a process.
** See `docLang::Threading` for details.
**
const class Thread
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Make a new thread with the given name.  If name is non-null then it
  ** must not conflict with any threads currently active (new or running)
  ** otherwise ArgErr is thrown.  Convention is to use a dotted notation
  ** beginning with your pod name to avoid naming collisions.  If name is
  ** null, then a unique name is automatically generated.  If name is
  ** non-null, then it must be valid according to `Uri.isName` otherwise
  ** NameErr is thrown.
  **
  ** If run is non-null, then it is invoked as the main loop of the thread.
  ** If run is specified then it must be an immutable function (it cannot
  ** capture state from the calling thread), otherwise NotImmutableErr is
  ** thrown.  If run is null, then you must subclass Thread and override
  ** the run() method.  The return value of run is available to the first
  ** thread which calls `join`.
  **
  ** The thread is created in the new state, and must be started using
  ** the start method.
  **
  new make(Str? name := null, |Thread t->Obj|? run := null)

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

  **
  ** Lookup a thread in this VM by name.  If the thread doesn't
  ** exist and checked is false then return null, otherwise throw
  ** UnknownThreadErr.  Only active threads which are in the new
  ** or running state may be found by name.
  **
  static Thread? find(Str name, Bool checked := true)

  **
  ** Get the list of all active (new or running) threads
  ** in the VM.
  **
  static Thread[] list()

  **
  ** Get the currently executing thread.  Throw Err if
  ** the current thread is not a proper Fan thread.
  **
  static Thread current()

  **
  ** Return the map of thread local variables.  This is a map of "global"
  ** variables visible only to the current thread.  These variables are
  ** keyed by a string name - by convention use a dotted notation beginning
  ** with your pod name to avoid naming collisions.
  **
  static Str:Obj? locals()

//////////////////////////////////////////////////////////////////////////
// Service
//////////////////////////////////////////////////////////////////////////

  **
  ** Lookup a service thread by type.  If the service doesn't
  ** exist and checked is false then return null, otherwise throw
  ** UnknownThreadErr.  See `isService`.
  **
  static Thread? findService(Type t, Bool checked := true)

  **
  ** Subclasses should override this method to publish this
  ** thread to a "well known URI".  Service threads are automatically
  ** mapped into the namespace under "/sys/service/{qname}" for
  ** all their public types.  This mapping is only available while
  ** the thread is new or running.  If more than service type is currently
  ** active, only the first one is mapped.  You can also use the
  ** `findService` method to lookup a service type.  The default is
  ** to return false.
  **
  virtual Bool isService()

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the name of this thread which uniquely
  ** identifies this thread within the VM.
  **
  Str name()

  **
  ** Print this thread's stack trace to the specified output
  ** stream (or Sys.out by default).  If this thread is not currently
  ** running print nothing.
  **
  Void trace(OutStream out := Sys.out)

  **
  ** Return true if same thread according '===' same operator.
  **
  override Bool equals(Obj? obj)

  **
  ** Return name.hash.
  **
  override Int hash()

  **
  ** Default toStr returns name.
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if this thread has been created, but not yet started.
  **
  Bool isNew()

  **
  ** Return if this thread has been started, but not yet stopped.
  **
  Bool isRunning()

  **
  ** Return if this thread has been stopped.
  **
  Bool isDead()

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  **
  ** Start this thread running.  If the thread is already
  ** running or has been stopped, then throw Err.  Return this.
  ** Also see `stop` and `kill`.
  **
  This start()

  **
  ** Stop this thread from running with a clean shutdown.
  ** The thread finishes processing all the pending messages
  ** on its queue, then exits gracefully.  If not currently
  ** running, then this method does nothing.  Return this.
  ** Also see `kill` to discard pending messages.
  **
  This stop()

  **
  ** Kill this thread from running as soon as possible.  Any
  ** pending messages in the queue are discarded, and the thread
  ** is terminated as soon as reaches an interruptable point in
  ** its main loop.  InterruptedErr is raised on any threads waiting
  ** for sendSync responses. If not currently running then do nothing.
  ** Return this.  Also see `stop` to gracefully shutdown.
  **
  This kill()

  **
  ** Wait for this thread to stop.  If timeout is non-null,
  ** then wait no longer then specified timeout.  If this thread
  ** hasn't been started yet, then throw Err.  If this thread
  ** is already dead, then this method is a no op.  Return
  ** the result of the run method for the first thread to join,
  ** or null on subsequent calls.
  **
  Obj? join(Duration? timeout := null)

  **
  ** Put the currently executing thread to sleep for the
  ** specified period.  If the thread is interrupted for any
  ** reason while sleeping, then InterruptedErr is thrown.
  **
  static Void sleep(Duration duration)

  **
  ** The run method implements the code to run in the thread.
  ** If a run function was specified in the constructor, then it
  ** is invoked, otherwise subclasses should override this method.
  ** Threads which wish to process their message queue must
  ** enter the main loop by calling the loop() method.  The
  ** return value of this method is available to the first thread
  ** which calls the join method (the result is not required to
  ** be immutable).
  **
  protected virtual Obj? run()

  **
  ** This callback is invoked on this thread right before
  ** `run` is called.  If this method raises an exception,
  ** then `run` is not called (although `onStop` is still
  ** called).
  **
  protected virtual Void onStart()

  **
  ** This callback is invoked on this thread right after
  ** the `run` method exits.  This method is called even
  ** if `onStart` or `run` raises an exception.
  **
  protected virtual Void onStop()

  **
  ** Enter the message loop.  This method does not return until
  ** the thread is stopped.  This receive callback is invoked by
  ** the main loop each time a message is received from its send queue.
  ** The callback should process the message and return a response.
  ** If the calling thread is not this thread, then throw Err.
  **
  ** If the the message was enqueued by sendAsync the response is
  ** ignored; exceptions are printed to standard output and ignored.
  **
  ** If the message was enqueued by sendSync the response is
  ** returned to the caller and must be immutable or serializable;
  ** exceptions are raised to the caller.
  **
  ** See [docLang]`docLang::Threading#messages`.
  **
  Void loop(|Obj? msg->Obj?| receive)

  **
  ** Enter a coalescing message loop.  This method follows the same
  ** semantics as `loop`, but has the ability to coalesce the messages
  ** pending in the thread's message queue.
  **
  ** The 'toKey' function is used to derive a key for each message,
  ** or if null then the message itself is used as the key.  If the 'toKey'
  ** function returns null, then the message is not considered for coalescing.
  ** Internally messages are indexed by key for efficient coalescing.
  **
  ** If an incoming message has the same key as a pending message
  ** in the queue, then the 'coalesce' function is called to coalesce
  ** the messages into a new merged message.  If 'coalesce' is null,
  ** then we use the original message.  The coalesced message occupies
  ** the same position in the queue as the original and the incoming
  ** message is discarded.
  **
  ** Both the 'toKey' and 'coalesce' functions are called while holding
  ** an internal lock on the queue.  So the functions must be efficient
  ** and never attempt to interact with other threads.
  **
  ** See [docLang]`docLang::Threading#coalescing` for more information.
  **
  Void loopCoalescing(|Obj? msg->Obj?|? toKey,
                      |Obj? orig, Obj? incoming->Obj?|? coalesce,
                      |Obj? msg->Obj?| receive)

//////////////////////////////////////////////////////////////////////////
// Messaging
//////////////////////////////////////////////////////////////////////////

  **
  ** Enqueue the specified message for this thread, then block the
  ** calling thread until this thread processes the message via
  ** the `loop` callback - return the result.  If the `loop`
  ** callback throws an exception processing the message, then
  ** that exception is raised to the calling thread.  If msg is
  ** not immutable or serializable, then IOErr is thrown.  If this
  ** thread is stopped while the caller is blocked, then an
  ** InterruptedErr is thrown.  Note that flow control may block
  ** the caller until there is enough space in this thread's message
  ** queue.
  **
  ** See [docLang]`docLang::Threading#messages`.
  **
  Obj? sendSync(Obj? msg)

  **
  ** Enqueue the specified message for this thread to process in
  ** its received() callback.  Using sendAsync() is fire-and-forget,
  ** the caller has no guarantee that this thread will successfully
  ** process the message.  If msg is not immutable or serializable,
  ** then IOErr is thrown.  Note that flow control may block the
  ** caller until there is enough space in this thread's message
  ** queue.  Return this.
  **
  ** See [docLang]`docLang::Threading#messages`.
  **
  This sendAsync(Obj? msg)

  **
  ** Setup a timer to post a message to this thread after the
  ** specified duration has elapsed.  If repeat is true, then
  ** the same msg is posted on repeated intervals of the given
  ** duration.  Expired timer messages are always processed before
  ** messages posted by `sendSync` and `sendAsync`.  Return an opaque
  ** ticket which may used to cancel the timer via `cancelLater`.
  ** If msg is not immutable or serializable, then IOErr is thrown.
  **
  ** See [docLang]`docLang::Threading#timers`.
  **
  Obj sendLater(Duration dur, Obj? msg, Bool repeat := false)

  **
  ** Cancel a timer with the ticket returned by `sendLater`.
  **
  Void cancelLater(Obj ticket)

}
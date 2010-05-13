#! /usr/bin/env fan

using concurrent
using fwt
using gfx

**
** Display a clock label and update from a background task
** using an actor.
**
const class Clock : Actor
{
  **
  ** the only message we understand...
  **
  static const Str updateMsg := "update"

  **
  ** generate a unique handle for this actor
  **
  const Str handle := Uuid().toStr

  **
  ** create a Clock that updates a UI Label
  **
  new make(Label label) : super(ActorPool())
  {
    // Clock instance must be created by the main UI thread,
    // which is where we need to cache the label
    Actor.locals[handle] = label

    // send the first clock-tick
    sendLater(1sec, updateMsg)
  }

  **
  ** receive a message in actor's own pool thread
  **
  override Obj? receive(Obj? msg)
  {
    // assuming we recognize the message, have the
    // UI thread execute an update (with this actor's
    // update method, below)
    if (msg == updateMsg)
    {
      Desktop.callAsync |->| { update }

      // send the next clock-tick
      sendLater(1sec, updateMsg)
    }
    return null
  }

  **
  ** Must be called from the UI thread; will look up
  ** our label using the const handle, and set its
  ** text with the current time.
  **
  Void update()
  {
    label := Actor.locals[handle] as Label
    if (label != null)
    {
      time := Time.now.toLocale("k:mm:ss a")
      label.text = "It is now $time"
    }
  }


  static Void main()
  {
    // label to update
    display := Label
    {
      text   = "Does anybody know what time it is?"
      halign = Halign.center
    }

    // clock actor
    clock := Clock(display)

    Window
    {
      size = Size(200,100)
      title = "Clock Actor"
      display,
    }.open
  }
}
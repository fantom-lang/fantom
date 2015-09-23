//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Feb 2009  Andy Frank  Creation
//    8 Jul 2009  Andy Frank  Split webappClient into sys/dom
//    2 Jun 2011  Andy Frank  Rename to DomEvent
//   26 Aug 2015  Andy Frank  Rename back to Event
//

**
** Event models the DOM event object.
**
@Js
class Event
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  private new make() {}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  ** The target to which the event was dispatched.
  native Elem target()

  ** The x position of the event.
  native Int x()

  ** The y position of the event.
  native Int y()

  ** Return true if the ALT key was pressed during the event.
  native Bool alt()

  ** Return true if the CTRL key was pressed during the event.
  native Bool ctrl()

  ** Return true if the SHIFT key was pressed during the event.
  native Bool shift()

  ** Return true if the Meta key was pressed during the event.  On Macs
  ** this maps to "command" key.  On Windows this maps to "Windows" key.
  native Bool meta()

  ** Mouse button number pressed.
  native Int? button()

  ** Horizontal scroll amount for wheel events.
  native Int? deltaX()

  ** Vertical scroll amount for wheel events.
  native Int? deltaY()

  ** Key instance for key pressed.
  native Key? key()

  ** Stop further propagation of this event.
  native Void stop()

  ** The DataTransfer object for this event.
  native DataTransfer dataTransfer()

  ** Meta-data for this event instance.
  Str:Obj? stash := Str:Obj?[:]

  override Str toStr()
  {
    "Event { target=$target x=$x y=$y button=$button deltaX=$deltaX deltaY=$deltaY" +
    " key=$key alt=$alt ctrl=$ctrl meta=$meta shift=$shift }"
  }
}
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Feb 09  Andy Frank  Creation
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
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

  ** Mouse button number pressed.
  native Int? button

  ** Meta-data for this event instance.
  Str:Obj? meta := Str:Obj?[:]

}
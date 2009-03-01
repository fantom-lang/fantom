//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Feb 09  Andy Frank  Creation
//

**
** Event models the DOM event object.
**
@javascript
class Event
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  new make(Obj obj) {}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** The target to which the event was dispatched.
  **
  Elem target() { return Elem("") }

  **
  ** The x position of the event.
  **
  Int x() { return 0 }

  **
  ** The y position of the event.
  **
  Int y() { return 0 }

}
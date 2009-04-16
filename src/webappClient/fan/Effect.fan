//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Apr 09  Andy Frank  Creation
//

**
** Effect provides visual effects on a DOM element.
**
@javascript
class Effect
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct a new Effect object for the given DOM element.
  **
  new make(Elem elem) {}

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the DOM element effects are applied to.
  **
  Elem elem() { return Elem("") }

//////////////////////////////////////////////////////////////////////////
// Show/Hide
//////////////////////////////////////////////////////////////////////////

  **
  ** Show the element.  If 'dur' is specificed, animate the
  ** display within the given duration of time.  If given,
  ** invoke the callback function after animation has completed.
  **
  This show(Duration dur := 0ms, |Effect|? callback := null)
  {
    return this
  }

  **
  ** Hide the element.  If 'dur' is specificed, animate the
  ** display within the given duration of time.  If given,
  ** invoke the callback function after animation has completed.
  **
  This hide(Duration dur := 0ms, |Effect|? callback := null)
  {
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Animate
//////////////////////////////////////////////////////////////////////////

  **
  ** TODO.
  **
  This animate(Str:Str map, Duration dur := 0ms, |Effect|? callback := null)
  {
    return this
  }

}
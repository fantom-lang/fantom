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
// Animate
//////////////////////////////////////////////////////////////////////////

  **
  ** Animate one or more CSS properties on the element.  If 'dur' is
  ** specified, animate within the given duration of time.  If given,
  ** invoke the callback function after the animation has completed.
  **
  **   elem.effect.animate(["opacity":"0.0"], 100ms) |fx| {
  **     fx.animate(["opacity":"1.0"], 100ms)
  **   }
  **
  This animate(Str:Str map, Duration dur := 0ms, |Effect|? callback := null)
  {
    return this
  }

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
// Fading
//////////////////////////////////////////////////////////////////////////

  **
  ** Fade in the element by animating its opacity.  If 'dur' is
  ** specificed, animate the fade within the given duration of
  ** time.  If given, invoke the callback function after animation
  ** has completed.
  **
  This fadeIn(Duration dur := 0ms, |Effect|? callback := null)
  {
    return this
  }

  **
  ** Fade in the element by animating its opacity.  If 'dur' is
  ** specificed, animate the fade within the given duration of
  ** time.  If given, invoke the callback function after animation
  ** has completed.
  **
  This fadeOut(Duration dur := 0ms, |Effect|? callback := null)
  {
    return this
  }

  **
  ** Fade the opacity of the element to the target value, where
  ** 0.0 is fully transparent, and 1.0 is fully opaque. If 'dur' is
  ** specificed, animate the fade within the given duration of
  ** time.  If given, invoke the callback function after animation
  ** has completed.
  **
  This fadeTo(Decimal opacity, Duration dur := 0ms, |Effect|? callback := null)
  {
    return this
  }

}
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Apr 09  Andy Frank  Creation
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

**
** Effect provides visual effects on a DOM element.
**
@js
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
  native Elem elem()

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
  native This animate(Str:Str map, Duration dur := 0ms, |Effect|? callback := null)

//////////////////////////////////////////////////////////////////////////
// Show/Hide
//////////////////////////////////////////////////////////////////////////

  **
  ** Show the element.  If 'dur' is specificed, animate the
  ** display within the given duration of time.  If given,
  ** invoke the callback function after animation has completed.
  **
  native This show(Duration dur := 0ms, |Effect|? callback := null)

  **
  ** Hide the element.  If 'dur' is specificed, animate the
  ** display within the given duration of time.  If given,
  ** invoke the callback function after animation has completed.
  **
  native This hide(Duration dur := 0ms, |Effect|? callback := null)

//////////////////////////////////////////////////////////////////////////
// Slide
//////////////////////////////////////////////////////////////////////////

  **
  ** Make the element visible by animating its height. If 'dur' is
  ** specificed, animate the slide within the given duration of
  ** time.  If given, invoke the callback function after animation
  ** has completed.
  **
  native This slideDown(Duration dur := 0ms, |Effect|? callback := null)

  **
  ** Hide the element by animating its height. If 'dur' is specificed,
  ** animate the slide within the given duration of time.  If given,
  ** invoke the callback function after animation has completed.
  **
  native This slideUp(Duration dur := 0ms, |Effect|? callback := null)

//////////////////////////////////////////////////////////////////////////
// Fading
//////////////////////////////////////////////////////////////////////////

  **
  ** Fade in the element by animating its opacity.  If 'dur' is
  ** specificed, animate the fade within the given duration of
  ** time.  If given, invoke the callback function after animation
  ** has completed.
  **
  native This fadeIn(Duration dur := 0ms, |Effect|? callback := null)

  **
  ** Fade in the element by animating its opacity.  If 'dur' is
  ** specificed, animate the fade within the given duration of
  ** time.  If given, invoke the callback function after animation
  ** has completed.
  **
  native This fadeOut(Duration dur := 0ms, |Effect|? callback := null)

  **
  ** Fade the opacity of the element to the target value, where
  ** 0.0 is fully transparent, and 1.0 is fully opaque. If 'dur' is
  ** specificed, animate the fade within the given duration of
  ** time.  If given, invoke the callback function after animation
  ** has completed.
  **
  native This fadeTo(Decimal opacity, Duration dur := 0ms, |Effect|? callback := null)

}
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Mar 09  Brian Frank  Creation
//

using gfx

**
** ScrollBar is used to position a widget too wide or tall to be
** visible at one time.  ScrollBars cannot be created directly,
** rather they are accessed widgets which support scrolling via
** 'hbar' and 'vbar'.
**
@Js
@Serializable
class ScrollBar : Widget
{

  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** Internal constructor for scroll bars created
  ** natively as part of some scrollable component
  **
  internal new makeNative(Orientation orientation)
  {
    this.orientation = orientation
    this.isNative = true
  }

  **
  ** Callback when scroll bar value is modified.
  **
  ** Event id fired:
  **   - `EventId.modified`
  **
  ** Event fields:
  **   - `Event.data`: new value of scroll bar
  **
  once EventListeners onModify()
  {
    EventListeners() { it.onModify = |->| { checkModifyListeners } }
  }

  internal native Void checkModifyListeners()

  **
  ** Horizontal or vertical.
  **
  const Orientation orientation := Orientation.horizontal

  **
  ** The current value of the scroll bar.
  **
  native Int val

  **
  ** The minimum value of the scroll bar.
  **
  native Int min

  **
  ** The maximum value of the scroll bar.
  **
  native Int max

  **
  ** The size of thumb relative to difference between min and max.
  **
  native Int thumb

  **
  ** Page increment size relative to difference between min and max.
  **
  native Int page

  **
  ** Native scroll bars are part of a scrollable widget like
  ** ScrollPane or Table and might not be backed by a real widget.
  **
  internal const Bool isNative

}
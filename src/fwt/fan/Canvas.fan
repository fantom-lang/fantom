//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Jun 09  Brian Frank  Creation
//

using gfx

**
** Canvas is a custom widget which paints itself.
**
@Js
@Serializable
class Canvas : Widget
{

  **
  ** This callback is invoked when the widget should be repainted.
  ** The graphics context is initialized at the widget's origin
  ** with the clip bounds set to the widget's size.
  **
  **
  virtual Void onPaint(Graphics g) {}

  // to force native peer
  private native Void dummyCanvas()

}
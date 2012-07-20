//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Sep 2011  Andy Frank  Creation
//

using fwt
using gfx

**
** WebCanvas
**
@NoDoc
@Js
abstract class WebCanvas : Canvas
{
  ** Configure if canvas contents are cleared before repaint.
  ** Defaults to 'true'.
  native Bool clearOnRepaint
}

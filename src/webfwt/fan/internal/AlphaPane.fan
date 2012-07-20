//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Aug 10  Andy Frank  Creation
//

using gfx
using fwt

**
** AlphaPane applies an opacity to its content.
**
@NoDoc
@Js
// TODO: leave as internal until needed
internal class AlphaPane : ContentPane
{
  **
  ** Opacity value, where '0' is fully transparent, and '1.0' is fully opaque.
  **
  Float opacity := 0.5f

  // force native peer
  private native Void dummy()
}
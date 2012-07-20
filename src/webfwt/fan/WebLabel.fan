//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Apr 2010  Andy Frank  Creation
//   17 Mar 2011  Andy Frank  Rename from FLabel to WebLabel
//

using fwt
using gfx

**
** WebLabel extends Label with additional functionality.
**
@Js
class WebLabel : Label
{
  ** Override horizontal gap between image and text.
  ** Defaults to null.
  native Int? hgap

  ** If enabled, text that is clipped by bounds is indicated
  ** with ellipsis (...).  Defaults to 'false'.
  native Bool softClip

  ** Override image size.  Original image will be scaled up or
  ** down to match specified size.
  native Size? imageSize

  ** Override text CSS style. Defaults to null.
  native [Str:Str]? style
}



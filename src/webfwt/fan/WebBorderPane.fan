//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Oct 10  Andy Frank  Creation
//

using fwt
using gfx

**
** WebBorderPane extends BorderPane with additional functionality.
**
@NoDoc
@Js
class WebBorderPane : BorderPane
{
  ** Override style. Defaults to null.
  native [Str:Str]? style
}


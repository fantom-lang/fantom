//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Sep 2011  Andy Frank  Creation
//

using fwt
using gfx

**
** WebText extends Text with additional functionality.
**
@Js
class WebText : Text
{
  ** Constructor.
  new make(|This|? f := null) : super(f) {}

  ** Placeholder text to display in text field if empty.
  Str? placeHolder := null

  ** Override style. Defaults to null.
  [Str:Str]? style := null

  ** Override disabled style. Defaults to null.
  [Str:Str]? disabledStyle := null

  // force peer
  private native Void dummy()
}


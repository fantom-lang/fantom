//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Jul 08  Andy Frank  Creation
//

using web
using webapp

class Box : Widget
{

  override Void onGet()
  {
    body.div("style='color:$fg; background:$bg; padding:${pad}px;'")
    body.esc(text)
    body.divEnd
  }

  Str text := ""
  Str fg   := "#000"
  Str bg   := "none"
  Int pad  := 10

}

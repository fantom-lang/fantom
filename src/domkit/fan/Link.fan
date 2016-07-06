//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jan 2015  Andy Frank  Creation
//

using dom

**
** Hyperlink anchor element
**
@Js class Link : Elem
{
  new make() : super("a")
  {
    this.style.addClass("domkit-Link")
  }

  ** URI to hyperlink to.
  Uri uri := `#`
  {
    set
    {
      &uri = it
      set("href", &uri.encode)
    }
  }
}
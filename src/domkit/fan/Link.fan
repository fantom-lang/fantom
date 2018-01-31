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
    this.style.addClass("domkit-control domkit-Link")
    this.uri = `#`
  }

  ** The target attribute specifies where to open the linked document.
  Str target
  {
    get { this->target }
    set { this->target = it }
  }

  ** URI to hyperlink to.
  Uri uri := `#`
  {
    set
    {
      &uri = it
      setAttr("href", &uri.encode)
    }
  }
}

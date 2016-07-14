//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Feb 2015  Brian Frank  Creation
//

using dom

**
** Simple text based element.
**
** See also: [pod doc]`pod-doc#label`
**
@Js class Label : Elem
{
  new make() : super("span")
  {
    this.style.addClass("domkit-Label")
  }
}
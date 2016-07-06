//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Dec 2014  Andy Frank  Creation
//

using dom

**
** Box defaults style to:
**
**   display: block;
**   box-sizing: border-box;
**   width: 100%;
**   height: 100%;
**   position: relative;
**
@Js class Box : Elem
{
  new make() : super("div")
  {
    this.style.addClass("domkit-Box")
  }
}
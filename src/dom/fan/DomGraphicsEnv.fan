//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Mar 2022  Brian Frank  Creation
//

using graphics

**
** Browser implementation of GraphicsEnv
**
@NoDoc @Js
const class DomGraphicsEnv : GraphicsEnv
{
  override Image image(Uri uri, Buf? data := null)
  {
    throw UnsupportedErr()
  }
}
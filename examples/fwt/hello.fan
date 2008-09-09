#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 08  Brian Frank  Creation
//

using fwt

**
** FwtHello is as simple as it gets
**
class FwtHello : Test
{
  Void main()
  {
    Window { Label { text = "Hello world" } }.open
  }
}

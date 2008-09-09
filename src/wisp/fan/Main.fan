//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jun 07  Brian Frank  Creation
//

**
** Main launches a simple bare bones Wisp web server on port 80.
**
class Main
{

  static Void main()
  {
    WispService("web").start.join
  }

}
//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Nov 10  Brian Frank  Creation
//

using gfx

class FwtTestMain : Test
{

  static Void main()
  {
    Window
    {
      size = Size(300,200)
      Label { text = "FWT Test Main!"; halign=Halign.center },
    }.open
  }

}


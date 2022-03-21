//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Mar 2022  Brian Frank  Creation
//

using graphics

@Js
abstract class AbstractTest
{
  static Type[] list()
  {
    AbstractTest#.pod.types.findAll |t| { t.fits(AbstractTest#) && !t.isAbstract }.sort
  }

  Void paint(Size size, Graphics g)
  {
    g.color = Color("white")
    g.fillRect(0f, 0f, size.w-1f, size.h-1f)
    g.color = Color("black")
    g.drawRect(0f, 0f, size.w-1f, size.h-1f)
    onPaint(size, g)
  }

  abstract Void onPaint(Size size, Graphics g)
}


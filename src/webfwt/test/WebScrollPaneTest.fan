//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 2011  Andy Frank  Creation
//

using fwt
using gfx
using web

**
** WebScrollPaneTest
**
@Js
internal class WebScrollPaneTest : ContentPane
{
  new make()
  {
    content = InsetPane(24)
    {
      GridPane
      {
        numCols = 4
        vgap = 24
        hgap = 24
        // auto/off
        sample(Size(200,200), Size(100,100), WebScrollPane.auto, WebScrollPane.off),
        sample(Size(200,200), Size(200,200), WebScrollPane.auto, WebScrollPane.off),
        sample(Size(200,200), Size(300,300), WebScrollPane.auto, WebScrollPane.off),
        sample(Size(200,200), Size(300,100), WebScrollPane.auto, WebScrollPane.off),

        // auto/auto
        sample(Size(200,200), Size(100,100), WebScrollPane.auto, WebScrollPane.auto),
        sample(Size(200,200), Size(200,200), WebScrollPane.auto, WebScrollPane.auto),
        sample(Size(200,200), Size(300,300), WebScrollPane.auto, WebScrollPane.auto),
        sample(Size(200,200), Size(300,100), WebScrollPane.auto, WebScrollPane.auto),

        // on/on
        sample(Size(200,200), Size(100,100), WebScrollPane.on, WebScrollPane.on),
        sample(Size(200,200), Size(200,200), WebScrollPane.on, WebScrollPane.on),
        sample(Size(200,200), Size(300,300), WebScrollPane.on, WebScrollPane.on),
        sample(Size(200,200), Size(300,100), WebScrollPane.on, WebScrollPane.on),
      },
    }
  }

  Widget sample(Size container, Size content, Int vpolicy, Int hpolicy)
  {
    ConstraintPane
    {
      minw=container.w; maxw=container.w
      minh=container.h; maxh=container.h
      WebScrollPane
      {
        it.vpolicy = vpolicy
        it.hpolicy = hpolicy
        ConstraintPane
        {
          minw=content.w; maxw=content.w
          minh=content.h; maxh=content.h
          BorderPane { border=Border("#f00") },
        },
      },
    }
  }
}

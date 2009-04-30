//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 08  Brian Frank  Creation
//

using gfx

**
** PaneTest
**
class PaneTest : Test
{

  Void testInsetPane()
  {
    x := InsetPane(1,2,3,4)
    {
      content = Fixed { ps = Size(10,10) }
    }
    verifyEq(x.insets, Insets(1,2,3,4))
    verifyEq(x.prefSize, Size(16,14))

    x.size = Size(20,20)
    x.onLayout
    verifyEq(x.content.bounds, Rect(4,1,14,16))

    verifyEq(InsetPane(5).insets, Insets(5,5,5,5))
    verifyEq(InsetPane(5,6).insets, Insets(5,6,5,6))
    verifyEq(InsetPane(5,6,7).insets, Insets(5,6,7,6))
  }

  Void testEdgePane()
  {
    // top+bottom
    x := EdgePane
    {
      top = Fixed { ps = Size(10,20) }
      bottom = Fixed { ps = Size(30,40) }
    }
    verifyEq(x.children, Widget[x.top, x.bottom])

    // preferred size
    verifyEq(x.prefSize, Size(30,60))

    // layout
    x.size = Size(100,100)
    x.onLayout
    verifyEq(x.top.bounds, Rect(0,0,100,20))
    verifyEq(x.bottom.bounds, Rect(0,60,100,40))

    // clear top, replace bottom
    x.top = null
    x.bottom = Fixed { ps = Size(100, 10) }
    verifyEq(x.children, Widget[x.bottom])
    verifyEq(x.prefSize, Size(100,10))

    // all five
    x.top    = Fixed { ps = Size(70, 10) }
    x.bottom = Fixed { ps = Size(70, 20) }
    x.left   = Fixed { ps = Size(30, 20) }
    x.right  = Fixed { ps = Size(40, 40) }
    x.center = Fixed { ps = Size(50, 30) }
    verifyEq(x.children, Widget[x.top, x.bottom, x.left, x.right, x.center])
    verifyEq(x.prefSize, Size(120,70))

    // layout
    x.size = Size(140,100)
    x.onLayout
    verifyEq(x.top.bounds,    Rect(0,0,140,10))
    verifyEq(x.bottom.bounds, Rect(0,80,140,20))
    verifyEq(x.left.bounds,   Rect(0,10,30,70))
    verifyEq(x.right.bounds,  Rect(100,10,40,70))
    verifyEq(x.center.bounds, Rect(30,10,70,70))
  }

  Void testGridPane()
  {
    x := GridPane { hgap = 10; vgap = 10; valignCells=Valign.top; numCols = 3 }
    a := Fixed { ps = Size(30,10) }; x.add(a)
    b := Fixed { ps = Size(20,10) }; x.add(b)
    c := Fixed { ps = Size(30,10) }; x.add(c)
    d := Fixed { ps = Size(20,20) }; x.add(d)
    e := Fixed { ps = Size(40,10) }; x.add(e)
    f := Fixed { ps = Size(10,20) }; x.add(f)
    g := Fixed { ps = Size(40,10) }; x.add(g)
    h := Fixed { ps = Size(30,20) }; x.add(h)

    // preferred size
    verifyEq(x.prefSize, Size(130,70))

    // layout
    x.size = Size(200,200)
    x.onLayout
    verifyEq(a.bounds, Rect(0,0,30,10))
    verifyEq(b.bounds, Rect(50,0,20,10))
    verifyEq(c.bounds, Rect(100,0,30,10))
    verifyEq(d.bounds, Rect(0,20,20,20))
    verifyEq(e.bounds, Rect(50,20,40,10))
    verifyEq(f.bounds, Rect(100,20,10,20))
    verifyEq(g.bounds, Rect(0,50,40,10))
    verifyEq(h.bounds, Rect(50,50,30,20))
  }

}

internal class Fixed : Widget
{
  Size ps := Size(10, 20)
  override Size prefSize(Hints hint := Hints.defVal) { return ps }
}
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Sep 08  Brian Frank  Creation
//

using fwt

**
** SideBarPane is used to manage the sidebars.
**
internal class SideBarPane : ContentPane
{

  new make(Frame frame, ViewTabPane tabPane)
  {
    this.frame  = frame
    this.content = SashPane
    {
      orientation = Orientation.horizontal
      weights = [200, 600, 200]
      add(left)
      SashPane
      {
        orientation = Orientation.vertical
        weights = [600, 200]
        add(tabPane)
        add(bottom)
      }
      add(right)
    }
  }

  SideBar sideBar(Type t, Bool make)
  {
    sb := sideBars.find |SideBar x->Bool| { return x.type === t }
    if (sb == null && make)
    {
      sb = t.make
      sb.frame = frame
      sideBars.add(sb)
    }
    return sb
  }

  Void show(SideBar sb)
  {
    pref := sb.prefAlign
    if (pref == Halign.left)
    {
      left.add(sb)
    }
    else if (pref == Halign.right)
    {
      right.add(sb)
    }
    else if (pref == Valign.bottom)
    {
      if (bottom.content != null) bottom.content->hide
      bottom.content = sb
    }
    else
    {
      throw Err("Invalid ${sb.type}.prefAlign $pref")
    }
    sb.parent.visible = true
    sb.parent.relayout
    sb.parent.parent.relayout
  }

  Void hide(SideBar sb)
  {
    parent := sb.parent
    if (parent == null) return
    if (parent is ContentPane)
      parent->content = null
    else
      parent.remove(sb)
    parent.visible = !parent.children.isEmpty
    parent.relayout
    parent.parent.relayout
  }

  readonly Frame frame
  SideBar[] sideBars := SideBar[,]
  SashPane left  := SashPane { visible=false; orientation = Orientation.vertical }
  SashPane right := SashPane { visible=false; orientation = Orientation.vertical }
  ContentPane bottom := ContentPane { visible=false }

}


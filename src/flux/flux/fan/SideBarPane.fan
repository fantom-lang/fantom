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

  SideBar? sideBar(Type t, Bool make)
  {
    sb := sideBars.find |SideBar x->Bool| { return x.type === t }
    if (sb == null && make)
    {
      sb = t.make
      sb.frame = frame
      sideBars.add(sb)
      try { sb.onLoad } catch (Err e) { e.trace }
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
    try { sb.onShow } catch (Err e) { e.trace }
  }

  Void hide(SideBar sb)
  {
    try { sb.onHide } catch (Err e) { e.trace }
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

  Void onActive(View view)
  {
    sideBars.each |SideBar sb|
    {
      try { if (sb.showing) sb.onActive(view) } catch (Err e) { e.trace }
    }
  }

  Void onInactive(View view)
  {
    sideBars.each |SideBar sb|
    {
      try { if (sb.showing) sb.onInactive(view) } catch (Err e) { e.trace }
    }
  }

  Void onUnload()
  {
    sideBars.each |SideBar sb|
    {
      try { sb.onUnload } catch (Err e) { e.trace }
    }
  }

  Void onMarks(Mark[] marks)
  {
    sideBars.each |SideBar sb|
    {
      try { if (sb.showing) sb.onMarks(marks) } catch (Err e) { e.trace }
    }
  }

  Void onGotoMark(Mark mark)
  {
    sideBars.each |SideBar sb|
    {
      try { if (sb.showing) sb.onGotoMark(mark) } catch (Err e) { e.trace }
    }
  }

  readonly Frame frame
  SideBar[] sideBars := SideBar[,]
  SashPane left  := SashPane { visible=false; orientation = Orientation.vertical }
  SashPane right := SashPane { visible=false; orientation = Orientation.vertical }
  ContentPane bottom := ContentPane { visible=false }

}


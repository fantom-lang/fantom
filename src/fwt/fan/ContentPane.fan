//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 08  Brian Frank  Creation
//

**
** ContentPane is the base class for panes which only
** contain one child widget called 'content'.
**
@collection=false
class ContentPane : Pane
{

//////////////////////////////////////////////////////////////////////////
// Children
//////////////////////////////////////////////////////////////////////////

  **
  ** The content child widget.
  **
  Widget content { set { remove(@content); Widget.super.add(val); @content = val } }

  **
  ** If this the first widget added, then assume it the content.
  **
  override This add(Widget child)
  {
    if (@content == null) @content=child
    super.add(child)
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  override Size prefSize(Hints hints := Hints.def)
  {
    if (content == null) return Size.def
    return content.prefSize(hints)
  }

  override Void onLayout()
  {
    if (content == null) return
    content.pos = Point.def
    content.size = this.size
  }

}
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 08  Brian Frank  Creation
//

using gfx

**
** ContentPane is the base class for panes which only
** contain one child widget called 'content'.
**
@Js
@Serializable
class ContentPane : Pane
{

//////////////////////////////////////////////////////////////////////////
// Children
//////////////////////////////////////////////////////////////////////////

  **
  ** The content child widget.
  **
  Widget? content { set { remove(&content); doAdd(it); &content = it } }

  **
  ** If this the first widget added, then assume it the content.
  **
  @Operator override This add(Widget? child)
  {
    if (&content == null) &content=child
    super.add(child)
    return this
  }

  **
  ** Internal hook to call Widget.add version directly and skip
  ** hook to implicitly mount any added child as content.
  **
  internal Void doAdd(Widget? child) { super.add(child) }

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  override Size prefSize(Hints hints := Hints.defVal)
  {
    if (content == null) return Size.defVal
    if (!visible) return Size.defVal
    return content.prefSize(hints)
  }

  override Void onLayout()
  {
    if (content == null) return
    content.pos = Point.defVal
    content.size = this.size
  }

}
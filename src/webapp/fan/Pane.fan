//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 May 09  Andy Frank  Creation
//

using web

**
** Pane is a Widget designed to contain child Widgets.
**
** See `docLib::WebWidget`
**
@collection
abstract class Pane : Widget
{

//////////////////////////////////////////////////////////////////////////
// Children
//////////////////////////////////////////////////////////////////////////

  **
  ** Iterate the children widgets.
  **
  Void each(|Widget w, Int i| f)
  {
    kids.each(f)
  }

  **
  ** Get the children widgets.
  **
  Widget[] children() { return kids.ro }

  **
  ** Add a child widget.  If child is null, then do nothing.
  ** Return this.
  **
  virtual This add(Widget? child)
  {
    if (child == null) return this
    kids.add(child)
    return this
  }

  **
  ** Remove a child widget.  If child is null, then do
  ** nothing.  If this widget is not the child's current
  ** parent throw ArgErr.  Return this.
  **
  virtual This remove(Widget? child)
  {
    if (child == null) return this
    if (kids.removeSame(child) == null)
      throw ArgErr("not my child: $child")
    return this
  }

  **
  ** Remove all child widgets.  Return this.
  **
  virtual This removeAll()
  {
    kids.dup.each |Widget kid| { remove(kid) }
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Private
//////////////////////////////////////////////////////////////////////////

  @transient
  private Widget[] kids := Widget[,]

}
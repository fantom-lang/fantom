//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 08  Brian Frank  Creation
//

using gfx

**
** Combo is a combination of a text field and a list drop down.
**
@Js
@Serializable
class Combo : Widget
{

  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** Callback when Return/Enter key is pressed.
  **
  ** Event id fired:
  **   - `EventId.action`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onAction() { EventListeners() }

  **
  ** Callback when either the text field or item is changed.
  **
  ** Event id fired:
  **   - `EventId.modified`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onModify() { EventListeners() }

  **
  ** If true then the list is displayed in a drop down
  ** window.  If false then the list is displayed directly
  ** under the text field.  Default is true.
  **
  const Bool dropDown := true

  **
  ** Set to true to display editing of the combo's text field.
  ** Default is false.
  **
  const Bool editable := false

  **
  ** The widget's current text.  Defaults to "".
  **
  native Str text

  **
  ** The list selection items displayed via 'Obj.toStr'.
  ** Defaults to the empty list.
  **
  native Obj[] items

  **
  ** Font for text. Defaults to null (system default).
  **
  native Font? font

  **
  ** The currently selected index of `items` or null if no selection.
  **
  @Transient native Int? selectedIndex

  **
  ** The currently selected item.  Items are matched
  ** to the `items` list using `index`.
  **
  @Transient Obj? selected
  {
    get { i := selectedIndex; return i == null ? null : items[i] }
    set { i := index(it); if (i != null) selectedIndex = i }
  }

  **
  ** Get the index of the specified item. Items are matched
  ** to indices via 'Obj.equals'.  See `sys::List.index`.
  **
  Int? index(Obj item) { return items.index(item) }


}
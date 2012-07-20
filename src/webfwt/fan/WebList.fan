//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jun 2011  Andy Frank  Creation
//

using fwt
using gfx

**
** WebList displays a set of objects as a List.
**
@Js
abstract class WebList : Pane
{
  ** Items to display for this list. Defaults to an empty list.
  native Obj[] items

  ** Get the index for the given item. By default, items are
  ** matched to indices by 'Obj.equals'.
  virtual Int? index(Obj item) { items.index(item) }

  ** Return 'false' to disable selection. Defaults to 'true'.
  virtual Bool selectionEnabled() { true }

  ** Selected item, or null if no selection.
  Obj? selected := null
  {
    set
    {
      index := index(it)
      if (index != null) { &selected=it; selectedIndex=index }
    }
  }

  ** Index of selected item, or null if no selection.
  Int? selectedIndex := null
  {
    set
    {
      if (it != null && (it < 0 || it >= items.size)) throw IndexErr("$it")
      &selected = it==null ? null : items[it]
      &selectedIndex = it
      updateSelection
    }
  }

  ** Update selection due to programtic changes.
  private native Void updateSelection()

  ** Callback before an item is selected. To cancel the following
  ** selection event, set 'Event.data' to the Str '"cancel"'
  **   - `fwt::Event.index`: index of selected item
  **   - `fwt::Event.data`: the selected item
  once EventListeners onBeforeSelect() { EventListeners() }

  ** Callback when an item is selected.
  **   - `fwt::Event.index`: index of selected item
  **   - `fwt::Event.data`: the selected item
  once EventListeners onSelect() { EventListeners() }

  ** Fire onBeforeSelect with given index - return false to cancel.
  private Bool fireBeforeSelect(Int index)
  {
    event := Event {
      it.id = EventId.select
      it.data = items[index]
      it.index = index
    }
    onBeforeSelect.fire(event)
    return event.data != "cancel"
  }

  ** Fire onSelect with given index.
  private Void fireSelect(Int index)
  {
    selected = items[index]
    selectedIndex = index
    onSelect.fire(Event {
      it.id = EventId.select
      it.data = selected
      it.index = selectedIndex
    })
  }

  native override Size prefSize(Hints hints := Hints.defVal)
  native override Void onLayout()
}

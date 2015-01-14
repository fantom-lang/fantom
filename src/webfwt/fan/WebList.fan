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
  @NoDoc
  virtual Bool selectionEnabled() { true }

  ** Get or set vertical scroll position.
  @NoDoc
  native Int scrolly

  ** Enable multiple selection.  Defaults to 'false' for single selection.
  Bool multi := false

  ** If non-null, reported for preferred width.
  Int? prefw := null

  ** If non-null, reported for preferred width.
  Int? prefh := null

  ** Selected item, or null if no selection.
  Obj[] selected := [,]
  {
    set
    {
      list := Int[,]
      it.each |item|
      {
        index := index(item)
        if (index != null) list.add(index)
      }
      &selected = it
      &selectedIndexes = list
      updateSelection
    }
  }

  ** Index of selected items, or empty list if no selection.
  Int[] selectedIndexes := [,]
  {
    set
    {
      &selected = it.map |i|
      {
        if (i < 0 || i >= items.size) throw IndexErr("$i")
        return items[i]
      }
      &selectedIndexes = it
      updateSelection
    }
  }

  ** Fix for old code
  @NoDoc Int? selectedIndex
  {
    get { selectedIndexes.first }
    set { selectedIndexes = it == null ? Int#.emptyList : [it] }
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

  ** Callback when an item is double-clicked.
  **   - `fwt::Event.index`: index of selected item
  **   - `fwt::Event.data`: the selected item
  once EventListeners onAction() { EventListeners() }

  ** Fire onBeforeSelect with given index - return false to cancel.
  private Bool fireBeforeSelect(Int[] index)
  {
    event := Event {
      it.id = EventId.select
      it.data = items[index.first]
      it.index = index.first
      it.widget = this
    }
    onBeforeSelect.fire(event)
    return event.data != "cancel"
  }

  ** Fire onSelect with given index.
  private Void fireSelect(Int[] index)
  {
    selectedIndexes = index
    onSelect.fire(Event {
      it.id = EventId.select
      it.data = selected.first
      it.index = selectedIndexes.first
      it.widget = this
    })
  }

  ** Fire onAction with current selection.
  private Void fireAction()
  {
    onAction.fire(Event {
      it.id = EventId.select
      it.data = selected.first
      it.index = selectedIndexes.first
      it.widget = this
    })
  }

  native override Size prefSize(Hints hints := Hints.defVal)
  native override Void onLayout()
}
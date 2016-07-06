//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Feb 2016  Andy Frank  Creation
//

using dom

**
** ListButton allows user selection of an item in a list by
** showing a listbox popup on button press.
**
** See also: [pod doc]`pod-doc#listButton`, `Button`, `ToggleButton`
**
@Js class ListButton : Button
{
  new make() : super()
  {
    this.style.addClass("domkit-ListButton")
    this.isList = true
    this.sel = ListButtonSelection(this)
    this.onPopup { makeLisbox }
  }

  ** The current list items.
  Obj[] items := Obj#.emptyList
  {
    set
    {
      &items = it
      sel.index = it.size==0 ? null : 0
      update
    }
  }

  ** Selection for list.
  Selection sel { private set }

  ** Callback when selected item has changed.
  Void onSelect(|This| f) { this.cbSelect = f }

  ** Callback to create an 'Elem' representation for a given list
  ** item.  If function does not return an 'Elem' instance, one will
  ** be created using 'toStr' of value.
  Void onElem(|Obj->Obj| f)
  {
    this.cbElem = f
    update
  }

  ** Update button content.
  internal Void update()
  {
    if (isCombo) return
    this.removeAll
    if (items.size > 0) this.add(makeElem(sel.item))
  }

  ** Fire select event.
  internal Void fireSelect() { cbSelect?.call(this) }

  ** Build listbox.
  private Popup makeLisbox()
  {
    menu := Menu {}
    items.each |item,i|
    {
      menu.add(MenuItem {
        it.style.addClass("domkit-ListButton-MenuItem")
        if (sel.index == i) it.style.addClass("sel")
        it.add(makeElem(item))
        it.onAction { sel.index=i; fireSelect }
      })
    }
    menu.select(sel.index)
    // menu.onOpen
    // {
    //   // TODO FIXIT: make event handles cumulative
    //   menu.focus
    //
    //   // TODO FIXIT: need onBeforeOpen - onOpen fires after
    //   // animation so we get a "jump" in the UI as result
    //   // scroll sel into view
    //   menu.scrollPos = Pos(0, menu.children[sel.index].pos.y)
    // }
    return menu
  }

  private Elem makeElem(Obj item)
  {
    v := cbElem == null ? item.toStr : cbElem(item)
    return v is Elem ? v : Elem { it.text=v.toStr }
  }

  private Func? cbSelect := null
  private Func? cbElem   := null
}

**************************************************************************
** ListButtonSelection
**************************************************************************

@Js internal class ListButtonSelection : IndexSelection
{
  new make(ListButton button) { this.button = button }
  override Int max() { button.items.size }
  override Obj toItem(Int index) { button.items[index] }
  override Int? toIndex(Obj item) { button.items.findIndex(item) }
  override Void onUpdate(Int[] oldIndexes, Int[] newIndexes) { button.update }
  private ListButton button
}
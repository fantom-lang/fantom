//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Feb 2016  Andy Frank  Creation
//

using dom
using graphics

**
** ListButton allows user selection of an item in a list by
** showing a listbox popup on button press.
**
** See also: [docDomkit]`docDomkit::Controls#listButton`,
** `Button`, `ToggleButton`
**
@Js class ListButton : Button
{
  new make() : super()
  {
    this.style.addClass("domkit-ListButton disclosure-list")
    this.sel = ListButtonSelection(this)
    this.onPopup { makeListbox }
    this.update

    // shift to align text
    this.popupOffset = Point(-12, 0)
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
    if (items.size == 0 || sel.item == null) this.add(Elem { it.text = "\u200b" })
    else this.add(makeElem(sel.item))
  }

  ** Fire select event.
  internal Void fireSelect() { cbSelect?.call(this) }

  ** Build listbox.
  private Popup makeListbox()
  {
    this.find = ""
    this.menu = Menu {}
    items.each |item,i|
    {
      elem := makeElem(item)
      menu.add(MenuItem {
        if (!isCombo)
        {
          it.style.addClass("domkit-ListButton-MenuItem")
          if (sel.index == i) it.style.addClass("sel")
        }
        it.add(elem)
        it.onAction { sel.index=i; fireSelect }
      })

      // TODO: temp hook to mark list items as disabled
      if (elem.style.hasClass("disabled")) menu.lastChild.enabled = false
    }
    menu.select(sel.index)
    menu.onCustomKeyDown = |Event e| { onMenuKeyDown(e) }
    return menu
  }

  private Elem makeElem(Obj item)
  {
    v := cbElem == null ? item.toStr : cbElem(item)
    return v is Elem ? v : Elem { it.text=v.toStr }
  }

  private Void onMenuKeyDown(Event e)
  {
    if (e.key.code.isAlphaNum)
    {
      find += e.key.code.toChar.lower
      ix := items.findIndex |i| { i.toStr.lower.startsWith(find) }
      if (ix != null) menu.select(ix)
    }
  }

  private Func? cbSelect := null
  private Func? cbElem   := null

  private Str find := ""  // onPopup
  private Menu? menu      // onPopup
}

**************************************************************************
** ListButtonSelection
**************************************************************************

@Js internal class ListButtonSelection : IndexSelection
{
  new make(ListButton button) { this.button = button }
  override Int max() { button.items.size }
  override Obj toItem(Int index) { button.items[index] }
  override Int? toIndex(Obj item) { button.items.findIndex |i| { i == item }}
  override Void onUpdate(Int[] oldIndexes, Int[] newIndexes) { button.update }
  private ListButton button
}
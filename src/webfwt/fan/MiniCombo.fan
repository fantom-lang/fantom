//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jan 11  Andy Frank  Creation
//

using fwt
using gfx

**
** MiniCombo.
**
@NoDoc
@Js
class MiniCombo : Pane
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Constructor.
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  ** Callback when item is selected.
  EventListeners onSelect := EventListeners() { private set }

  ** Text for button.  Defaults to "".
  native Str text

  ** List of selection items.
  Obj[] items := [,]

  ** Selected item.
  Obj selected
  {
    get { i := selectedIndex; return i == null ? "" : items[i] }
    set { i := index(it); if (i != null) selectedIndex = i }
  }

  ** Index of selected item.
  Int? selectedIndex
  {
    set { &selectedIndex=it; select }
  }

  ** Get index of specified item.
  Int? index(Obj item) { return items.index(item) }

//////////////////////////////////////////////////////////////////////////
// Widget
//////////////////////////////////////////////////////////////////////////

  override native Size prefSize(Hints hints := Hints.defVal)
  override Void onLayout() {}

//////////////////////////////////////////////////////////////////////////
// Popup
//////////////////////////////////////////////////////////////////////////

  private Void select()
  {
    text = selected.toStr
    relayout
  }

  private Void openDropDown()
  {
    vpane := VPane()
    popup := HudPopup
    {
      insets = Insets(6)
      body = ConstraintPane { minw=125; vpane, }
      onClose.add { dropDownClosed }
    }

    items.each |item,i|
    {
      vpane.add(BorderPane
      {
        it.onMouseUp.add
        {
          popup.close
          text = item.toStr
          relayout
          onSelect.fire(Event { id=EventId.select; it.widget=this; it.index=i; data=item })
        }
        insets = Insets(4)
        Label { it.text=item.toStr; fg=Color.white },
      })
    }

    popup.open(this, Point(0, size.h))
  }

  private native Void dropDownClosed()

}


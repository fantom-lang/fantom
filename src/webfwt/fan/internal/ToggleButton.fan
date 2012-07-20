//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Aug 10  Andy Frank  Creation
//

using fwt
using gfx

**
** ToggleButton.
**
@NoDoc
@Js
// TODO: leave as internal until needed
class ToggleButton : ContentPane
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Create new button group with text for buttons.
  new make(Str text)
  {
    content = BorderPane
    {
      border = Border("0,0,1,0 $borderOuter 0,0,5,5")
      it.onMouseUp.add
      {
        selected = !selected
        onSelect.fire( Event { id=EventId.select })
      }
      BorderPane
      {
        border = Border("$borderInner 5")
        Label { it.text=text; fg=fgNorm; font=Desktop.sysFontSmall; halign=Halign.center },
      },
    }
    select(selected)
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  ** Currently selected tab index.
  Bool selected := false
  {
    set { &selected=it; select(it) }
  }

  ** Select the tab at the given index.
  private Void select(Bool sel)
  {
    inner := (BorderPane)content->content
    inner.bg     = sel ? bgDown : bgNorm
    inner.insets = sel ? Insets(5,12,3,12) : Insets(4,12)
    inner.content->fg = sel ? fgDown : fgNorm
    relayout
  }

  ** EventListeners for select event.
  EventListeners onSelect := EventListeners()

//////////////////////////////////////////////////////////////////////////
// Customize
//////////////////////////////////////////////////////////////////////////

  ** Outer Border color.
  protected virtual Str borderOuter() { "#e0e0e0" }

  ** Outer Border color.
  protected virtual Str borderInner() { "#404040" }

  ** Background when normal.
  protected virtual Gradient bgNorm() { brushBgNorm }

  ** Background when pressed.
  protected virtual Gradient bgDown() { brushBgDown }

  ** Foreground when normal.
  protected virtual Color fgNorm() { Color.black }

  ** Foreground when pressed.
  protected virtual Color fgDown() { Color.white }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static const Gradient brushBgNorm := Gradient("0% 0%, 0% 100%, #fefefe, #cbcbcb")
  private static const Gradient brushBgDown := Gradient("0% 0%, 0% 100%, #1b54a5, #3d80df")

}


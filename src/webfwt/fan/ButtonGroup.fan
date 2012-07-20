//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 10  Andy Frank  Creation
//

using fwt
using gfx

**
** ButtonGroup.
**
@NoDoc
@Js
class ButtonGroup : ContentPane
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Create new button group with text for buttons.
  new make(Str[] text)
  {
    grid := GridPane
    {
      hgap = -1
      numCols = text.size
      uniformCols = true
      halignPane  = Halign.center
      halignCells = Halign.fill
    }
    text.each |t,i| { grid.add(button(t, i==0, i==text.size-1)) }
    content = grid
    select(null)
  }

  private Widget button(Str text, Bool right, Bool left)
  {
    pos := buttons.size

    Border? outer
    Border? inner

    bo := borderOuter  // #555
    bi := borderInner  // #131313

    if (right)     { outer=Border("0,0,1,0 $bo 0,0,0,5"); inner=Border("$bi 5,0,0,5") }
    else if (left) { outer=Border("0,0,1,0 $bo 0,0,5,0"); inner=Border("$bi 0,5,5,0") }
    else           { outer=Border("0,0,1,0 $bo");         inner=Border("$bi") }

    button := BorderPane
    {
      border = outer
      it.onMouseUp.add
      {
        select(pos)
        event := Event { id=EventId.select; widget=this; index=selected }
        onSelect.fire(event)
      }
      BorderPane
      {
        border = inner
        Label { it.text=text; fg=fgNorm; font=Desktop.sysFontSmall; halign=Halign.center },
      },
    }

    buttons.add(button)
    return button
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  ** Currently selected button index.
  Int? selected := null
  {
    set { select(it) }
  }

  ** Select the tab at the given index.
  private Void select(Int? pos)
  {
    // udpate widgets
    &selected = pos
    buttons.each |but,i|
    {
      sel   := &selected == i
      inner := (BorderPane)but.content
      inner.bg     = sel ? bgDown : bgNorm
      inner.insets = sel ? Insets(5,12,3,12) : Insets(4,12)
      inner.content->fg = sel ? fgDown : fgNorm
    }
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

  private BorderPane[] buttons := BorderPane[,]

  private static const Gradient brushBgNorm := Gradient("0% 0%, 0% 100%, #fefefe, #cbcbcb")
  private static const Gradient brushBgDown := Gradient("0% 0%, 0% 100%, #1b54a5, #3d80df")

}


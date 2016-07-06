//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 2015  Andy Frank  Creation
//

using dom

**
** ToggleButton models a boolean state toggled by pressing a button.
**
** See also: [pod doc]`pod-doc#toggleButton`, `Button`
**
@Js class ToggleButton : Button
{
  new make() : super()
  {
    this.style.addClass("domkit-ToggleButton")
  }

  ** Toggle selection state.
  Bool selected := false
  {
    set
    {
      &selected = it
      if (it)
      {
        showDown
        if (elemOn != null) removeAll.add(elemOn)
      }
      else
      {
        showUp
        if (elemOff != null) removeAll.add(elemOff)
      }
    }
  }

  ** Optional content to display when selected. If the argument
  ** is not an [Elem]`dom::Elem` instance, one will be created
  ** with text content using 'toStr'.
  Obj? elemOn := null
  {
    set { val := it; &elemOn = it is Elem ? val : Elem { it.text=val.toStr }}
  }

  ** Optional content to display when not selected. If the argument
  ** is not an [Elem]`dom::Elem` instance, one will be created
  ** with text content using 'toStr'.
  Obj? elemOff := null
  {
    set { val := it; &elemOff = it is Elem ? val : Elem { it.text=val.toStr }}
  }

  internal override Void doMouseUp()
  {
    if (mouseDown) selected = !selected
  }
}
//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jul 2015  Andy Frank  Creation
//

using dom

**
** RadioButton displays a radio button.  RadioButtons must belong to
** a RadioButtonGroup, where only one button in the group can be
** selected at a time.
**
** See also: [pod doc]`pod-doc#radio`
**
@Js class RadioButton : Elem
{
  new make() : super("input")
  {
    this.set("type", "radio")
    this.style.addClass("domkit-RadioButton")
    // this.onEvent("change", false) |e| { fireAction(e) }
  }

  ** Wrap this checkbox with content that can also be
  ** clicked to toggle checkbox.
  Elem wrap(Obj content)
  {
    Elem("label")
    {
      this,
      content is Elem
        ? content
        : Elem("span") { it.style.addClass("domkit-RadioButton-label"); it.text=content.toStr },
    }
  }

  ** Value of checked.
  // TODO
  // Bool checked
  // {
  //   get { this->checked }
  //   set { this->checked = it }
  // }

  // ** Callback when state is toggled.
  // Void onAction(|This| f) { this.cbAction = f }
  //
  // private Void fireAction(Event e) { cbAction?.call(this) }
  // private Func? cbAction := null
}
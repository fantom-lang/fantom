//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jul 2015  Andy Frank  Creation
//

using dom

**
** Checkbox displays a checkbox that can be toggled on and off.
**
** See also: [docDomkit]`docDomkit::Controls#checkbox`
**
@Js class Checkbox : Elem
{
  new make() : super("input")
  {
    this.set("type", "checkbox")
    this.style.addClass("domkit-Checkbox")
    this.onEvent("change", false) |e| { fireAction(e) }
  }

  ** Wrap this checkbox with content that can also be
  ** clicked to toggle checkbox.
  Elem wrap(Obj content)
  {
    Elem("label")
    {
      this,
      content is Elem ? content : Label { it.text=content.toStr },
    }
  }

  ** Get or set indeterminate flag.
  Bool indeterminate
  {
    get { this->indeterminate }
    set { this->indeterminate = it }
  }

  ** Value of checked.
  Bool checked
  {
    get { this->checked }
    set { this->checked = it }
  }

  ** Callback when state is toggled.
  Void onAction(|This| f) { this.cbAction = f }

  private Void fireAction(Event e) { cbAction?.call(this) }
  private Func? cbAction := null
}
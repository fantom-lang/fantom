//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 2014  Andy Frank  Creation
//

using dom

**
** Text field input element.
**
** See also: [docDomkit]`docDomkit::Controls#textField`
**
@Js class TextField : Elem
{
  new make() : super("input")
  {
    this.set("type", "text")
    this.style.addClass("domkit-control domkit-control-text domkit-TextField")
    this.onEvent("input", false) |e|
    {
      checkUpdate
      fireModify(e)
    }
    this.onEvent("keydown", false) |e|
    {
      onKeyDown(e)
    }
  }

  ** Preferred width of field in columns, or 'null' for default.
  Int? cols
  {
    get { this->size }
    set { this->size = it }
  }

  ** Hint that is displayed in the field before a user enters a
  ** value that describes the expected input, or 'null' for no
  ** placeholder text.
  Str? placeholder
  {
    get { this->placeholder }
    set { this->placeholder = it }
  }

  ** Set to 'true' to set field to readonly mode.
  Bool ro
  {
    get { this.prop("readOnly") }
    set { this.setProp("readOnly", it) }
  }

  ** Set to 'true' to mask characters inputed into field.
  Bool password
  {
    get { this->type == "password" }
    set { this->type = it ? "password" : "text" }
  }

  ** Value of text field.
  Str val
  {
    get { this->value }
    set { this->value = it; checkUpdate }
  }

  ** Callback when value is modified by user.
  Void onModify(|This| f) { this.cbModify = f }

  ** Callback when 'enter' key is pressed.
  Void onAction(|This| f) { this.cbAction = f }

  ** Select given range of text
  Void select(Int start, Int end)
  {
    setProp("selectionStart", start)
    setProp("selectionEnd", end)
  }

  // framework use only
  @NoDoc protected virtual Void onKeyDown(Event e)
  {
    if (e.key == Key.enter) fireAction(e)
  }

  // framework use only
  @NoDoc protected Void fireAction(Event? e) { cbAction?.call(this) }
  private Func? cbAction := null

  // framework use only
  @NoDoc protected Void fireModify(Event? e) { cbModify?.call(this) }
  private Func? cbModify := null

  // framework use only
  private Void checkUpdate()
  {
    if (parent is Combo) ((Combo)parent).update(val.trim)
  }
}
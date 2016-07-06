//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 2014  Andy Frank  Creation
//

using dom

**
** Text field input element
**
@Js class TextField : Elem
{
  new make() : super("input")
  {
    this.set("type", "text")
    this.style.addClass("domkit-TextField").addClass("domkit-border")
    this.onEvent(EventType.input, false) |e| { fireModify(e) }
    this.onEvent(EventType.keyDown, false) |e|
    {
      if (e.key == Key.enter) fireAction(e)
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
    get { this.get("readonly") }
    set { this.set("readonly", it) }
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
    set { this->value = it }
  }

  ** Callback when value is modified by user.
  Void onModify(|This| f) { this.cbModify = f }

  ** Callback when 'enter' key is pressed.
  Void onAction(|This| f) { this.cbAction = f }

  ** Select given range of text
  Void select(Int start, Int end)
  {
    set("selectionStart", start)
    set("selectionEnd", end)
  }

  internal Void fireAction(Event? e) { cbAction?.call(this) }
  private Func? cbAction := null

  private Void fireModify(Event? e) { cbModify?.call(this) }
  private Func? cbModify := null
}
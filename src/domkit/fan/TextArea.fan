//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 2014  Andy Frank  Creation
//

using dom

**
** Multi-line text input element
**
@Js class TextArea : Elem
{
  new make() : super("textarea")
  {
    this.style.addClass("domkit-TextArea").addClass("domkit-border")
    this.onEvent(EventType.input, false) |e| { fireModify(e) }
  }

  ** Preferred width of text area in columns, or 'null' for default.
  Int? cols
  {
    get { this->cols }
    set { this->cols = it }
  }

  ** Preferred height of text area in rows, or 'null' for default.
  Int? rows
  {
    get { this->rows }
    set { this->rows = it }
  }

  ** Hint that is displayed in the text area before a user enters
  ** value that describes the expected input, or 'null' for no
  ** placeholder text.
  Str? placeholder
  {
    get { this->placeholder }
    set { this->placeholder = it }
  }

  ** Set to 'true' to set text area to readonly mode.
  Bool ro
  {
    get { this.get("readonly") }
    set { this.set("readonly", it) }
  }

  ** Value of text area.
  Str val
  {
    get { this->value }
    set { this->value = it }
  }

  ** Callback when value is modified by user.
  Void onModify(|This| f) { this.cbModify = f }

  private Void fireModify(Event e) { cbModify?.call(this) }
  private Func? cbModify := null
}
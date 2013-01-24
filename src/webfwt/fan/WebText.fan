//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Sep 2011  Andy Frank  Creation
//

using fwt
using gfx

**
** WebText extends Text with additional functionality.
**
@Js
class WebText : Text
{
  ** Constructor.
  new make(|This|? f := null) : super(f) {}

  ** Placeholder text to display in text field if empty.
  Str? placeHolder := null

  ** Placeholder text color, or null for default.
  Color? placeHolderColor := null

  ** Insets between text and border, or null for default.
  Insets? insets := null

  ** Border for text field, or null for default.
  Border? textBorder := null

  ** Inner shadow, or null for none.
  Shadow? innerShadow := null

  ** Drop shadow, or null for none.
  Shadow? dropShadow := null

  ** Image to display inside widget, or null for none.
  Image? image := null

  ** Halign of image.  Supoported values: 'left' and 'right'.
  Halign halignImage := Halign.right

  ** Override style. Defaults to null.
  [Str:Str]? style := null

  ** Override disabled style. Defaults to null.
  [Str:Str]? disabledStyle := null

  override Size prefSize(Hints hints := Hints.defVal)
  {
    pref := super.prefSize(hints)
    w := pref.w
    h := pref.h

    if (dropShadow != null)
      h += dropShadow.offset.y + dropShadow.blur + dropShadow.spread

    return Size(w,h)
  }

  // force peer
  private native Void dummy()
}


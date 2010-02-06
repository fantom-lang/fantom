//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 08  Brian Frank  Creation
//

using gfx

**
** Label displays text and/or an image.
**
@Js
@Serializable
class Label : Widget
{

  **
  ** Text of the label. Defaults to "".
  **
  native Str text

  **
  ** Image to display on label. Defaults to null.
  **
  native Image? image

  **
  ** Foreground color. Defaults to null (system default).
  **
  native Color? fg

  **
  ** Background color. Defaults to null (system default).
  **
  native Color? bg

  **
  ** Font for text. Defaults to null (system default).
  **
  native Font? font

  **
  ** Horizontal alignment. Defaults to left.
  **
  native Halign halign

}
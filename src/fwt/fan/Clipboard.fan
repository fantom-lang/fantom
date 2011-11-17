//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 11  Brian Frank  Creation
//

using gfx

**
** Clipboard provides access to the system clipboard for data transfer.
** Access is via `Desktop.clipboard`.
**
@Js
class Clipboard
{
  **
  ** Get the current clipboard contents as plain text or null
  ** if clipboard doesn't contain text data.
  **
  native Str? getText()

  **
  ** Set the clipboard contents to given plain text data.
  **
  native Void setText(Str data)
}
//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun May 09  Andy Frank  Creation
//

using gfx
using fwt

**
** Hyperlink adds link support to WebLabels.
**
@Js
class Hyperlink : WebLabel
{
  ** The uri to hyperlink to if widget is clicked. Defaults to "#".
  native Uri uri

  ** Link target.
  Str target := "_self"

  ** Underline mode for hyperlink.
  UnderlineMode underline := UnderlineMode.underline

  ** Callback to invoke before link is followed.
  once EventListeners onBefore() { EventListeners() }
}

**************************************************************************
** HyperlinkTarget
**************************************************************************
@Js
enum class HyperlinkTarget
{
  underline,
  hover,
  none
}

**************************************************************************
** UnderlineMode
**************************************************************************
@Js
enum class UnderlineMode
{
  underline,
  hover,
  none
}



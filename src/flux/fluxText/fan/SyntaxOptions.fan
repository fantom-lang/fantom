//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Aug 08  Brian Frank  Creation
//

using gfx
using fwt
using flux

**
** SyntaxOptions configures the syntax color coding
** initialized from fluxText symbols.
**
**
@serializable
const class SyntaxOptions
{

  new make(|This|? f := null) { if (f != null) f(this) }

  const Font font                   := @styleFont.val ?: Desktop.sysFontMonospace
  const Color highlightCurLine      := @styleHighlightCurLine.val
  const RichTextStyle text          := @styleText.val
  const RichTextStyle bracket       := @styleBracket.val
  const RichTextStyle bracketMatch  := @styleBracketMatch.val
  const RichTextStyle keyword       := @styleKeyword.val
  const RichTextStyle literal       := @styleLiteral.val
  const RichTextStyle comment       := @styleComment.val

}
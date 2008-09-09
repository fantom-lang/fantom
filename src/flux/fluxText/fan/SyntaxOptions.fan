//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Aug 08  Brian Frank  Creation
//

using fwt
using flux

**
** SyntaxOptions configures the syntax color coding.
**
@serializable
const class SyntaxOptions
{

//////////////////////////////////////////////////////////////////////////
// Rule
//////////////////////////////////////////////////////////////////////////

  ** Map of file extension to rule names.  The rule name should
  ** map to a SyntaxRules file called "syntax/syntax-{name}.fog".
  ** Extensions are matched to rules as follows:
  **   1. if match found for 'file.ext', then it takes precedence
  **   2. if the first line has shebang, then we attempt to
  **      match as "#!/bin/ext" or "#!/bin/env ext"
  **   3. use default rules
  const Str:Str extToRules := ["fan":"fan"]

//////////////////////////////////////////////////////////////////////////
// Styling
//////////////////////////////////////////////////////////////////////////

  const Font font                   := Font("Courier New", 9)
  const RichTextStyle text          := RichTextStyle { fg = Color(0x00_00_00) }
  const RichTextStyle bracket       := RichTextStyle { fg = Color(0xff_00_00) }
  const RichTextStyle bracketMatch  := RichTextStyle { fg = Color(0xff_00_00); bg=Color(0xff_ff_00); }
  const RichTextStyle keyword       := RichTextStyle { fg = Color(0x00_00_ff) }
  const RichTextStyle literal       := RichTextStyle { fg = Color(0x77_00_77) }
  const RichTextStyle comment       := RichTextStyle { fg = Color(0x00_77_00) }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  internal static SyntaxOptions load()
  {
    return Flux.loadOptions("syntax", SyntaxOptions#)
  }
}




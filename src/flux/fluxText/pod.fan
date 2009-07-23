//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jul 08  Brian Frank  Original
//   17 Jul 09  Brian Frank  Create from "build.fan"
//

using gfx
using fwt

**
** Flux: Text Editor
**

@podDepends = [Depend("sys 1.0"),
               Depend("gfx 1.0"),
               Depend("fwt 1.0"),
               Depend("flux 1.0")]
@podSrcDirs = [`fan/`, `test/`]
@podResDirs = [`locale/`]

pod fluxText
{

//////////////////////////////////////////////////////////////////////////
// Symbols
//////////////////////////////////////////////////////////////////////////

  ** Map of file extension to rule names.  The rule name should
  ** map to a SyntaxRules file called "syntax/syntax-{name}.fog".
  ** Extensions are matched to rules as follows:
  **   1. if match found for 'file.ext', then it takes precedence
  **   2. if the first line has shebang, then we attempt to
  **      match as "#!/bin/ext" or "#!/bin/env ext"
  **   3. use default rules
  virtual Str:Str extToRules := ["fan":"fan"]

  ** Default line end delimiter to use when saving text files.
  ** Note that loading text files will accept any combination
  ** of "\n", "\r", or "\r\n" - but that if the doc is saved
  ** then this line ending is applied.  Default is "\n".
  virtual Str lineDelimiter := "\n"

  ** If true, then trailing whitespace on each text
  ** line is strip on save.  Default is true.
  virtual Bool stripTrailingWhitespace := true

  ** Number of spaces to use for a tab.  Default is 2.
  virtual Int tabSpacing := 2

  ** If true, then all tabs to converted to space characters
  ** based on the configured `@tabSpacing`.  The default is true.
  virtual Bool convertTabsToSpaces := true

  ** Default char encoding to use when load/saving
  ** text files.  Defaults to utf8.
  virtual Charset charset := Charset("UTF-8")

//////////////////////////////////////////////////////////////////////////
// Styling Symbols
//////////////////////////////////////////////////////////////////////////

  virtual Font? styleFont                  := null
  virtual Color styleHighlightCurLine      := Color("#fff")
  virtual RichTextStyle styleText          := RichTextStyle { fg = Color("#000") }
  virtual RichTextStyle styleBracket       := RichTextStyle { fg = Color("#f00") }
  virtual RichTextStyle styleBracketMatch  := RichTextStyle { fg = Color("#f00"); bg=Color("#ff0"); }
  virtual RichTextStyle styleKeyword       := RichTextStyle { fg = Color("#00f") }
  virtual RichTextStyle styleLiteral       := RichTextStyle { fg = Color("#007777") }
  virtual RichTextStyle styleComment       := RichTextStyle { fg = Color("#007700") }

}


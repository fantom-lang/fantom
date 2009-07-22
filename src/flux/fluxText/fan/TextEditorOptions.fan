//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 08  Brian Frank  Creation
//

using flux

**
** TextEditorOptions configured from fluxText symbols.
**
@serializable
const class TextEditorOptions
{
  ** Default constructor with it-block
  new make(|This|? f := null) { if (f != null) f(this) }

  ** Default line end delimiter to use when saving text files.
  ** Note that loading text files will accept any combination
  ** of "\n", "\r", or "\r\n" - but that if the doc is saved
  ** then this line ending is applied.  Default is "\n".
  const Str lineDelimiter := @lineDelimiter.val

  ** If true, then trailing whitespace on each text
  ** line is strip on save.  Default is true.
  const Bool stripTrailingWhitespace := @stripTrailingWhitespace.val

  ** Number of spaces to use for a tab.  Default is 2.
  const Int tabSpacing := @tabSpacing.val

  ** If true, then all tabs to converted to space characters
  ** based on the configured `tabSpacing`.  The default is true.
  const Bool convertTabsToSpaces := @convertTabsToSpaces.val

  ** Default char encoding to use when load/saving
  ** text files.  Defaults to utf8.
  const Charset charset := @charset.val

}


//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 08  Brian Frank  Creation
//

using flux

**
** TextEditorOptions configured general text document options.
**
@Serializable
const class TextEditorOptions
{
  ** Default constructor with it-block
  new make(|This|? f := null) { if (f != null) f(this) }

  ** Default line end delimiter to use when saving text files.
  ** Note that loading text files will accept any combination
  ** of "\n", "\r", or "\r\n" - but that if the doc is saved
  ** then this line ending is applied.  Default is "\n".
  const Str lineDelimiter := "\n"

  ** If true, then trailing whitespace on each text
  ** line is strip on save.  Default is true.
  const Bool stripTrailingWhitespace := true

  ** Number of spaces to use for a tab.  Default is 2.
  const Int tabSpacing := 2

  ** If true, then all tabs to converted to space characters
  ** based on the configured `tabSpacing`.  The default is true.
  const Bool convertTabsToSpaces := true

  ** Default char encoding to use when load/saving
  ** text files.  Defaults to utf8.
  const Charset charset := Charset.utf8

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  internal static TextEditorOptions load()
  {
    return Flux.loadOptions(TextEditorOptions#.pod, "text-editor", TextEditorOptions#)
  }
}


//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Nov 2024  Matthew Giannini  Creation
//

**
** Mixin for parser/renderer extensions.
**
** Markdown extensions encapsulate all the modifications to the parser/renderer
** to support a given markdown "feature" (e.g. tables, strikethrough, etc.). The are
** registered using the methods on the various builders.
**
@Js
mixin MarkdownExt
{
  ** Callback to extend the parser. Default implementation does nothing.
  virtual Void extendParser(ParserBuilder builder) { }

  ** Callback to extend the HTML renderer. Default implementation does nothing.
  virtual Void extendRenderer(HtmlRendererBuilder builder) { }
}
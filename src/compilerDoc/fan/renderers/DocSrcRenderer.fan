//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 11  Brian Frank  Creation
//

using web
using syntax

**
** Renders DocSrc documents.
**
**   <div class='src'>
**    {SyntaxHtmlWriter.writeLines}
**   </div>
**
class DocSrcRenderer : DocRenderer
{
  new make(DocEnv env, WebOutStream out, DocSrc doc)
    : super(env, out, doc)
  {
    this.src = doc
  }

  ** Source document to renderer
  const DocSrc src

  override Void writeContent()
  {
    // rules for extension
    rules := SyntaxRules.loadForExt(src.uri.ext ?: "?") ?: SyntaxRules()

    // read source and parse into syntax document
    SyntaxDoc? syntaxDoc
    zip := Zip.open(src.pod.file)
    try
      syntaxDoc = SyntaxDoc.parse(rules, zip.contents[src.uri].in)
    finally
      zip.close

    // render
    out.div("class='src'")
    HtmlSyntaxWriter(out).writeLines(syntaxDoc)
    out.divEnd
  }
}


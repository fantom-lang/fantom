//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   09 Oct 2024  Matthew Giannini  Creation
//

**
** Paragraph parser
**
@Js
internal class ParagraphParser : BlockParser
{
  new make() { }

  private LinkReferenceDefinitionParser linkRefDefParser := LinkReferenceDefinitionParser()

//////////////////////////////////////////////////////////////////////////
// BlockParser
//////////////////////////////////////////////////////////////////////////

  override Paragraph block := Paragraph() { private set }

  override const Bool canHaveLazyContinuationLines := true

  override BlockContinue? tryContinue(ParserState state)
  {
    if (!state.isBlank)
      return BlockContinue.atIndex(state.index)
    else
      return BlockContinue.none
  }

  override Void addLine(SourceLine line)
  {
    linkRefDefParser.parse(line)
  }

  override Void addSourceSpan(SourceSpan sourceSpan)
  {
    // some source spans might belong to link reference definitions, others to paras.
    // the parser will handle that.
    linkRefDefParser.addSourceSpan(sourceSpan)
  }

  override DefinitionMap[] definitions()
  {
    map := DefinitionMap(LinkReferenceDefinition#)
    linkRefDefParser.linkRefDefs.each |def| { map.putIfAbsent(def.label, def) }
    return [map]
  }

  override Void closeBlock()
  {
    linkRefDefParser.linkRefDefs.each |def| { block.insertBefore(def) }

    if (linkRefDefParser.paragraphLines.isEmpty) block.unlink
    else block.setSourceSpans(linkRefDefParser.paraSourceSpans)
  }

  override Void parseInlines(InlineParser inlineParser)
  {
    lines := linkRefDefParser.paragraphLines
    if (!lines.isEmpty) inlineParser.parse(lines, block)
  }

  SourceLines paragraphLines() { linkRefDefParser.paragraphLines }
}
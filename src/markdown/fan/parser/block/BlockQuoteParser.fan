//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

**
** Block quote parser
**
@Js
internal class BlockQuoteParser : BlockParser
{
  new make()
  {
  }

  override BlockQuote block := BlockQuote() { private set }

  override const Bool isContainer := true

  override Bool canContain(Block block) { true }

  override BlockContinue? tryContinue(ParserState state)
  {
    nextNonSpace := state.nextNonSpaceIndex
    if (isMarker(state, nextNonSpace))
    {
      newColumn := state.column + state.indent + 1
      // optional following space or tab
      if (Chars.isSpaceOrTab(state.line.content, nextNonSpace+1)) ++newColumn
      return BlockContinue.atColumn(newColumn)
    }
    return BlockContinue.none
  }

  internal static Bool isMarker(ParserState state, Int index)
  {
    line := state.line.content
    return state.indent < Parsing.code_block_indent && index < line.size && line[index] == '>'
  }

  static const BlockParserFactory factory := BlockQuoteParserFactory()
}

**************************************************************************
** BlockQuoteParserFactory
**************************************************************************

@Js
internal const class BlockQuoteParserFactory : BlockParserFactory
{
  override BlockStart? tryStart(ParserState state, MatchedBlockParser parser)
  {
    nextNonSpace := state.nextNonSpaceIndex
    if (BlockQuoteParser.isMarker(state, nextNonSpace))
    {
      newColumn := state.column + state.indent + 1
      // optinal following space or tab
      if (Chars.isSpaceOrTab(state.line.content, nextNonSpace+1)) ++newColumn
      return BlockStart.of([BlockQuoteParser()]).atColumn(newColumn)
    }
    return BlockStart.none
  }
}
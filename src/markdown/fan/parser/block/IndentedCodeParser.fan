//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 2024  Matthew Giannini  Creation
//

**
** Indented code parser
**
@Js
class IndentedCodeParser : BlockParser
{
  new make()
  {
  }

  override IndentedCode block := IndentedCode() { private set }
  private Str[] lines := [,]

  override BlockContinue? tryContinue(ParserState state)
  {
    if (state.indent >= Parsing.code_block_indent)
      return BlockContinue.atColumn(state.column + Parsing.code_block_indent)
    else if (state.isBlank)
      return BlockContinue.atIndex(state.nextNonSpaceIndex)
    else
      return BlockContinue.none
  }

  override Void addLine(SourceLine line) { lines.add(line.content) }

  override Void closeBlock()
  {
    lastNonBlank := lines.size - 1
    while (lastNonBlank >= 0)
    {
      if (!Chars.isBlank(lines[lastNonBlank])) break
      --lastNonBlank
    }

    sb := StrBuf()
    for (i := 0; i < lastNonBlank + 1; ++i)
    {
      sb.add(lines[i]).addChar('\n')
    }
    block.literal = sb.toStr
  }

  static const BlockParserFactory factory := IndentedCodeParserFactory()
}

**************************************************************************
** Factory
**************************************************************************

@Js
internal const class IndentedCodeParserFactory : BlockParserFactory
{
  override BlockStart? tryStart(ParserState state, MatchedBlockParser parser)
  {
    // an indented code block cannot interrupt a paragraph
    if (state.indent >= Parsing.code_block_indent
        && !state.isBlank
        && (state.activeBlockParser.block isnot Paragraph))
    {
      return BlockStart.of([IndentedCodeParser()])
        .atColumn(state.column + Parsing.code_block_indent)
    }
    return BlockStart.none
  }
}

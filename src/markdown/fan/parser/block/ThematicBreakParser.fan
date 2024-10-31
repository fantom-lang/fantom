//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 2024  Matthew Giannini  Creation
//

**
** Thematic break parser
**
@Js
class ThematicBreakParser : BlockParser
{
  new make(Str literal)
  {
    this.block = ThematicBreak(literal)
  }

  override ThematicBreak block { private set }

  override BlockContinue? tryContinue(ParserState state)
  {
    // a horizontal rule can never contain > 1 line, so fail to match
    BlockContinue.none
  }

  static const BlockParserFactory factory := ThematicBreakParserFactory()
}

**************************************************************************
** Factory
**************************************************************************

@Js
internal const class ThematicBreakParserFactory : BlockParserFactory
{
  override BlockStart? tryStart(ParserState state, MatchedBlockParser parser)
  {
    if (state.indent >= 4) return BlockStart.none

    nextNonSpace := state.nextNonSpaceIndex
    line := state.line.content
    if (isThematicBreak(line, nextNonSpace))
    {
      literal := line[state.index..-1]
      return BlockStart.of([ThematicBreakParser(literal)]).atIndex(line.size)
    }
    return BlockStart.none
  }

  ** spec: a line consisting of 0-3 spaces of indentation, followed by a sequence of
  ** three or more matching -, _, or * characters, each followed by any number of spaces,
  ** forms a thematic break.
  private static Bool isThematicBreak(Str line, Int index)
  {
    dashes := 0
    underscores := 0
    stars := 0
    len := line.size
    for (i := index; i < len; ++i)
    {
      switch (line[i])
      {
        case '-': ++dashes
        case '_': ++underscores
        case '*': ++stars
        case ' ':
        case '\t':
          // fall-through
          // allowed, even between markers
          continue
        default:
          return false
      }
    }
    return ((dashes >= 3 && underscores == 0 && stars == 0) ||
            (underscores >= 3 && dashes == 0 && stars == 0) ||
            (stars >= 3 && dashes == 0 && underscores == 0))
  }
}
//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

**
** Heading parser
**
@Js
internal class HeadingParser : BlockParser
{
  new make(Int level, SourceLines content)
  {
    this.block = Heading(level)
    this.content = content
  }

  SourceLines content { private set }

  override Heading block { private set }

  override BlockContinue? tryContinue(ParserState state)
  {
    // in both ATX and Setext headings, once we have the heading markup,
    // there's nothing more to parse
    BlockContinue.none
  }

  override Void parseInlines(InlineParser parser) { parser.parse(content, block) }

  static const BlockParserFactory factory := HeadingParserFactory()
}

**************************************************************************
** HeadingParserFactory
**************************************************************************

@Js
internal const class HeadingParserFactory : BlockParserFactory
{
  override BlockStart? tryStart(ParserState state, MatchedBlockParser parser)
  {
    if (state.indent >= Parsing.code_block_indent) return BlockStart.none

    // ATX heading
    line := state.line
    nextNonSpace := state.nextNonSpaceIndex
    if (line.content[nextNonSpace] == '#')
    {
      atxHeading := toAtxHeading(line.substring(nextNonSpace, line.content.size))
      if (atxHeading != null)
        return BlockStart.of([atxHeading]).atIndex(line.content.size)
    }

    // Setext heading
    setextHeadingLevel := toSetextHeadingLevel(line.content, nextNonSpace)
    if (setextHeadingLevel > 0)
    {
      para := parser.paragraphLines
      if (!para.isEmpty)
      {
        return BlockStart.of([HeadingParser(setextHeadingLevel, para)])
          .atIndex(line.content.size)
          .withReplaceParagraphLines(para.lines.size)
      }
    }

    return BlockStart.none
  }

  ** spec: An ATX heading consists of a string of characters, parsed as inline content,
  ** between an opening sequence of 1-6 unescaped # characters and an optional closing
  ** sequence of any number of unescaped # characters. The opening
  ** sequence of # characters must be followed by a space or by the end of line.
  ** The optional closing sequence of #s must be preceded by a space and may be
  ** followed by spaces only.
  private static HeadingParser? toAtxHeading(SourceLine line)
  {
    scanner := Scanner(line)
    level := scanner.matchMultiple('#')

    if (level == 0 || level > 6) return null

    if (!scanner.hasNext)
    {
      // end of line after markers is an empty heading
      return HeadingParser(level, SourceLines.empty)
    }

    next := scanner.peek
    if (!(next == ' ' || next == '\t')) return null

    scanner.whitespace
    start := scanner.pos
    end := start
    hashCanEnd := true

    while (scanner.hasNext)
    {
      c := scanner.peek
      switch (c)
      {
        case '#':
          if (hashCanEnd)
          {
            scanner.matchMultiple('#')
            whitespace := scanner.whitespace
            // if there's other characters, the hashes and spaces were part of the heading
            if (scanner.hasNext) end = scanner.pos
            hashCanEnd = whitespace > 0
          }
          else
          {
            scanner.next
            end = scanner.pos
          }
        case ' ':
        case '\t':
          // fall-through
          hashCanEnd = true
          scanner.next
        default:
          hashCanEnd = false
          scanner.next
          end = scanner.pos
      }
    }

    source := scanner.source(start, end)
    return source.content.isEmpty
      ? HeadingParser(level, SourceLines.empty)
      : HeadingParser(level, source)
  }

  ** spec: A setext heading underline is a sequence of = characters or a
  ** sequence of - characters, with no more than 3 spaces indentation and
  ** any number of trailing spaces.
  private static Int toSetextHeadingLevel(Str line, Int index)
  {
    switch (line[index])
    {
      case '=':
        if (isSetextHeadingRest(line, index+1, '=')) return 1
      case '-':
        if (isSetextHeadingRest(line, index+1, '-')) return 2
    }
    return 0
  }

  private static Bool isSetextHeadingRest(Str line, Int index, Int marker)
  {
    afterMarker := Chars.skip(marker, line, index, line.size)
    afterSpace := Chars.skipSpaceTab(line, afterMarker, line.size)
    return afterSpace >= line.size
  }
}

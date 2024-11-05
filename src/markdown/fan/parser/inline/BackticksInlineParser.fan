//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

**
** Configurable inline code parser base class. Parses a 'marker' code span, or
** a literal sequence of 'marker' characters
**
@Js
@NoDoc abstract class InlineCodeParser : InlineContentParser
{
  new make(Int markerChar)
  {
    this.markerChar = markerChar
  }

  protected const Int markerChar
  private Int maxMarkers := Int.maxVal
  This withMaxMarkers(Int max) { this.maxMarkers = 1.max(max); return this }

  override ParsedInline? tryParse(InlineParserState state)
  {
    scanner := state.scanner
    start := scanner.pos
    openingMarkers := scanner.matchMultiple(markerChar)
    afterOpening := scanner.pos

    if (openingMarkers > this.maxMarkers) return ParsedInline.none

    while (scanner.find(markerChar) > 0)
    {
      beforeClosing := scanner.pos
      count := scanner.matchMultiple(markerChar)
      if (count == openingMarkers)
      {
        content := scanner.source(afterOpening, beforeClosing).content
        content = content.replace("\n", " ")

        // spec: if the resulting string both begins and ends with a space character,
        // but does not consist entirely of space characters, a single space
        // character is removed from the front and back.
        if (content.size >= 3 &&
             content[0] == ' ' && content[-1] == ' ' && Chars.hasNonSpace(content))
        {
          content = content[1..<content.size-1]
        }
        node := Code(content)
        return ParsedInline.of(node, scanner.pos)
      }
    }

    // if we got here, we didn't find a matching closing markerChar sequence.
    source := scanner.source(start, afterOpening)
    text := Text(source.content)
    return ParsedInline.of(text, afterOpening)
  }
}

**************************************************************************
** BackticksInlineParser
**************************************************************************

**
** Attempt to parse backticks, returning either a backtick code span, or a
** literal sequence of backticks.
**
@Js
internal class BackticksInlineParser : InlineCodeParser
{
  new make() : super('`') { }
  static const InlineContentParserFactory factory := BackticksInlineParserFactory()
}

**************************************************************************
** Factory
**************************************************************************

@Js
internal const class BackticksInlineParserFactory : InlineContentParserFactory
{
  override const Int[] triggerChars := ['`']

  override InlineContentParser create() { BackticksInlineParser() }
}


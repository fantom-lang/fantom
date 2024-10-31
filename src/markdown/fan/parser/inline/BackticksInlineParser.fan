//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

**
** Attempt to parse backticks, returning either a backtick code span, or a
** literal sequence of backticks
**
@Js
class BackticksInlineParser : InlineContentParser
{
  override ParsedInline? tryParse(InlineParserState state)
  {
    scanner := state.scanner
    start := scanner.pos
    openingTicks := scanner.matchMultiple('`')
    afterOpening := scanner.pos

    while (scanner.find('`') > 0)
    {
      beforeClosing := scanner.pos
      count := scanner.matchMultiple('`')
      if (count == openingTicks)
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

    // if we got here, we didn't find a matching closing backtick sequence.
    source := scanner.source(start, afterOpening)
    text := Text(source.content)
    return ParsedInline.of(text, afterOpening)
  }

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


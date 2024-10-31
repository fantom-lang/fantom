//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 2024  Matthew Giannini  Creation
//

**
** Attempts to parse an HTML entity or numeric character reference.
**
@Js
internal class EntityInlineParser : InlineContentParser
{
  private static const |Int->Bool| hex := |Int ch->Bool| {
    ch.isDigit || ('a' <= ch && ch <= 'f') || ('A' <= ch && ch <= 'F')
  }

  private static const |Int->Bool| dec := |Int ch->Bool| { ch.isDigit }

  private static const |Int->Bool| entityContinue := |Int ch->Bool| { ch.isAlphaNum }

  override ParsedInline? tryParse(InlineParserState state)
  {
    scanner := state.scanner
    start := scanner.pos
    // skip '&'
    scanner.next

    c := scanner.peek
    if (c == '#')
    {
      // numeric
      scanner.next
      if (scanner.nextCh('x') || scanner.nextCh('X'))
      {
        digits := scanner.match(hex)
        if (1 <= digits && digits <= 6 && scanner.nextCh(';'))
          return entity(scanner, start)
      }
      else
      {
        digits := scanner.match(dec)
        if (1 <= digits && digits <= 7 && scanner.nextCh(';'))
          return entity(scanner, start)
      }
    }
    else if (c.isAlpha)
    {
      scanner.match(entityContinue)
      if (scanner.nextCh(';')) return entity(scanner, start)
    }
    return ParsedInline.none
  }

  private ParsedInline entity(Scanner scanner, Position start)
  {
    text := scanner.source(start, scanner.pos).content
    return ParsedInline.of(Text(Html5.entityToStr(text)), scanner.pos)
  }

  static const InlineContentParserFactory factory := EntityInlineParserFactory()
}

**************************************************************************
** Factory
**************************************************************************

@Js
internal const class EntityInlineParserFactory : InlineContentParserFactory
{
  override const Int[] triggerChars := ['&']

  override InlineContentParser create() { EntityInlineParser() }
}
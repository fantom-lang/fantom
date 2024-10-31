//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 2024  Matthew Giannini  Creation
//

**
** Parse a backslash-escaped special character, adding either the escaped charactor,
** a hard line break (if the backslash is followed by a newline), or a literal backslash
** to the block's children.
**
@Js
class BackslashInlineParser : InlineContentParser
{
  private static const Regex escapable := Regex("^${Esc.escapable}")

  override ParsedInline? tryParse(InlineParserState state)
  {
    scanner := state.scanner
    // backslash
    scanner.next

    next := scanner.peek
    if (next == '\n')
    {
      scanner.next
      return ParsedInline.of(HardLineBreak(), scanner.pos)
    }
    else if (escapable.matcher(next.toChar).matches)
    {
      scanner.next
      return ParsedInline.of(Text(next.toChar), scanner.pos)
    }
    else
    {
      return ParsedInline.of(Text("\\"), scanner.pos)
    }
  }

  static const InlineContentParserFactory factory := BackslashInlineParserFactory()
}

**************************************************************************
** Factory
**************************************************************************

@Js
internal const class BackslashInlineParserFactory : InlineContentParserFactory
{
  override const Int[] triggerChars := ['\\']

  override InlineContentParser create() { BackslashInlineParser() }
}
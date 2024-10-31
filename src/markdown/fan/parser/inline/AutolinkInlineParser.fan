//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 2024  Matthew Giannini  Creation
//

**
** Attempt to parse an autolink (URL or email in pointy brackets)
**
@Js
class AutolinkInlineParser : InlineContentParser
{
  private static const Regex uri := Regex("^[a-zA-Z][a-zA-Z0-9.+-]{1,31}:[^<> - ]*\$")

  private static const Regex email :=
    Regex("^([a-zA-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)\$")


  override ParsedInline? tryParse(InlineParserState state)
  {
    scanner := state.scanner
    scanner.next
    textStart := scanner.pos
    if (scanner.find('>') > 0)
    {
      textSource := scanner.source(textStart, scanner.pos)
      content := textSource.content
      scanner.next

      Str? dest := null
      if (uri.matcher(content).matches) dest = content
      else if (email.matcher(content).matches) dest = "mailto:${content}"

      if (dest != null)
      {
        link := Link(dest, null)
        text := Text(content)
        text.setSourceSpans(textSource.sourceSpans)
        link.appendChild(text)
        return ParsedInline.of(link, scanner.pos)
      }
    }
    return ParsedInline.none
  }

  const static InlineContentParserFactory factory := AutolinkInlineParserFactory()
}

**************************************************************************
** Factory
**************************************************************************

@Js
internal const class AutolinkInlineParserFactory : InlineContentParserFactory
{
  override const Int[] triggerChars := ['<']

  override InlineContentParser create() { AutolinkInlineParser() }
}
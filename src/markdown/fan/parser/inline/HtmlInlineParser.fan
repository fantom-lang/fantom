//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 2024  Matthew Giannini  Creation
//

**
** Attempt to parse inline HTML
**
@Js
internal class HtmlInlineParser : InlineContentParser
{
  // TODO:MAYBE - the java version usess an "AsciiMatcher" builder pattern
  // for building up a bitmask of characters that match. We might want to use
  // that with [Int:Bool] map instead of closures if this ends up being some
  // sort of performance bottleneck.

  private static const |Int->Bool| asciiLetter := |Int c->Bool| { c.isAlpha }
  ** spec: a tag name consists of an ASCII letter followed by zero or more ASCII letters,
  ** digits, or hyphens ('-').
  private static const |Int->Bool| tagNameStart := |Int c->Bool| { c.isAlpha }
  private static const |Int->Bool| tagNameContinue := |Int c->Bool| { c.isAlphaNum || c == '-' }

  ** spec: an attribute name consists of an ascii latter, _, or :, followed by zero or
  ** more ascii letters, digits, _, ., :, or -.  (Note: this is the XML spec restricted
  ** to ascii. html5 is more lax)
  private static const |Int->Bool| attrStart := |Int c->Bool| { c.isAlpha || c == '_' || c == ':' }
  private static const |Int->Bool| attrContinue := |Int c->Bool| {
    attrStart(c) || c.isDigit || c == '.' || c == '-'
  }
  // spec: an unquoted attr value is a nonempty string of characters not including
  // whitespace, ", ', =, <, >, or `
  private static const |Int->Bool| attrValEnd := |Int c->Bool| {
    switch (c)
    {
      case ' ':
      case '\t':
      case '\n':
      case '\u000B':
      case '\f':
      case '\r':
      case '"':
      case '\'':
      case '=':
      case '<':
      case '>':
      case '`':
        // fall-through
        return true
      default:
        return false
    }
  }

  override ParsedInline? tryParse(InlineParserState state)
  {
    scanner := state.scanner
    start := scanner.pos
    // skip over '<'
    scanner.next

    c := scanner.peek
    if (tagNameStart(c))
    {
      // we are in tag name start
      if (tryOpenTag(scanner)) return htmlInline(start, scanner)
    }
    else if (c == '/')
    {
      if (tryClosingTag(scanner)) return htmlInline(start, scanner)
    }
    else if (c == '?')
    {
      if (tryProcessingInstruction(scanner)) return htmlInline(start, scanner)
    }
    else if (c == '!')
    {
      // comment, declaration, or CDATA
      scanner.next
      c = scanner.peek
      if (c == '-')
      {
        if (tryComment(scanner)) return htmlInline(start, scanner)
      }
      else if (c == '[')
      {
        if (tryCdata(scanner)) return htmlInline(start, scanner)
      }
      else if (asciiLetter(c))
      {
        if (tryDeclaration(scanner)) return htmlInline(start, scanner)
      }
    }

    return ParsedInline.none
  }

  private static ParsedInline htmlInline(Position start, Scanner scanner)
  {
    text := scanner.source(start, scanner.pos).content
    node := HtmlInline(text)
    return ParsedInline.of(node, scanner.pos)
  }

  private static Bool tryOpenTag(Scanner scanner)
  {
    // spec: an open tag consists of a < character, a tag name, zero or more attrs,
    // optional whitespace, an optional / character, and a > character.
    scanner.next
    scanner.match(tagNameContinue)
    whitespace := scanner.whitespace >= 1
    // spec: an attribute consists of whitespace, an attr name, and and optional attr value spec
    while (whitespace && scanner.match(attrStart) >= 1)
    {
      scanner.match(attrContinue)
      // spec: an attribute value specification consists of optional whitespace,
      // a = character, optional whitespace, and an attr value
      whitespace = scanner.whitespace >= 1
      if (scanner.nextCh('='))
      {
        scanner.whitespace
        valStart := scanner.peek
        if (valStart == '\'')
        {
          scanner.next
          if (scanner.find('\'') < 0) return false
          scanner.next
        }
        else if (valStart == '"')
        {
          scanner.next
          if (scanner.find('"') < 0) return false
          scanner.next
        }
        else
        {
          if (scanner.findMatch(attrValEnd) <= 0) return false
        }

        // whitespace is required between attributes
        whitespace = scanner.whitespace >= 1
      }
    }

    scanner.nextCh('/')
    return scanner.nextCh('>')
  }

  private static Bool tryClosingTag(Scanner scanner)
  {
    // spec: a closing tag consists of the string </, a tag name, optional whitespace,
    // and the > character
    scanner.next
    if (scanner.match(tagNameStart) >= 1)
    {
      scanner.match(tagNameContinue)
      scanner.whitespace
      return scanner.nextCh('>')
    }
    return false
  }

  private static Bool tryProcessingInstruction(Scanner scanner)
  {
    // spec: a processing instruction consists of the string <?, a string of characters
    // not including the string ?>, and the string ?>
    scanner.next
    while (scanner.find('?') > 0)
    {
      scanner.next
      if (scanner.nextCh('>')) return true
    }
    return false
  }

  private static Bool tryComment(Scanner scanner)
  {
    // spec: an [HTML comment](@) consists of '<!-->', '<!--->',
    // or '<!--', a string of characters not including the string '-->' and '-->'
    // see: https://html.spec.whatwg.org/multipage/parsing.html#markup-declaration-open-state

    // skip first '-'
    scanner.next
    if (!scanner.nextCh('-')) return false

    if (scanner.nextCh('>') || scanner.nextStr("->")) return true

    while (scanner.find('-') >= 0)
    {
      if (scanner.nextStr("-->")) return true
      else scanner.next
    }

    return false
  }

  private static Bool tryCdata(Scanner scanner)
  {
    // spec: a CDATA section consists of the string <![CDATA[, a string of
    // characters not including the string ]]>, and the string ]]>

    // already parsed <!

    // skip [
    scanner.next

    if (scanner.nextStr("CDATA["))
    {
      while (scanner.find(']') >= 0)
      {
        if (scanner.nextStr("]]>")) return true
        else scanner.next
      }
    }

    return false
  }

  private static Bool tryDeclaration(Scanner scanner)
  {
    // spec: a declaration consists of the string <!, an ascii letter, zero or more
    // characters not including the character >, and the character >

    // skip ascii letter
    scanner.match(asciiLetter)
    if (scanner.whitespace <= 0) return false
    if (scanner.find('>') >= 0)
    {
      scanner.next
      return true
    }

    return false
  }

  static const InlineContentParserFactory factory := HtmlInlineParserFactory()
}

**************************************************************************
** Factory
**************************************************************************

@Js
internal const class HtmlInlineParserFactory : InlineContentParserFactory
{
  override const Int[] triggerChars := ['<']

  override InlineContentParser create() { HtmlInlineParser() }
}
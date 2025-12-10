//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Oct 2024  Matthew Giannini  Creation
//

**
** Parser for link reference definitions at the beginning of a paragraph
**
@Js
internal class LinkReferenceDefinitionParser
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make()
  {
  }

  LinkRefState state := LinkRefState.start_definition { private set }

  private SourceLine[] workingLines := [,]
  SourceLines paragraphLines() { SourceLines(this.workingLines) }

  private LinkReferenceDefinition[] definitions := [,]
  LinkReferenceDefinition[] linkRefDefs() { finishReference; return this.definitions}

  private SourceSpan[] sourceSpans := [,]
  Void addSourceSpan(SourceSpan span) { sourceSpans.add(span) }
  SourceSpan[] paraSourceSpans() { this.sourceSpans }

  private StrBuf? label
  private Str? destination
  private Int titleDelim
  private StrBuf? title
  private Bool referenceValid := false

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  Void parse(SourceLine line)
  {
    this.workingLines.add(line)
    if (state === LinkRefState.paragraph)
    {
      // We're in a paragraph now. Link reference definitions can only appear
      // at the beginning, so once we're in a paragraph, there's no going back!
      return
    }

    scanner := Scanner(line)
    while (scanner.hasNext)
    {
      // will be set to true by various states if we are still in the process
      // of parsing a valid link reference definition
      success := false
      switch (state)
      {
        case LinkRefState.start_definition:
          success = onStartDefinition(scanner)
        case LinkRefState.label:
          success = onLabel(scanner)
        case LinkRefState.destination:
          success = onDestination(scanner)
        case LinkRefState.start_title:
          success = onStartTitle(scanner)
        case LinkRefState.title:
          success = onTitle(scanner)
        default:
          throw UnsupportedErr("Unknown parsing state: ${state}")
      }

      // parsing failed, which means we fall back to treating text as a paragraph
      if (!success)
      {
        state = LinkRefState.paragraph
        finishReference
        return
      }
    }
  }

  SourceSpan[] removeLines(Int lines)
  {
    removedSpans := sourceSpans[(sourceSpans.size-lines).max(0)..<sourceSpans.size]
    removeLast(lines, workingLines)
    removeLast(lines, sourceSpans)
    return removedSpans
  }

  private static Void removeLast(Int n, List arr)
  {
    if (n >= arr.size) arr.clear
    else { n.times { arr.removeAt(-1) } }
  }

  private Bool onStartDefinition(Scanner scanner)
  {
    // finish any outstanding references now. we don't do this earlier because
    // we need addSourceSpan to have been called before we do it.
    finishReference

    scanner.whitespace
    if (!scanner.nextCh('[')) return false

    state = LinkRefState.label
    label = StrBuf()

    if (!scanner.hasNext) label.addChar('\n')

    return true
  }

  private Bool onLabel(Scanner scanner)
  {
    start := scanner.pos
    if (!LinkScanner.scanLinkLabelContent(scanner)) return false

    label.add(scanner.source(start, scanner.pos).content)

    if (!scanner.hasNext)
    {
      // label might continue on next line
      label.addChar('\n')
      return true
    }
    else if (scanner.nextCh(']'))
    {
      // end of label
      if (!scanner.nextCh(':')) return false

      // spec: a link label can have at most 999 characters inside the square bracket
      if (label.size > 999) return false

      normalizedLabel := Esc.normalizeLabelContent(label.toStr)
      if (normalizedLabel.isEmpty) return false

      // successfully parsed a label; move to destination state
      state = LinkRefState.destination

      scanner.whitespace
      return true
    }
    else
      return false
  }

  private Bool onDestination(Scanner scanner)
  {
    scanner.whitespace
    start := scanner.pos
    if (!LinkScanner.scanLinkDestination(scanner)) return false

    rawDestination := scanner.source(start, scanner.pos).content
    this.destination = rawDestination.startsWith("<")
      ? rawDestination[1..<(rawDestination.size-1)]
      : rawDestination

    whitespace := scanner.whitespace
    if (!scanner.hasNext)
    {
      // destination was at end of line, so this is a valid reference for sure
      // (and maybe a title). If not at end of line, wait for title to be valid first.
      this.referenceValid = true
      workingLines.clear
    }
    else if (whitespace == 0)
    {
      // spec: the title must be separated from the link destination by whitespace
      return false
    }

    this.state = LinkRefState.start_title
    return true
  }

  private Bool onStartTitle(Scanner scanner)
  {
    scanner.whitespace
    if (!scanner.hasNext)
    {
      state = LinkRefState.start_definition
      return true
    }

    this.titleDelim = 0
    c := scanner.peek
    switch (c)
    {
      case '"':
      case '\'':
        titleDelim = c
      case '(':
        titleDelim = ')'
    }

    if (titleDelim != 0)
    {
      state = LinkRefState.title
      this.title = StrBuf()
      scanner.next
      if (!scanner.hasNext) title.addChar('\n')
    }
    else
    {
      // there might be another reference instead, try that for the same character
      state = LinkRefState.start_definition
    }
    return true
  }

  private Bool onTitle(Scanner scanner)
  {
    start := scanner.pos
    if (!LinkScanner.scanLinkTitleContent(scanner, titleDelim))
    {
      // invalid title - stop. title collected so far must not be used
      this.title = null
      return false
    }

    title.add(scanner.source(start, scanner.pos).content)

    if (!scanner.hasNext)
    {
      // title ran until the end-of-line, so continue on next line (until we find delim)
      title.addChar('\n')
      return true
    }

    // skip delimiter character
    scanner.next
    scanner.whitespace
    if (scanner.hasNext)
    {
      // spec: no further non-whitespace characters may occur on the line
      // title collected so far must not be used
      this.title = null
      return false
    }
    this.referenceValid = true
    this.workingLines.clear

    // see if there's another definition
    state = LinkRefState.start_definition
    return true
  }

  private Void finishReference()
  {
    if (!referenceValid) return

    d := Esc.unescapeStr(destination)
    t := title != null ? Esc.unescapeStr(title.toStr) : null
    def := LinkReferenceDefinition(label.toStr, d, t)
    def.setSourceSpans(sourceSpans)
    sourceSpans.clear
    definitions.add(def)

    this.label = null
    this.referenceValid = false
    this.destination = null
    this.title = null
  }
}

**************************************************************************
** LinkeRefState
**************************************************************************

@Js
internal enum class LinkRefState
{
  ** Looking for the start of a definition: i.e. '['
  start_definition,
  ** Parsing the label, i.e. 'foo' within '[foo]'
  label,
  ** Parsing the destination, i.e. '/url' in '[foo]: /url'
  destination,
  ** Looking for the start of a title, i.e. the first '"' in '[foo]: /url "title"'
  start_title,
  ** Parsing the content of the title, i.e. 'title' in '[foo]: /url "title"'
  title,
  ** End state, no matter what kind of lines we add, they won't be references
  paragraph
}

**************************************************************************
** LinkScanner
**************************************************************************

@Js
internal class LinkScanner
{
  ** Attempt to scan the contents of a link label (inside the brackets), stopping
  ** after the content, or returning false. The stopped position can be either
  ** the closing ']', or the end of the line if the label continues on the next line.
  static Bool scanLinkLabelContent(Scanner scanner)
  {
    while (scanner.hasNext)
    {
      switch (scanner.peek)
      {
        case '\\':
          scanner.next
          if (isEscapable(scanner.peek)) scanner.next
        case ']':
          return true
        case '[':
          // spec: unescaped square bracket characters are not allowed inside
          // the opening and closing square brackets of link labels
          return false
        default:
          scanner.next
      }
    }
    return true
  }

  ** Attempt to scan a link destination, stopping after the destination or returning false
  ** See § 6.3 - Links
  static Bool scanLinkDestination(Scanner scanner)
  {
    if (!scanner.hasNext) return false

    if (scanner.nextCh('<'))
    {
      while (scanner.hasNext)
      {
        switch (scanner.peek)
        {
          case '\\':
            scanner.next
            if (isEscapable(scanner.peek)) scanner.next
          case '\n':
          case '<':
            return false
          case '>':
            scanner.next
            return true
          default:
            scanner.next
        }
      }
      return false
    }
    else return scanLinkDestinationWithBalancedParaens(scanner)
  }

  static Bool scanLinkTitle(Scanner scanner)
  {
    if (!scanner.hasNext) return false

    endDelim := 0
    switch (scanner.peek)
    {
      case '"':  endDelim = '"'
      case '\'': endDelim = '\''
      case '(':  endDelim = ')'
      default:   return false
    }
    scanner.next

    if (!scanLinkTitleContent(scanner, endDelim)) return false
    if (!scanner.hasNext) return false
    scanner.next
    return true
  }

  static Bool scanLinkTitleContent(Scanner scanner, Int endDelim)
  {
    while (scanner.hasNext)
    {
      c := scanner.peek
      if (c == '\\')
      {
        scanner.next
        if (isEscapable(scanner.peek)) scanner.next
      }
      else if (c == endDelim) return true
      else if (endDelim == ')' && c == '(')
      {
        // unescaped '(' in title within parens is invalid
        return false
      }
      else scanner.next
    }
    return true
  }

  ** spec: a non-empty sequence of characters that does not start with '<',
  ** does not include ASCII space or control characters, and includes
  ** parentheses only if (a) they are backslash-escaped or (b) they are part of
  ** a balanced pair of unescaped parentheses.
  static Bool scanLinkDestinationWithBalancedParaens(Scanner scanner)
  {
    parens := 0
    empty := true
    while (scanner.hasNext)
    {
      c := scanner.peek
      switch (c)
      {
        case ' ':
          return !empty
        case '\\':
          scanner.next
          if (isEscapable(scanner.peek)) scanner.next
        case '(':
          ++parens
          // limit to 32 nested parens for pathological cases
          if (parens > 32) return false
          scanner.next
        case ')':
          if (parens == 0) return true
          else --parens
          scanner.next
        default:
          // or control character
          if (Chars.isIsoControl(c)) return !empty
          scanner.next
      }
      empty = false
    }
    return true
  }

  static Bool isEscapable(Int c)
  {
    switch (c)
    {
      case '!':
      case '"':
      case '#':
      case '$':
      case '%':
      case '&':
      case '\'':
      case '(':
      case ')':
      case '*':
      case '+':
      case ',':
      case '-':
      case '.':
      case '/':
      case ':':
      case ';':
      case '<':
      case '=':
      case '>':
      case '?':
      case '@':
      case '[':
      case '\\':
      case ']':
      case '^':
      case '_':
      case '`':
      case '{':
      case '|':
      case '}':
      case '~':
        // fall through
        return true;
    }
    return false
  }
}

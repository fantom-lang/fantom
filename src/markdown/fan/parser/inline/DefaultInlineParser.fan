//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Oct 2024  Matthew Giannini  Creation
//

**
** Default implementation of an inline content parser
**
@Js
internal class DefaultInlineParser : InlineParser, InlineParserState
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(InlineParserContext cx)
  {
    this.cx = cx
    this.inlineContentParserFactories = calculateInlineContentParserFactories
    this.delimProcessors = calculateDelimProcessors(cx.customDelimiterProcessors)
    this.linkProcessors = calculateLinkProcessors(cx.customLinkProcessors)
    this.linkMarkers = calculateLinkMarkers(cx.customLinkMarkers)
    this.specialChars = calculateSpecialChars(linkMarkers, delimProcessors.keys, inlineContentParserFactories)
  }

  private InlineParserContext cx
  private InlineContentParserFactory[] inlineContentParserFactories
  private [Int:DelimiterProcessor] delimProcessors
  private LinkProcessor[] linkProcessors

  // TODO: possibly need to implement these as BitSet like in java
  private [Int:Bool] linkMarkers
  private [Int:Bool] specialChars

  private [Int:InlineContentParser[]]? inlineParsers
  override Scanner? scanner { private set }
  private Bool includeSourceSpans
  private Int trailingSpaces

  ** Top delimiter (emphasis, strong emphasis, or custom emphasis). (Brackets are
  ** on a separate stack, different from the algorithm described in the spec.)
  private Delimiter? lastDelim

  ** Top opening bracket '[' or '!['
  private Bracket? lastBracket

//////////////////////////////////////////////////////////////////////////
// Constructor Support
//////////////////////////////////////////////////////////////////////////

  private InlineContentParserFactory[] calculateInlineContentParserFactories()
  {
    acc := InlineContentParserFactory[,]
    // custom parsers can override built-in parsers if they want, so make
    // sure they are tried first
    acc.addAll(cx.factories)
    acc.add(BackslashInlineParser.factory)
    acc.add(BackticksInlineParser.factory)
    acc.add(EntityInlineParser.factory)
    acc.add(AutolinkInlineParser.factory)
    acc.add(HtmlInlineParser.factory)
    return acc
  }

  private static LinkProcessor[] calculateLinkProcessors(LinkProcessor[] custom)
  {
    acc := LinkProcessor[,]
    // custom link processors can override the built-in behavior so they are tried first
    acc.addAll(custom)
    acc.add(CoreLinkProcessor())
    return acc
  }

  private static [Int:DelimiterProcessor] calculateDelimProcessors(DelimiterProcessor[] custom)
  {
    acc := [Int:DelimiterProcessor][:]
    addDelimProcessor([AsteriskDelimiterProcessor(), UnderscoreDelimiterProcessor()], acc)
    addDelimProcessor(custom, acc)
    return acc
  }

  private static Void addDelimProcessor(DelimiterProcessor[] processors, [Int:DelimiterProcessor] acc)
  {
    processors.each |processor|
    {
      opening := processor.openingChar
      closing := processor.closingChar
      if (opening == closing)
      {
        old := acc[opening]
        if (old != null && old.openingChar == old.closingChar)
        {
          // staggered
          throw Err("TODO")
        }
        else addDelimiterProcessorForChar(opening, processor, acc)
      }
      else
      {
        addDelimiterProcessorForChar(opening, processor, acc)
        addDelimiterProcessorForChar(closing, processor, acc)
      }
    }
  }

  private static Void addDelimiterProcessorForChar(Int delimChar, DelimiterProcessor toAdd, [Int:DelimiterProcessor] acc)
  {
    existing := acc[delimChar]
    if (existing != null)
      throw ArgErr("Delimiter processor conflict with delimiter char '${delimChar.toChar}'")
    acc[delimChar] = toAdd
  }

  private [Int:InlineContentParser[]] createInlineContentParsers()
  {
    acc := [Int:InlineContentParser[]][:]
    inlineContentParserFactories.each |factory|
    {
      parser := factory.create
      factory.triggerChars.each |ch|
      {
        parsers := acc[ch]
        if (parsers == null) acc[ch] = parsers = InlineContentParser[,]
        parsers.add(parser)
      }
    }
    return acc
  }

  private static [Int:Bool] calculateLinkMarkers(Int[] customLinkMarkers)
  {
    acc := [Int:Bool][:] { def = false }
    customLinkMarkers.each |marker| { acc[marker] = true }
    acc['!'] = true
    return acc
  }

  private static [Int:Bool] calculateSpecialChars(
    [Int:Bool] linkMarkers,
    Int[] delimChars,
    InlineContentParserFactory[] inlineContentParserFactories)
  {
    acc := [Int:Bool][:] { def = false }
    delimChars.each |ch| { acc[ch] = true }
    inlineContentParserFactories.each |factory|
    {
      factory.triggerChars.each |ch| { acc[ch] = true }
    }
    acc.set('[', true)
    acc.set(']', true)
    acc.set('!', true)
    acc.set('\n', true)
    return acc
  }

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  ** Parse content in block into inline children, appending them to the block node.
  override Void parse(SourceLines lines, Node block)
  {
    reset(lines)

    while (true)
    {
      nodes := parseInline
      if (nodes == null) break
      nodes.each |node|
      {
        block.appendChild(node)
      }
    }

    processDelimiters(null)
    mergeChildTextNodes(block)
  }

  internal Void reset(SourceLines lines)
  {
    this.scanner = Scanner(lines)
    this.includeSourceSpans = !lines.sourceSpans.isEmpty
    this.trailingSpaces = 0
    this.lastDelim = null
    this.lastBracket = null
    this.inlineParsers = createInlineContentParsers
  }

  private Text text(SourceLines sourceLines)
  {
    text := Text(sourceLines.content)
    text.setSourceSpans(sourceLines.sourceSpans)
    return text
  }

  ** Parse the next inline element in subject, advancing our position.
  ** On success, return the new inline node.
  ** On failture, return null.
  private Node[]? parseInline()
  {
    c := scanner.peek
    switch (c)
    {
      case '[':
        return [parseOpenBracket]
      case ']':
        return [parseCloseBracket]
      case '\n':
        return [parseLineBreak]
      case Scanner.END:
        return null
    }

    if (linkMarkers[c])
    {
      markerPos := scanner.pos
      nodes := parseLinkMarker
      if (nodes != null) return nodes
      // reset and try other things (e.g. inline parsers below)
      scanner.setPos(markerPos)
    }

    // no inline parser, delimiter or other special handling
    if (!specialChars[c])
    {
      return [parseText]
    }

    inlineParsers := inlineParsers[c]
    if (inlineParsers != null)
    {
      pos := scanner.pos
      node := inlineParsers.eachWhile |inlineParser->Node?|
      {
        parsedInline := inlineParser.tryParse(this)
        if (parsedInline != null)
        {
          node := parsedInline.node
          scanner.setPos(parsedInline.pos)
          if (includeSourceSpans && node.sourceSpans.isEmpty)
          {
            node.setSourceSpans(scanner.source(pos, scanner.pos).sourceSpans)
          }
          return node
        }
        else
        {
          // reset position
          scanner.setPos(pos)
        }
        return null
      }
      if (node != null) return [node]
    }

    processor := delimProcessors[c]
    if (processor != null)
    {
      nodes := parseDelimiters(processor, c)
      if (nodes != null) return nodes
    }

    // If we get here, even for a special/delimiter character,
    // we will just treat it as text
    return [parseText]
  }

  ** Attempt to parse delimiters like emphasis, strong emphasis or custom delimiters
  private Node[]? parseDelimiters(DelimiterProcessor processor, Int delimChar)
  {
    res := scanDelimiters(processor, delimChar)
    if (res == null) return null

    chars := res.chars

    // add entry to stack for this opener
    this.lastDelim = Delimiter(chars, delimChar, res.canOpen, res.canClose, lastDelim)
    if (lastDelim.prev != null) lastDelim.prev.next = lastDelim

    return chars
  }

  ** Add open bracket to delimiter stack and add a text node to block's children
  private Node parseOpenBracket()
  {
    start := scanner.pos
    scanner.next
    contentPos := scanner.pos

    node := text(scanner.source(start, contentPos))

    // add entry to stack for this opener
    addBracket(Bracket.link(node, start, contentPos, lastBracket, lastDelim))
    return node
  }

  ** If next character is '[', add a bracket to the stack.
  ** Otherwise, return null
  private Node[]? parseLinkMarker()
  {
    markerPos := scanner.pos
    scanner.next
    bracketPos := scanner.pos
    if (scanner.nextCh('['))
    {
      contentPos := scanner.pos
      bangNode := text(scanner.source(markerPos, bracketPos))
      bracketNode := text(scanner.source(bracketPos, contentPos))

      // add entry to stack for this opener
      addBracket(
        Bracket.withMarker(bangNode, markerPos, bracketNode, bracketPos, contentPos,
          lastBracket, lastDelim)
      )
      return [bangNode, bracketNode]
    }
    else return null
  }

  private Node parseCloseBracket()
  {
    beforeClose := scanner.pos
    scanner.next
    afterClose := scanner.pos

    // get previous '[' or '!['
    opener := this.lastBracket
    if (opener == null)
    {
      // no matching opener, just return a literal
      return text(scanner.source(beforeClose, afterClose))
    }

    if (!opener.allowed)
    {
      // matching opener, but it's not allowed, just return a literal
      removeLastBracket
      return text(scanner.source(beforeClose, afterClose))
    }

    linkOrImage := parseLinkOrImage(opener, beforeClose)
    if (linkOrImage != null) return linkOrImage
    scanner.setPos(afterClose)

    // Nothing parsed, just parse the bracket as text and continue
    removeLastBracket
    return text(scanner.source(beforeClose, afterClose))
  }

  private Node? parseLinkOrImage(Bracket opener, Position beforeClose)
  {
    linkInfo := parseLinkInfo(opener, beforeClose)
    if (linkInfo == null) return null

    processorStartPos := scanner.pos

    return linkProcessors.eachWhile |processor|
    {
      result := processor.process(linkInfo, scanner, cx)
      if (result == null)
      {
        // reset position in  case the processor used the scanner, and it didn't work out
        scanner.setPos(processorStartPos)
        return null
      }

      node := result.node
      pos  := result.pos
      if (result.wrap)
      {
        scanner.setPos(pos)
        return wrapBracket(opener, node, result.includeMarker)
      }
      else
      {
        scanner.setPos(pos)
        return replaceBracket(opener, node, result.includeMarker)
      }
    }
  }

  private LinkInfo? parseLinkInfo(Bracket opener, Position beforeClose)
  {
    // Check to see if we have a link (or image, with a ! in front). The different types:
    // - Inline: `[foo](/uri)` or with optional title `[foo](/uri "title")`
    // - Reference Links:
    //   - Full:      `[foo][bar]` (foo is the text and bar is the label that nees to match a reference)
    //   - Collapsed: `[foo][]`    (foo is both the text and label)
    //   - Shortcut:  `[foo]       (foo is both the text and label)

    text := scanner.source(opener.contentPos, beforeClose).content

    // starting position is after the closing ']'
    afterClose := scanner.pos

    // maybe an inline link/image
    destTitle := parseInlineDestinationTitle(scanner)
    if (destTitle != null)
    {
      return MLinkInfo() {
        it.marker = opener.markerNode
        it.openingBracket = opener.bracketNode
        it.text = text
        it.destination = destTitle.destination
        it.title = destTitle.title
        it.afterTextBracket = afterClose
      }
    }

    // not an inline link/image, rewind back to after ']'
    scanner.setPos(afterClose)

    // maybe a reference link/image like '[foo][bar]', '[foo][]' or '[foo]'.
    // note that even '[foo](' could be a valid link if foo is a reference, which is
    // why we try this even if the '(' failed to be parsed as an inline link/image before.

    // see if there's a link label like '[bar]' or '[]'
    label := parseLinkLabel(scanner)
    if (label == null)
    {
      // no label, rewind back
      scanner.setPos(afterClose)
    }

    textIsRef := label == null || label.isEmpty
    if (opener.bracketAfter && textIsRef && opener.markerNode == null)
    {
      // In case of shortcut or collapsed links, the text is used as the reference.
      // But the reference is not allowed to contain an unescaped bracket, so if that's
      // the case we don't need to continue. This is an optimization.
      return null
    }

    return MLinkInfo
    {
      it.marker = opener.markerNode
      it.openingBracket = opener.bracketNode
      it.text = text
      it.label = label
      it.afterTextBracket = afterClose
    }
  }

  private Node wrapBracket(Bracket opener, Node wrapperNode, Bool includeMarker)
  {
    // add all nodes between the opening bracket and now (closing bracket)
    // as child nodes of the link
    n := opener.bracketNode.next
    while (n != null)
    {
      next := n.next
      wrapperNode.appendChild(n)
      n = next
    }

    if (includeSourceSpans)
    {
      throw Err("TODO: source spans")
    }

    // process delimiters such as emphasis inside link/image
    processDelimiters(opener.prevDelim)
    mergeChildTextNodes(wrapperNode)

    // we don't need the corresponding text node anymore, we turned it into a link/image node
    if (includeMarker && opener.markerNode != null) opener.markerNode.unlink
    opener.bracketNode.unlink
    removeLastBracket

    // links within links are not allowed. we found this link, so there can be no other
    // link around it
    if (opener.markerNode == null)
    {
      bracket := lastBracket
      while (bracket != null)
      {
        if (bracket.markerNode == null)
        {
          // disallow link opener. it will still get matched, but will not
          // result in a link
          bracket.allowed = false
        }
        bracket = bracket.prev
      }
    }

    return wrapperNode
  }

  private Node replaceBracket(Bracket opener, Node node, Bool includeMarker)
  {
    throw Err("TODO")
  }

  private Void addBracket(Bracket bracket)
  {
    if (this.lastBracket != null) lastBracket.bracketAfter = true
    lastBracket = bracket
  }

  private Void removeLastBracket()
  {
    lastBracket = lastBracket.prev
  }

/*
  private Void dumpBrackets()
  {
    cur := this.lastBracket
    i := 0
    while (cur != null)
    {
      echo("${i}: ${cur.bracketNode} ${cur.bracketPos}")
      cur = cur.prev
    }
  }
  */

  ** Try to parse the destination and an optional title for an inline link/image
  private static DestinationTitle? parseInlineDestinationTitle(Scanner scanner)
  {
    if (!scanner.nextCh('(')) return null

    scanner.whitespace
    dest := parseLinkDestination(scanner)
    if (dest == null) return null

    Str? title := null
    whitespace := scanner.whitespace
    if (whitespace >= 1)
    {
      title = parseLinkTitle(scanner)
      scanner.whitespace
    }
    if (!scanner.nextCh(')'))
    {
      // don't have a closing ')', so it's not a destination and title
      // note that something like '[foo](' could still be valid later, '(' will just be text.
      return null
    }
    return DestinationTitle(dest, title)
  }

  ** Attempt to parse link destination, returning the uri or null if no match
  private static Str? parseLinkDestination(Scanner scanner)
  {
    delim := scanner.peek
    start := scanner.pos
    if (!LinkScanner.scanLinkDestination(scanner)) return null

    Str? dest := null
    if (delim == '<')
    {
      // chop off surrounding <..>:
      rawDest := scanner.source(start, scanner.pos).content
      dest = rawDest[1..<(rawDest.size-1)]
    }
    else dest = scanner.source(start, scanner.pos).content

    return Esc.unescapeStr(dest)
  }

  ** Attempt to parse link title (without quotes), returning the string or null if no match.
  private static Str? parseLinkTitle(Scanner scanner)
  {
    start := scanner.pos
    if (!LinkScanner.scanLinkTitle(scanner)) return null

    // chop off single quote, double quote, or parens
    rawTitle := scanner.source(start, scanner.pos).content
    title := rawTitle[1..<(rawTitle.size-1)]
    return Esc.unescapeStr(title)
  }

  ** Attempt to parse a link label, returning the label between the brackets or null.
  static Str? parseLinkLabel(Scanner scanner)
  {
    if (!scanner.nextCh('[')) return null

    start := scanner.pos
    if (!LinkScanner.scanLinkLabelContent(scanner)) return null
    end := scanner.pos

    if (!scanner.nextCh(']')) return null

    content := scanner.source(start, end).content
    // spec: a link label can have at most 999 characters inside the square brackets.
    if (content.size > 999) return null

    return content
  }

  private Node parseLineBreak()
  {
    scanner.next
    return trailingSpaces >= 2 ? HardLineBreak() : SoftLineBreak()
  }

  ** Parse the next character as plain text, and possibly more if the following
  ** characters are non-special.
  private Node parseText()
  {
    start := scanner.pos
    scanner.next
    Int? c
    while (true)
    {
      c = scanner.peek
      if (c == Scanner.END || specialChars[c]) break
      scanner.next
    }

    source := scanner.source(start, scanner.pos)
    content := source.content

    if (c == '\n')
    {
      // we parsed until the end of the line. trim any trailing white spaces
      // and remember them (for hard line breaks).
      end := Chars.skipBackwards(' ', content) + 1
      this.trailingSpaces = content.size - end
      content = content[0..<end]
    }
    else if (c == Scanner.END)
    {
      // for the last line, both tabs and spaces are trimmed for some reason
      // (verified with commonmark.js)
      end := Chars.skipSpaceTabBackwards(content, content.size-1, 0) + 1
      content = content[0..<end]
    }

    text := Text(content)
    text.setSourceSpans(source.sourceSpans)
    return text
  }

  ** Scan a sequence of characters with code 'delimChar' and return information about the
  ** number of delimiters and wheter they are positioned such that they can open and/or
  ** close emphasis or strong emphasis.
  **
  ** Returns information about delimiter run or null
  private DelimiterData? scanDelimiters(DelimiterProcessor processor, Int delimChar)
  {
    before := scanner.peekPrevCodePoint
    start := scanner.pos

    // quick check to see if we have enough delimiters
    delimCount := scanner.matchMultiple(delimChar)
    if (delimCount < processor.minLen)
    {
      scanner.setPos(start)
      return null
    }

    // we do have enough, extract a text node for each delimiter character
    delims := Text[,]
    scanner.setPos(start)
    posBefore := start
    while (scanner.nextCh(delimChar))
    {
      delims.add(text(scanner.source(posBefore, scanner.pos)))
      posBefore = scanner.pos
    }

    after := scanner.peekCodePoint

    // we could be more lazy here, in most cases we don't need to do every match case
    beforeIsPunctuation := before == Scanner.END || Chars.isPunctuation(before)
    beforeIsWhitespace := before == Scanner.END || Chars.isWhitespace(before)
    afterIsPunctuation := after == Scanner.END || Chars.isPunctuation(after)
    afterIsWhiteSpace := after == Scanner.END || Chars.isWhitespace(after)

    leftFlanking := !afterIsWhiteSpace &&
      (!afterIsPunctuation || beforeIsWhitespace || beforeIsPunctuation)
    rightFlanking := !beforeIsWhitespace &&
      (!beforeIsPunctuation || afterIsWhiteSpace || afterIsPunctuation)
    canOpen := false
    canClose := false
    if (delimChar == '_')
    {
      canOpen = leftFlanking && (!rightFlanking || beforeIsPunctuation)
      canClose = rightFlanking && (!leftFlanking || afterIsPunctuation)
    }
    else
    {
      canOpen = leftFlanking && delimChar == processor.openingChar
      canClose = rightFlanking && delimChar == processor.closingChar
    }

    return DelimiterData(delims, canOpen, canClose)
  }

//////////////////////////////////////////////////////////////////////////
// Delimiters
//////////////////////////////////////////////////////////////////////////

  // private Void delimDump(Delimiter? d)
  // {
  //   echo(d)
  //   if (d == null) return
  //   n := d.prev
  //   while (n != null) { delimDump(n); n = n.prev }
  // }

  private Void processDelimiters(Delimiter? stackBottom)
  {

    openersBottom := [Int:Delimiter?][:]

    // find first closer *above* stackBottom:
    closer := this.lastDelim
    while (closer != null && closer.prev != stackBottom)
      closer = closer.prev

    // move forward, looking for closers, and handling each
    while (closer != null)
    {
      delimChar := closer.delimChar

      processor := delimProcessors[delimChar]
      if (!closer.canClose || processor == null)
      {
        closer = closer.next
        continue
      }

      openingDelimChar := processor.openingChar

      // found delimiter closer; now look back for first matching opener.
      usedDelims := 0
      openerFound := false
      potentialOpenerFound := false
      opener := closer.prev
      while (opener != null && opener != stackBottom && opener != openersBottom[delimChar])
      {
        if (opener.canOpen && opener.delimChar == openingDelimChar)
        {
          potentialOpenerFound = true
          usedDelims = processor.process(opener, closer)
          if (usedDelims > 0)
          {
            openerFound = true
            break
          }
        }
        opener = opener.prev
      }

      if (!openerFound)
      {
        if (!potentialOpenerFound)
        {
          // Set lower bound for future searches for openers.
          // Only do this when we didn't even have a potential
          // opener (one that matches the character and can open).
          // If an opener was rejected because of the number of
          // delimiters (e.g. because of the "multiple of 3" rule),
          // we want to consider it next time because the number
          // of delimiters can change as we continue processing.
          openersBottom[delimChar] = closer.prev
          if (!closer.canOpen)
          {
            // we can remove a closer that can't be an opener,
            // once we've seen there's no matching opener:
            removeDelimiterKeepNode(closer)
          }
        }
        closer = closer.next
        continue
      }

      // remove number of used delimiter nodes
      for (i := 0; i < usedDelims; ++i)
      {
        delimiter := opener.chars.removeAt(opener.chars.size - 1)
        delimiter.unlink
      }
      for (i := 0; i < usedDelims; ++i)
      {
        delimiter := closer.chars.removeAt(0)
        delimiter.unlink
      }

      removeDelimitersBetween(opener, closer)

      // no delimiter characters left to process, so we can remove delimiter
      // and the now empty node.
      if (opener.size == 0)
      {
        removeDelimiterAndNodes(opener)
      }
      if (closer.size == 0)
      {
        next := closer.next
        removeDelimiterAndNodes(closer)
        closer = next
      }
    }

    // remove all delimiters
    while (lastDelim != null && lastDelim != stackBottom)
      removeDelimiterKeepNode(lastDelim)
  }

  private Void removeDelimitersBetween(Delimiter opener, Delimiter closer)
  {
    delimiter := closer.prev
    while (delimiter != null && delimiter != opener)
    {
      prev := delimiter.prev
      removeDelimiterKeepNode(delimiter)
      delimiter = prev
    }
  }

  ** Remove the delimiter and the corresponding text node.
  ** For used delimiters, e.g. '*' in '*foo*'
  private Void removeDelimiterAndNodes(Delimiter delim) { removeDelimiter(delim) }

  ** Remove the delimiter but keep the corresponding node as text.
  ** For unused delimiters such as '_' in 'foo_bar'
  private Void removeDelimiterKeepNode(Delimiter delim) { removeDelimiter(delim) }

  private Void removeDelimiter(Delimiter delim)
  {
    if (delim.prev != null) delim.prev.next = delim.next
    if (delim.next == null)
    {
      // top of stack
      this.lastDelim = delim.prev
    }
    else
    {
      delim.next.prev = delim.prev
    }
  }

  private Void mergeChildTextNodes(Node node)
  {
    // no children, no need for anything
    if (node.firstChild == null) return

    mergeTextNodesInclusive(node.firstChild, node.lastChild)
  }

  private Void mergeTextNodesInclusive(Node fromNode, Node toNode)
  {
    Text? first := null
    Text? last := null
    len := 0

    Node? node := fromNode
    while (node != null)
    {
      if (node is Text)
      {
        text := (Text)node
        if (first == null) first = text
        len += text.literal.size
        last = text
      }
      else
      {
        mergeIfNeeded(first, last, len)
        first = last = null
        len = 0
      }
      if (node == toNode) break
      node = node.next
    }
    mergeIfNeeded(first, last, len)
  }

  private Void mergeIfNeeded(Text? first, Text? last, Int textLen)
  {
    if (first != null && last != null && first != last)
    {
      sb := StrBuf()
      sb.add(first.literal)
      // TODO:sourcespans
      Obj? sourceSpans := null
      if (includeSourceSpans)
      {
        throw Err("TODO:source spans")
      }
      node := first.next
      stop := last.next
      while (node != stop)
      {
        sb.add(((Text)node).literal)
        if (sourceSpans != null) throw Err("TODO:source spans")

        unlink := node
        node = node.next
        unlink.unlink
      }
      literal := sb.toStr
      first.literal = literal
      if (sourceSpans != null) throw Err("TODO: source spans")
    }
  }
}

**************************************************************************
** DestTitle
**************************************************************************

**
** A destination and optional title for a link or image
**
@Js
internal const class DestinationTitle
{
  new make(Str destination, Str? title := null)
  {
    this.destination  = destination
    this.title        = title
  }
  const Str destination
  const Str? title

  override Str toStr() { "DestinationTitle(${destination}, ${title})" }
}

**************************************************************************
** DelimiterData
**************************************************************************

@Js
internal class DelimiterData
{
  new make(Text[] chars, Bool canOpen, Bool canClose)
  {
    this.chars = chars
    this.canOpen = canOpen
    this.canClose = canClose
  }

  Text[] chars { private set }
  const Bool canOpen
  const Bool canClose
}
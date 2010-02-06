//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Feb 07  Brian Frank  Creation
//

**
** FandocParser translate fandoc text into an in-memory
** representation of the document.
**
** See [pod doc]`pod-doc#api` for usage.
**
class FandocParser
{

//////////////////////////////////////////////////////////////////////////
// Parser
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the document from the specified in stream into an in-memory
  ** tree structure.  If close is true, the stream is guaranteed to be closed.
  **
  Doc parse(Str filename, InStream in, Bool close := true)
  {
    this.filename = filename
    this.errs = FandocErr[,]
    readLines(in, close)

    doc := Doc.make
    try
    {
      header(doc)
      while (curt !== LineType.eof)
        doc.addChild(topBlock)
    }
    catch (Err e)
    {
      err("Invalid line $curLine", curLine, e)
      doc.children = [Pre.make.addChild(DocText(lines.join("\n")))]
    }

    lines = null
    return doc
  }

  **
  ** Parse a string into its in-memory document tree structure.
  **
  Doc parseStr(Str plaintext)
  {
    return parse("str", plaintext.in, true)
  }

//////////////////////////////////////////////////////////////////////////
// Header
//////////////////////////////////////////////////////////////////////////

  private Void header(Doc doc)
  {
    if (!parseHeader) return
    skipBlankLines
    while (curt !== LineType.eof && cur.startsWith("**"))
    {
      colon := cur.index(":")
      if (colon != null)
      {
        key := cur[2..<colon].trim
        val := cur[colon+1..-1].trim
        doc.meta[key] = val
      }
      else
      {
        if (!cur.startsWith("****")) break
      }
      consume
    }
    skipBlankLines
  }

//////////////////////////////////////////////////////////////////////////
// Block
//////////////////////////////////////////////////////////////////////////

  private DocElem topBlock()
  {
    switch (peekt)
    {
      case LineType.h1:
      case LineType.h2:
      case LineType.h3:
        return heading
    }

    return block(0)
  }

  private DocElem heading()
  {
    level := peekt.headingLevel
    h := Heading(level)
    curStart = 0
    formattedText(h)
    consume
    skipBlankLines
    return h
  }

  private DocElem block(Int indent)
  {
    switch (curt)
    {
      case LineType.ol:
        return ol
      case LineType.ul:
        return ul
      case LineType.blockquote:
        return blockquote
      case LineType.preStart:
        return preExplicit
      case LineType.normal:
        if (curIndent >= indent+2)
          return pre
        else
          return para
      default:
        throw Err(curt.toStr)
    }
  }

  private DocElem para()
  {
    para := Para.make

    // if the first word is all capitals followed
    // by a colon then it is a admonition such as NOTE:
    first := cur.trim.split.first
    if (first[-1] == ':')
    {
      first = first[0..-2]
      if (first.all |Int ch->Bool| { return ch.isUpper })
      {
        para.admonition = first
        curStart = cur.index(":") + 1
      }
    }

    return formattedText(para)
  }

  private DocElem blockquote()
  {
    // block quote wraps paragraph
    return BlockQuote.make.addChild(formattedText(Para.make))
  }

  private DocElem preExplicit()
  {
    // skip pre>
    consume

    // skip any blank lines
    while (curt === LineType.blank) consume

    // align against indentation of first line
    indent := 0
    while (cur[indent] == ' ') indent++

    // read preformatted lines
    buf := StrBuf(256)
    while (curt !== LineType.preEnd && curt !== LineType.eof)
    {
      if (cur.isEmpty) buf.add("\n")
      else if (cur.size >= indent) buf.add(cur[indent..-1]).add("\n")
      else buf.add(cur)
      consume
    }
    consume

    while (curt === LineType.blank) consume

    pre := Pre.make
    pre.addChild(DocText(buf.toStr))
    return pre
  }

  private DocElem pre()
  {
    // first line defines left margin
    indent := curIndent
    buf := StrBuf(256)
    buf.add(cur[indent..-1])
    consume

    while (true)
    {
      // read in preformatted lines of code
      while (curt === LineType.normal && curIndent >= indent)
      {
        buf.add("\n").add(cur[indent..-1])
        consume
      }

      // skip blanks but keep track of count
      blanks := 0
      while (curt === LineType.blank) { consume; blanks++ }

      // if more code, then add blank lines and continue
      if (curt === LineType.normal && curIndent >= indent)
        blanks.times { buf.add("\n") }
      else
        break
    }

    pre := Pre.make
    pre.addChild(DocText(buf.toStr))
    return pre
  }

  private DocElem ol()
  {
    style := OrderedListStyle.fromFirstChar(cur.trim[0])
    return listItems(OrderedList(style), curt, curIndent)
  }

  private DocElem ul()
  {
    return listItems(UnorderedList.make, curt, curIndent)
  }

  private DocElem listItems(DocElem list, LineType listType, Int listIndent)
  {
    while (true)
    {
      // next item in my own list
      if (curt === listType && curIndent == listIndent)
      {
        list.addChild(formattedText(ListItem.make))
      }

      // otherwise if indent is same or greater, then
      // this is a continuation of the my last node
      else if (curIndent >= listIndent)
      {
        ((DocElem)list.children.last).addChild(block(listIndent))
      }

      // end of list
      else
      {
        break
      }
    }
    return list
  }

  private DocElem formattedText(DocElem elem)
  {
    startLineNum := curLine
    startIndent  := curStart
    isBlockQuote := curt === LineType.blockquote

    buf := StrBuf(256)
    buf.add(cur[curStart..-1].trim)
    consume

    while (curStart <= startIndent &&
           (curt === LineType.normal || (isBlockQuote && curt == LineType.blockquote)))
    {
      buf.add("\n").add(cur[curStart..-1].trim)
      consume
    }
    endLineNum := this.lineIndex - 2
    skipBlankLines

    oldNumChildren := elem.children.size
    try
    {
      InlineParser(this, buf, startLineNum).parse(elem)
    }
    catch (Err e)
    {
      if (e is FandocErr)
        errReport((FandocErr)e)
      else
        err("Internal error: $e", startLineNum, e)

      elem.children = elem.children[0..<oldNumChildren]
      elem.addChild(DocText(buf.toStr.replace("\n", " ")))
    }

    return elem
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  **
  ** Read all the lines into memory and close stream if required.
  **
  private Void readLines(InStream in, Bool close)
  {
    try
    {
      lines = in.readAllLines
      numLines = lines.size
      lineIndex = curLine = 0
      consume
      consume
      curLine = 1
    }
    finally
    {
      if (close) in.close
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Log an error
  **
  private Void err(Str msg, Int line, Err? cause := null)
  {
    errReport(FandocErr(msg, filename, line, cause))
  }

  **
  ** Log an error
  **
  private Void errReport(FandocErr err)
  {
    errs.add(err)
    if (!silent) echo("ERROR: $err")
  }

  **
  ** Skip any blank lines
  **
  private Void skipBlankLines()
  {
    while (curt === LineType.blank) consume
  }

  **
  ** Return if line starting at index i is an ordered
  ** list item:
  **   number* "." sp  (digits)
  **   letter  "." sp  (a-z | A-Z single letter only)
  **   roman*  "." sp  (ivx | IVX combos)
  **
  private static Bool isOrderedListMark(Str line, Int i)
  {
    // check if first char is alpha numeric
    if (!line[i].isAlphaNum) return false

    // find dot space
    dot := line.index(". ", i)
    if (dot == null) return false

    mark := line[i..<dot]
    if (mark[0].isDigit)
    {
      return mark.all |Int ch->Bool| { return ch.isDigit }
    }
    else
    {
      return mark.all |Int ch, Int index->Bool|
      {
        switch (ch)
        {
          case 'I':
          case 'V':
          case 'X':
          case 'i':
          case 'v':
          case 'x':
            return true
          default:
            return index == 0
        }
      }
    }
  }

  **
  ** Consume the current line and advance to the next line
  **
  private Void consume()
  {
    // advance cur to peek
    cur       = peek
    curt      = peekt
    curIndent = peekIndent
    curStart  = peekStart
    curNotBlank := curt != LineType.blank
    curLine++

    // update peek, peekIndent, and peekType
    peek = (lineIndex < numLines) ? lines[lineIndex++] : null
    peekIndent = peekStart = 0
    if (peek == null)                  peekt = LineType.eof
    else if (peek.isSpace)             peekt = LineType.blank
    else if (peek.startsWith("pre>"))  peekt = LineType.preStart
    else if (peek.startsWith("<pre"))  peekt = LineType.preEnd
    else if (peek.startsWith("***") && curNotBlank)  peekt = LineType.h1
    else if (peek.startsWith("===") && curNotBlank)  peekt = LineType.h2
    else if (peek.startsWith("---") && curNotBlank)  peekt = LineType.h3
    else
    {
      peekt = LineType.normal
      while (peek[peekIndent].isSpace) peekIndent++
      if (peekIndent+2 < peek.size)
      {
        if (peek[peekIndent] == '-' && peek[peekIndent+1].isSpace)
        {
          peekt = LineType.ul
          peekIndent += 2
          peekStart = peekIndent
        }
        if (isOrderedListMark(peek, peekIndent))
        {
          peekt = LineType.ol
          peekIndent += 2
          peekStart = peek.index(".") + 2
        }
        else if (peek[peekIndent] == '>' && peek[peekIndent+1].isSpace)
        {
          peekt = LineType.blockquote
          peekIndent += 2
          peekStart = peekIndent
        }
        else
        {
          peekStart = peekIndent
        }
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  static Void main(Str[] args := Env.cur.args)
  {
    doc := make.parse(args[0], File(args[0].toUri).in)
    doc.dump
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** If not silent, then errors are dumped to stdout
  Bool silent := false

  ** List of errors detected
  FandocErr[] errs := FandocErr[,]

  ** If true, then leading lines starting with '**' are parsed as header
  Bool parseHeader := true

  internal Str filename := "" // filename for reporting errors
  private Str[]? lines        // lines of document
  private Int numLines        // lines.size
  private Int lineIndex       // current index in lines
  private Str? cur            // current line
  private Str? peek           // next line
  private LineType? curt      // current line type
  private LineType? peekt     // peek line type
  private Int curLine         // one based line number of cur
  private Int curIndent       // how many spaces is cur indented
  private Int peekIndent      // how many spaces is peek indented
  private Int curStart        // starting index of cur text
  private Int peekStart       // starting index of cur text
}

**************************************************************************
** LineType
**************************************************************************

internal enum class LineType
{
  eof,         // end of file
  blank,       // space*
  ul,          // space* "-" space*
  ol,          // space* (number|letter)* "." space*
  h1,          // ***
  h2,          // ===
  h3,          // ---
  blockquote,  // >
  preStart,    // pre>
  preEnd,      // <pre
  normal       // anything else

  Bool isList() { return this === ul }

  Int headingLevel()
  {
    switch (this)
    {
      case h1: return 1
      case h2: return 2
      case h3: return 3
      default: throw Err(toStr)
    }
  }
}
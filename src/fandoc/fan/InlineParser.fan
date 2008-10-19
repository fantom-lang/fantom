//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Feb 07  Brian Frank  Creation
//

**
** InlineParser parses a block of formatted text into
** a series of inline elements.
**
internal class InlineParser
{

//////////////////////////////////////////////////////////////////////////
// Parser
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor takes a closure which feeds characters.
  **
  new make(FandocParser parent, StrBuf src, Int startLine)
  {
    this.parent = parent
    this.src = src
    this.stack = DocNode[,]
    this.line = startLine

    // initialize cur and peek
    last = ' '
    cur = peek = -1
    if (src.size > 0) cur  = src[0]
    if (src.size > 1) peek = src[1]
    if (cur == '\n')  { ++line; cur= ' ' }
    if (peek == '\n') { ++line; peek = ' ' }
    pos = 0
  }

//////////////////////////////////////////////////////////////////////////
// Block
//////////////////////////////////////////////////////////////////////////

  Void parse(DocElem parent)
  {
    while (cur > 0)
      segment(parent)
  }

  private Void segment(DocElem parent)
  {
    stack.push(parent)
    DocNode? child
    if (last.isSpace || last == '*' || last == '/')
    {
      switch (cur)
      {
        case '\'': child = code
        case '`':  child = link
        case '[':  child = annotation(parent)
        case '*':  child = (peek == '*') ? strong : emphasis
        case '!':  child = (peek == '[') ? image : text
        default:   child = text
      }
    }
    else
    {
      child = text
    }

    if (child != null) parent.addChild(child)

    stack.pop
  }

  private Bool isTextEnd()
  {
    switch (cur)
    {
      // these characters always indicate a new segment
      // if preceeded by a space because they can't contain
      // embedded segments
      case '\'':
      case '`':
      case '[':
        return last.isSpace

      // check for end of emphasis/strong or start of new one
      case '*':
        if (stack.peek.id == DocNodeId.strong)
          return peek == '*'
        else if (stack.peek.id == DocNodeId.emphasis)
          return true
        else
          return last.isSpace

      default:
        return false
    }
  }

  private DocText text()
  {
    buf := StrBuf.make
    buf.addChar(cur)
    consume
    while (cur > 0 && !isTextEnd)
    {
      buf.addChar(cur)
      consume
    }
    return DocText(buf.toStr)
  }

  private DocNode code()
  {
    buf := StrBuf.make
    consume
    while (cur != '\'')
    {
      if (cur <= 0) throw err("Invalid code")
      buf.addChar(cur)
      consume
    }
    consume
    code := Code.make
    code.children.add(DocText(buf.toStr))
    return code
  }

  private DocNode emphasis()
  {
    if (peek <= 0 || peek.isSpace)
      return text

    em := Emphasis.make
    consume
    while (cur != '*' || peek == '*')
    {
      if (cur <= 0) throw err("Invalid *emphasis*")
      segment(em)
    }
    consume
    return em
  }

  private DocNode strong()
  {
    strong := Strong.make
    consume
    consume
    while (cur != '*' || peek != '*')
    {
      if (cur <= 0) throw err("Invalid **strong**")
      segment(strong)
    }
    consume
    consume
    return strong
  }

  private DocNode link()
  {
    link := Link(uri)
    link.children.add(DocText(link.uri))
    return link
  }

  private DocNode? annotation(DocElem parent)
  {
    if (peek <= 0 || peek == ']')
      return text

    s := brackets
    if (cur == '`')
    {
      link := Link(uri)
      link.children.add(DocText(s))
      return link
    }
    else if (s.startsWith("#"))
    {
      parent.anchorId = s[1..-1]
      return null
    }
    else
    {
      throw err("Invalid annotation [${s}]")
    }
  }

  private DocNode image()
  {
    consume // !
    alt := brackets
    uri := uri
    return Image(uri, alt)
  }

  private Str uri()
  {
    if (cur != '`') throw err("Invalid uri")
    consume  // leading `
    buf := StrBuf.make
    while (cur != '`')
    {
      if (cur <= 0) throw err("Invalid uri")
      buf.addChar(cur)
      consume
    }
    consume  // trailing `
    return buf.toStr
  }

  private Str brackets()
  {
    if (cur != '[') throw err("Invalid []")
    consume  // leading [
    buf := StrBuf.make
    while (cur != ']')
    {
      if (cur <= 0) throw err("Invalid []")
      buf.addChar(cur)
      consume
    }
    consume  // leading ]
    return buf.toStr
  }

////////////////////////////////////////////////////////////////
// Utils
////////////////////////////////////////////////////////////////

  **
  ** Make exception to terminate processing.
  **
  Err err(Str msg)
  {
    return FandocErr(msg, parent.filename, line)
  }

  **
  ** Consume the cur char and advance to next char in buffer:
  **  - updates cur and peek fields
  **  - end of file, sets fields to null
  **
  private Void consume()
  {
    last = cur
    cur = peek
    pos++
    if (pos+1 < src.size)
    {
      peek = src[pos+1] // next peek is cur+1
      if (peek == '\n') { ++line; peek = ' '; }
    }
    else
    {
      peek = -1
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private FandocParser parent // parent parser
  private StrBuf src          // characters to parse
  private Int line            // line
  private Int pos             // index into buf for cur
  private Int last            // last char
  private Int cur             // current char
  private Int peek            // next char
  private DocNode[] stack     // stack of nodes
}
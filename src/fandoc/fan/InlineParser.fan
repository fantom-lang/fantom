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
@Js
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
    if (last.isSpace || last == '*' || last == '/' || last == '(')
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

    if (child != null) parent.add(child)

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
        return last.isSpace || last == '('

      // ![
      case '!':
        return peek == '[' && last.isSpace

      // check for end of emphasis/strong or start of new one
      case '*':
        if (stack.peek.id == DocNodeId.strong)
          // if inside a strong, then end of strong, or start of emphasis
          // ends the current text.
          return peek == '*' || last.isSpace
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
    code.add(DocText(buf.toStr))
    return code
  }

  private DocNode emphasis()
  {
    if (peek <= 0 || peek.isSpace && peekPeek != '*')
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
    link.line = this.line
    link.add(DocText(link.uri))
    return link
  }

  private DocNode? annotation(DocElem parent)
  {
    if (peek <= 0 || peek == ']')
      return text

    // there are three options for square brackets
    //   [anchor]`url`         // hyperlink
    //   [![alt]`image`]`url`  // image hyperlink (no spaces allowed)
    //   [#frag]               // id to link to a heading

    DocNode? body
    Str? anchor
    if (peek == '!' && peekPeek == '[')
    {
      consume // [
      body = image
      if (cur != ']') throw err("Invalid img link")
      consume  // ]
    }
    else
    {
      s := brackets
      if (s.startsWith("#"))
      {
        parent.anchorId = s[1..-1]
        return null
      }
      body = DocText(s)
    }

    if (cur == '`')
    {
      link := Link(uri)
      link.add(body)
      return link
    }
    else
    {
      throw err("Invalid annotation []")
    }
  }

  private DocNode image()
  {
    consume // !
    alt := brackets
    size := null
    if (cur == '[') size = brackets
    uri := uri
    img := Image(uri, alt)
    img.size = size
    return img
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

  **
  ** Look at char after peek
  **
  private Int peekPeek()
  {
    if (pos+2 < src.size) return src[pos+2]
    return -1
  }

  private Str debug()
  {
    "cur='" + (cur <= 0 ? "eof" : cur.toChar) +
    "' peek='" + (peek <= 0 ? "eof" : peek.toChar) + "'"
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
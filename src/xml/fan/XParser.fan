//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 01  Brian Frank  Original public domain Java version
//    7 Nov 08  Brian Frank  Creation
//

**
** XParser is a simple, lightweight XML parser.  It may be
** used as a pull parser by iterating through the element
** and text sections of an XML stream or it may be used to
** read an entire XML tree into memory as XElems.
**
class XParser
{

////////////////////////////////////////////////////////////////
// Constructor
////////////////////////////////////////////////////////////////

  **
  ** Construct input stream to read.
  **
  new make(InStream in)
  {
    this.in = in
  }

//////////////////////////////////////////////////////////////////////////
// "DOM" API
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the entire document into memory as a tree
  ** of XElems and optionally close the underlying input
  ** stream.
  **
  XDoc parseDoc(Bool close := true)
  {
    try
    {
      parseProlog
      doc.root = parseElem(close)
      return doc
    }
    finally
    {
      if (close) this.close
    }
  }

  **
  ** Parse the current element entirely into memory as a tree
  ** of XElems and optionally close the underlying input
  ** stream.
  **
  XElem parseElem(Bool close := true)
  {
    try
    {
      depth := 1
      root := elem.copy
      XElem? cur := root
      while (depth > 0)
      {
        nodeType := next
        if (nodeType == null) throw eosErr
        switch (nodeType)
        {
          case XNodeType.elemStart:
            oldCur := cur
            cur = elem.copy
            oldCur.add(cur)
            depth++
          case XNodeType.elemEnd:
            cur = cur.parent
            depth--
          case XNodeType.text:
            cur.add(text.copy)
          case XNodeType.pi:
            cur.add(curPi)
          default:
            throw Err("unhandled node type: $nodeType")
        }
      }
      return root
    }
    finally
    {
      if (close) this.close
    }
  }

//////////////////////////////////////////////////////////////////////////
// Pull API
//////////////////////////////////////////////////////////////////////////

  **
  ** Advance the parser to the next node and return the node type.
  ** Return the current node type:
  **   - `XNodeType.elemStart`
  **   - `XNodeType.elemEnd`
  **   - `XNodeType.text`
  **   - `XNodeType.pi`
  **   - null indicates end of stream
  ** Also see `nodeType`.
  **
  XNodeType? next()
  {
    if (popStack)
    {
      popStack = false
      pop
    }

    if (emptyElem)
    {
      emptyElem = false
      popStack = true // pop stack on next call to next()
      return nodeType = XNodeType.elemEnd
    }

    while (true)
    {
      c := 0
      try { c = read } catch (XIncompleteErr e) { return nodeType = null }

      // markup
      if (c == '<')
      {
        c = read

        // comment, CDATA, or DOCType
        if (c == '!')
        {
          c = read
          if (c == '-')
          {
            c = read
            if (c != '-') throw err("Expecting comment")
            skipComment
            continue
          }
          else if (c == '[')
          {
            consume("CDATA[")
            parseCDATA()
            return nodeType = XNodeType.text
          }
          else if (c == 'D')
          {
             consume("OCTYPE")
             parseDocType
             continue
          }
          throw err("Unexpected markup")
        }

        // processor instruction
        else if (c == '?')
        {
          parsePi
          if (curPi.target.equalsIgnoreCase("xml")) continue
          if (depth < 0) doc.add(curPi)
          return nodeType = XNodeType.pi
        }

        // element end
        else if (c == '/')
        {
          parseElemEnd
          popStack = true  // pop stack on next call to next()
          return nodeType = XNodeType.elemEnd
        }

        // must be element start
        else
        {
          parseElemStart(c)
          return nodeType = XNodeType.elemStart
        }
      }

      // char data
      if (!parseText(c)) continue
      return nodeType = XNodeType.text
    }

    throw Err("illegal state")
  }

  **
  ** Skip parses all the content until reaching the end tag
  ** of the specified depth.  When this method returns, the
  ** next call to `next` will return the node immediately
  ** following the end tag.
  **
  Void skip(Int toDepth := depth)
  {
    while (true)
    {
      if (nodeType === XNodeType.elemEnd && depth == toDepth) return
      nodeType = next()
      if (nodeType == null) throw eosErr
    }
  }

  **
  ** Get the root document node.
  **
  readonly XDoc doc := XDoc()

  **
  ** Get the current node type constant which is always the
  ** result of the last call to `next`.  Node type will be:
  **   - `XNodeType.elemStart`
  **   - `XNodeType.elemEnd`
  **   - `XNodeType.text`
  **   - `XNodeType.pi`
  **   - null indicates end of stream
  **
  readonly XNodeType? nodeType

  **
  ** Get the depth of the current element with the document.
  ** A depth of zero indicates the root element.  A depth
  ** of -1 indicates a position before or after the root element.
  **
  readonly Int depth := -1

  **
  ** Get the current element if `nodeType` is 'elemStart' or
  ** 'elemEnd'.  If `nodeType` is 'text' or 'pi' then this is the
  ** parent element.  After 'elemEnd' this XElem instance is no
  ** longer valid and will be reused for further processing.  If
  ** depth is -1 return null.
  **
  XElem? elem()
  {
    if (depth < 0) return null
    return stack[depth]
  }

  **
  ** Get the element at the specified depth.  Depth must be between 0
  ** and `depth` inclusively.  Calling 'elemAt(0)' will return the
  ** root element and 'elemAt(depth)' returns the current element.
  ** If depth is invalid IndexErr is thrown.
  **
  XElem elemAt(Int depth)
  {
    if (depth < 0 || depth > this.depth) throw IndexErr(depth.toStr)
    return stack[depth]
  }

  **
  ** If the current type is 'text' the XText instance used to
  ** store the character data.  After a call to `next`
  ** this XText instance is no longer valid and will be reused for
  ** further processing.  If the current type is not 'text' then
  ** return null.
  **
  XText? text()
  {
    if (nodeType !== XNodeType.text) return null
    return XText(buf.toStr) { it.cdata = this.cdata }
  }

  **
  ** if the current node type is 'pi' return the XPi instance
  ** otherwise return null.
  **
  XPi? pi()
  {
    if (nodeType !== XNodeType.pi) return null
    return curPi
  }

  **
  ** Current one based line number.
  **
  readonly Int line := 1

  **
  ** Current one based column number.
  **
  readonly Int col := 1

  **
  ** Close the underlying input stream.  Return true if the stream
  ** was closed successfully or false if the stream was closed abnormally.
  **
  Bool close()
  {
    return in.close
  }

//////////////////////////////////////////////////////////////////////////
// Parse Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the prolog up to the root element.
  **
  private Void parseProlog()
  {
    while (next() !== XNodeType.elemStart)
    {
      // processing instructions are ok in prolog
      if (nodeType === XNodeType.pi) continue

      // anything else is bad
      throw err("Expecting element start, not $nodeType")
    }
  }

  **
  ** Parse '[28]' DocType := <!DOCTYPE ... >
  **
  private Void parseDocType()
  {
    // parse root element name
    skipSpace
    rootElem := parseName(read, true)

    // check for publicId/systemId
    skipSpace
    Str? publicId := null
    Str? systemId := null
    c := read
    if (c == 'P' || c == 'S')
    {
      key := parseName(c, false)
      if (key == "PUBLIC")
      {
        skipSpace; c = read
        if (c == '"' || c == '\'') publicId = parseQuotedStr(c)
        else pushback = c

        skipSpace; c = read
        if (c == '"' || c == '\'') systemId = parseQuotedStr(c)
        else pushback = c
      }
      else if (key == "SYSTEM")
      {
        skipSpace; c = read
        if (c == '"' || c == '\'') systemId = parseQuotedStr(c)
        else pushback = c
      }
    }
    else pushback = c

    // init XDocType
    docType := doc.docType = XDocType()
    docType.rootElem = rootElem
    docType.publicId = publicId
    try
    {
      if (systemId != null) docType.systemId = Uri.decode(systemId)
    }
    catch (Err e)
    {
      throw err("Invalid system id uri: $systemId")
    }

    // skip the rest of the doctype
    depth := 1
    while (true)
    {
      c = read
      if (c == '<') depth++
      if (c == '>') depth--
      if (depth == 0) return
    }
  }

  **
  ** Parse a '[40]' element start production.  We are passed
  ** the first character after the < (beginning of name).
  **
  private Void parseElemStart(Int c)
  {
    // get our next XElem onto stack to reuse
    elem := push
    startLine := this.line
    startCol := this.col - 1

    // prefix / name
    parseQName(c)
    elem.name = name
    elem.line = line
    prefix := this.prefix
    resolveAttrNs := false

    // attributes
    while (true)
    {
      sp := skipSpace
      c = read
      if (c == '>')
      {
        break
      }
      else if (c == '/')
      {
        c = read
        if (c != '>') throw err("Expecting /> empty element")
        emptyElem = true
        break
      }
      else
      {
        if (!sp) throw err("Expecting space before attribute", line, col-1)
        resolveAttrNs = resolveAttrNs.or(parseAttr(c, elem))
      }
    }

    // after reading all the attributes, now it is safe to
    // resolve prefixes into their actual XNs instances
    // first resolve the element itself...
    if (prefix == null)
      elem.ns = defaultNs
    else
      elem.ns = prefixToNs(prefix, startLine, startCol, true)

    // if we detected an unresolved attribute namespace prefix, try
    // to resolve it now that we've fully parsed the start tag
    if (resolveAttrNs)
    {
      elem.eachAttr |XAttr a, Int i|
      {
        if (a.uri !== unresolvedNs) return
        ns := prefixToNs(a.ns.prefix, startLine, startCol, true)
        elem.attrList[i] = XAttr(a.name, a.val, ns)
      }
    }
  }

  **
  ** Parse an element end production.  Next character
  ** should be first char of element name.
  **
  private Void parseElemEnd()
  {
    // prefix / name
    line := this.line
    col  := this.col
    parseQName(read)
    XNs? ns := null
    if (prefix == null)
      ns = defaultNs
    else
      ns = prefixToNs(prefix, line, col, true)

    // get end element
    if (depth < 0) throw err("Element end without start", line, col)
    elem := stack[depth]

    // verify
    if (elem.name != name || elem.ns !== ns)
      throw err("Expecting end of element '${elem.qname}' (start line ${elem.line})", line, col)

    skipSpace
    if (read != '>')
      throw err("Expecting > end of element")
  }

  **
  ** Parse a '[41]' attribute production.  We are passed
  ** the first character of the attribute name.  Return
  ** if the attribute had a unresolved namespace prefix.
  **
  private Bool parseAttr(Int c, XElem elem)
  {
    // prefix / name
    startLine := this.line
    startCol := this.col - 1
    parseQName(c)
    prefix := this.prefix
    name   := this.name

    // Eq [25] production
    skipSpace
    if (read != '=') throw err("Expecting '='", line, col-1)
    skipSpace

    // String literal
    c = read
    if (c != '"' && c != '\'') throw err("Expecting quoted attribute value", line, col-1)
    val := parseQuotedStr(c)

    // check namespace declaration "xmlns", "xmlns:foo", or "xml:foo"
    if (prefix == null)
    {
      if (name == "xmlns")
      {
        pushNs("", val, startLine, startCol)
      }
    }
    else
    {
      if (prefix == "xmlns")
      {
        pushNs(name, val, startLine, startCol)
        prefix = null
        name = "xmlns:" + name
      }
      else if (prefix.equalsIgnoreCase("xml"))
      {
        prefix = null
        name = "xml:" + name
      }
    }

    // if no prefix then add unqualified attribute
    if (prefix == null) { elem.addAttr(name, val); return false }

    // attempt to resolve prefix to namespace, this may fail if
    // prefix is in the current element, in which case we return
    // true to resolve after the element start tag is complete
    ns := prefixToNs(prefix, line, col, false)
    elem.addAttr(name, val, ns)
    return ns.uri === unresolvedNs
  }

  **
  ** Parse an element or attribute name of the
  ** format '[<prefix>:]name' and store result in
  ** prefix and name fields.
  **
  private Void parseQName(Int c)
  {
    prefix = null
    name = parseName(c, false)

    c = read
    if (c == ':')
    {
      prefix = name
      name = parseName(read, true)
    }
    else
    {
      pushback = c
    }
  }

  **
  ** Parse a quoted string token "..." or '...'
  **
  private Str parseQuotedStr(Int quote)
  {
    buf := this.buf
    buf.clear
    c := 0
    while ((c = read) != quote) buf.addChar(toCharData(c))
    return bufToStr
  }

  **
  ** Parse an XML name token.
  **
  private Str parseName(Int c, Bool includeColon)
  {
    if (!isName(c)) throw err("Expected XML name")

    buf := this.buf
    buf.clear.addChar(c)
    if (includeColon)
    {
      while (isName(c = read) || c == ':') buf.addChar(c)
    }
    else
    {
      while (isName(c = read)) buf.addChar(c)
    }
    pushback = c
    return bufToStr
  }

  **
  ** Parse a CDATA section.
  **
  private Void parseCDATA()
  {
    buf.clear
    cdata = true

    c2 := -1; c1 := -1; c0 := -1
    while (true)
    {
      c2 = c1
      c1 = c0
      c0 = read
      if (c2 == ']' && c1 == ']' && c0 == '>')
      {
        buf.remove(-1).remove(-1)
        return
      }
      buf.addChar(c0)
    }
  }


  **
  ** Parse a character data text section.  Return
  ** false if all the text was whitespace only.
  **
  private Bool parseText(Int c)
  {
    line := this.line
    col  := this.col - 1
    gotText := !isSpace(c)
    buf.clear.addChar(toCharData(c))
    cdata = false

    while (true)
    {
      try
      {
        c = read
      }
      catch (XIncompleteErr e)
      {
        if (!gotText) return false
        if (depth < 0) throw XErr("Expecting root element", line, col)
        throw e
      }

      if (c == '<')
      {
        pushback = c
        if (gotText && depth < 0) throw XErr("Expecting root element", line, col)
        return gotText
      }

      if (!isSpace(c)) gotText = true
      buf.addChar(toCharData(c))
    }

    throw Err("illegal state")
  }

  **
  ** Parse '[16]' PI := <? ... ?>
  **
  private Void parsePi()
  {
    target := parseName(read, true)
    skipSpace
    buf.clear
    c1 := -1; c0 := -1
    while (true)
    {
      c1 = c0
      c0 = read
      if (c1 == '?' && c0 == '>') break
      buf.addChar(c0)
    }
    buf.remove(-1)
    curPi = XPi(target, buf.toStr)
  }

//////////////////////////////////////////////////////////////////////////
// Skip Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Skip '[3]' Space = ' ' '\n' '\r' '\t'
  ** Return true if one or more space chars found.
  **
  private Bool skipSpace()
  {
    c := read
    if (!isSpace(c))
    {
      pushback = c
      return false
    }

    while (isSpace(c = read())) {}
    pushback = c
    return true
  }

  **
  ** Skip '[15]' Comment := <!-- ... -->
  **
  private Void skipComment()
  {
    c2 := -1; c1 := -1; c0 := -1
    while (true)
    {
      c2 = c1
      c1 = c0
      c0 = read
      if (c2 == '-' && c1 == '-')
      {
        if (c0 != '>') throw err("Cannot have -- in middle of comment")
        return
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Consume Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Read from the stream and verify that the next
  ** characters match the specified String.
  **
  private Void consume(Str s)
  {
    s.each |Int expected|
    {
      if (expected != read) throw err("Expected '" + expected.toChar + "'")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Read
//////////////////////////////////////////////////////////////////////////

  **
  ** Read the next character from the stream:
  **  - handle pushbacks
  **  - updates the line and col count
  **  - normalizes line breaks
  **  - throw EOFException if end of stream reached
  **
  private Int read()
  {
    // check pushback
    c := pushback
    if (c != -1) { pushback = -1; return c }

    // read the next character
    cx := in.readChar
    if (cx == null) throw eosErr
    c = cx

    // update line:col and normalize line breaks (2.11)
    if (c == '\n')
    {
      line++; col=1
      return '\n'
    }
    else if (c == '\r')
    {
      lookAhead := in.readChar
      if (lookAhead != null && lookAhead != '\n') pushback = lookAhead
      line++; col=0
      return '\n'
    }
    else
    {
      col++
      return c
    }
  }

  **
  ** If the specified char is the amp (&) then resolve
  ** the entity otherwise just return the char.  If the
  ** character is markup then throw an exception.
  **
  private Int toCharData(Int c)
  {
    if (c == '<')
      throw err("Invalid markup in char data")

    if (c != '&') return c

    c = read

    // &#_; and &#x_;
    if (c == '#')
    {
      c = in.readChar; col++
      x := 0
      base := 10
      if (c == 'x') base = 16
      else x = toNum(x, c, base)
      c = in.readChar; col++
      while (c != ';')
      {
        x = toNum(x, c, base)
        c = in.readChar; col++
      }
      return x
    }

    ebuf := this.entityBuf
    ebuf.clear
    ebuf.addChar(c)
    while ((c = read()) != ';') ebuf.addChar(c)
    entity := ebuf.toStr

    if (entity == "lt")   return '<'
    if (entity == "gt")   return '>'
    if (entity == "amp")  return '&'
    if (entity == "quot") return '"'
    if (entity == "apos") return '\''

    throw err("Unsupported entity &${entity};")
  }

  private Int toNum(Int x, Int c, Int base)
  {
    digit := c.fromDigit(base)
    if (digit == null) err("Expected base $base number")
    return x * base + digit
  }

  private Str bufToStr()
  {
    return buf.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Namespace Scoping
//////////////////////////////////////////////////////////////////////////

  **
  ** Map the prefix string to a XNs instance declared
  ** in the current element or ancestor element.  If the prefix cannot
  ** be found and checked if false then return 'unresolvedNs', otherwise
  ** throw exception.
  **
  private XNs prefixToNs(Str prefix, Int line, Int col, Bool checked)
  {
    for (i:=depth; i>=0; --i)
    {
      ns := nsStack[i].find(prefix)
      if (ns != null) return ns
    }
    if (!checked) return XNs(prefix, unresolvedNs)
    throw err("Undeclared namespace prefix '${prefix}'", line, col)
  }

  **
  ** Push a namespace onto the stack at the current depth.
  **
  private Void pushNs(Str prefix, Str val, Int line, Int col)
  {
    // parse value into uri
    uri := ``
    try
      if (!val.isEmpty) uri = Uri.decode(val)
    catch (Err e)
      throw err("Invalid namespace uri $val", line, col)

    // make ns instance
    ns := XNs(prefix, uri)

    // update stack
    nsStack[depth].list.add(ns)

    // re-evaluate default ns
    if (prefix.isEmpty) reEvalDefaultNs
  }

  **
  ** Recalculate what the default namespace should be
  ** because we just popped the element that declared
  ** the default namespace last.
  **
  private Void reEvalDefaultNs()
  {
    defaultNs = null
    for (i:=depth; i>=0; --i)
    {
      defaultNs = nsStack[i].find("")
      if (defaultNs != null)
      {
        if (defaultNs.uri.toStr.isEmpty) defaultNs = null
        return
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Stack
//////////////////////////////////////////////////////////////////////////

  **
  ** Push a new XElem on the stack.  The stack itself
  ** only allocates a new XElem the first time a given
  ** depth is reached.  Further pushes at that depth
  ** will always reuse the last XElem from the given
  ** depth.
  **
  private XElem push()
  {
    // attempt to reuse element from given depth
    depth++
    try
    {
      elem := stack[depth].clearAttrs
      return elem
    }
    catch (IndexErr e)
    {
      elem := XElem("")
      stack.add(elem)
      nsStack.add(XNsDefs())
      return elem
    }
  }

  **
  ** Pop decreases the element depth, but leaves the
  ** actual element in the stack for reuse.  However
  ** we do need to re-evaluate our namespace scope if
  ** the popped element declared namespaces.
  **
  private Void pop()
  {
    nsDefs := nsStack[depth]
    if (!nsDefs.isEmpty)
    {
      nsDefs.clear
      reEvalDefaultNs
    }
    depth--
  }

//////////////////////////////////////////////////////////////////////////
// Error
//////////////////////////////////////////////////////////////////////////

  **
  ** Make an XException using with current line and column.
  **
  private XErr err(Str msg, Int line := this.line, Int col := this.col)
  {
    return XErr(msg, line, col)
  }

  **
  ** Make an XIncompleteErr for unexected end of stream.
  **
  private XErr eosErr()
  {
    throw XIncompleteErr("Unexpected end of stream", line, col)
  }

//////////////////////////////////////////////////////////////////////////
// Test
//////////////////////////////////////////////////////////////////////////

  /*
  static Void main()
  {
    t1 := Duration.now
    m1 := Sys.diagnostics["mem.heap"].toStr.toInt

    doc := XParser(File.os(Sys.args[0]).in).parseDoc
    doc.write(Env.cur.out)

    m2 := Sys.diagnostics["mem.heap"].toStr.toInt
    t2 := Duration.now
    echo("Mem " + ((m2-m1)/1024) + "kb " + (t2-t1).toMillis + "ms")
  }
  */

//////////////////////////////////////////////////////////////////////////
// Char Map
//////////////////////////////////////////////////////////////////////////

  private static Bool isName(Int c)  { return (c < 128) ? nameMap[c] : true }
  private static Bool isSpace(Int c) { return (c < 128) ? spaceMap[c] : false }

  private static const Bool[] nameMap
  private static const Bool[] spaceMap
  static
  {
    name := Bool[,]
    128.times |->| { name.add(false) }
    for (i:='a'; i<='z'; ++i) name[i] = true
    for (i:='A'; i<='Z'; ++i) name[i] = true
    for (i:='0'; i<='9'; ++i) name[i] = true
    name['-'] = true
    name['.'] = true
    name['_'] = true
    nameMap = name

    space := Bool[,]
    128.times |->| { space.add(false) }
    space['\n'] = true
    space['\r'] = true
    space[' ']  = true
    space['\t'] = true
    spaceMap = space
  }

//////////////////////////////////////////////////////////////////////////
// Fieldsname
//////////////////////////////////////////////////////////////////////////

  private const static Uri unresolvedNs := `__unresolved__`

  private InStream in
  private Int pushback := -1
  private XElem[] stack := [XElem("")]
  private XNsDefs[] nsStack := [XNsDefs()]
  private XNs? defaultNs
  private XPi? curPi
  private StrBuf buf := StrBuf()         // working string buffer
  private StrBuf entityBuf := StrBuf()   // working string buffer
  private Bool cdata      // is current buf CDATA section
  private Str? name       // result of parseQName()
  private Str? prefix     // result of parseQName()
  private Bool popStack   // used for next event
  private Bool emptyElem  // used for next event

}

**************************************************************************
** NsDefs
**************************************************************************

internal class XNsDefs
{
  XNs? find(Str prefix)
  {
    if (list.isEmpty) return null
    for (i:=0; i<list.size; ++i)
      if (list[i].prefix == prefix) return list[i]
    return null
  }

  Bool isEmpty() { return list.isEmpty }

  Void clear() { list.clear }

  XNs[] list := XNs[,]
}
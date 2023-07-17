#! /usr/bin/env fan
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    5 Jul 2022  Kiera O'Flynn   Creation
//

using util

internal class YamlParser
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(InStream in, FileLoc loc := FileLoc.unknown)
  {
    this.r = YamlTokenizer(in, loc)
  }

//////////////////////////////////////////////////////////////////////////
// Parsing
//////////////////////////////////////////////////////////////////////////

  ** Parse a whole YAML input stream.
  **
  ** [211] l-yaml-stream
  YamlObj[] parse()
  {
    docs = [,]
    parseDocument
    return docs
  }

  ** Parse an individual document.
  **
  ** [211] l-yaml-stream
  ** [210] l-any-document
  private Void parseDocument()
  {
    //document setup
    tagShorthands = [:]
    anchors = [:]
    anchorsInProgress = [,]

    assertLineStart

    //leading comments & byte order marks
    while((['#', '\n'] as Int?[]).contains(r.peekNextNs(r.docPrefix))) r.eatLine(r.docPrefix)
    while(r.peek(r.any) == 0xFFFE) r.any

    //directive/explicit document
    if (r.peek == '%' || r.peekToken == "---")
    {
      parseDirectives

      // Completely empty document
      if (r.peekIndentedNs(0, r.docPrefix) == null || r.nextTokenEndsDoc)
      {
        startLoc := r.loc
        sLComments(r.docPrefix)
        docs.add(YamlScalar("", "?", startLoc))
        if (r.peekToken(r.docPrefix) == "...") parseDocEnd
        else if (r.peekToken(r.docPrefix) == "---") parseDocument
        return
      }
    }

    //no document
    else if (r.peekToken == "...") { parseDocEnd; return }
    else if (r.peekNextNs == null) return

    //default - bare document (do nothing special)

    if (!tagShorthands.containsKey("!")) tagShorthands.add("!", "!")
    if (!tagShorthands.containsKey("!!")) tagShorthands.add("!!", "tag:yaml.org,2002:")
    docs.add(parseBlockNode(-1, Context.blockIn))

    //move onto next document, if applicable
    while (r.peek(r.docPrefix) != null && ['#', '\n', null].contains(r.peekNextNs(r.docPrefix)))
      r.eatLine(r.docPrefix)

    if (r.peekToken(r.docPrefix) == "...") parseDocEnd
    else if (r.peekToken(r.docPrefix) == "---") parseDocument
    else if (r.peek(r.docPrefix) != null)
      throw err("You cannot have multiple top-level nodes in a single document.")
  }

  ** Parse the directive section (containing 0 or more directive lines),
  ** adding its information to the current document.
  ** Includes the '---' directive end marker.
  **
  ** [82] l-directive
  ** [203] c-directives-end
  private Void parseDirectives()
  {
    // you can only use the YAML directive once
    doneYaml := false

    while (r.peek != '-' && r.peek != null) //---
    {
      if (r.peek != '%')
      {
        r.eatCommentLine("An empty directive line")
        continue
      }

      assertLineStart
      r.eatChar('%')

      name := r.eatToken
      switch (name)
      {
        case "YAML":
          if (doneYaml)
            throw err("The YAML directive must only be given at most once per document.")

          r.eatWs
          ver := r.eatToken.split('.')
          maj := 0
          min := 0
          try
          {
            if (ver.size != 2) throw ParseErr()
            maj = Int.fromStr(ver[0])
            min = Int.fromStr(ver[1])
          } catch (ParseErr e) {
            throw err("The YAML version is not correctly formatted as [major version].[minor version].")
          }

          if (maj < 1) throw Err("${maj}.${min} is not a valid YAML version.")
          if (maj > 1) throw Err("This processor is written for YAML version 1.2 and cannot process higher major versions.")

          if (min < 1) throw Err("${maj}.${min} is not a valid YAML version.")
          else if (min > 2)  echo("This Fantom processor is written for YAML version 1.2, and thus can only parse this document as " +
                                  "a YAML 1.2 document rather than a YAML ${maj}.${min} document.")
          else if (min == 1) echo("This Fantom processor is written for YAML version 1.2, and thus can only parse this document as " +
                                  "a YAML 1.2 document rather than a YAML 1.1 document. While this does not lead to " +
                                  "incompatibilities for the most part, beware that any line break characters other than \\n and " +
                                  "\\r (i.e. Unicode line breaks and separators) will be processed as non-break characters.")

          doneYaml = true
          r.eatCommentLine("A YAML directive")

        case "TAG":
          r.eatWs
          hloc   := r.loc
          r.eatChar('!')
          handle := "!" + r.eatUntilr(r.tagHandle) |c1| { !r.isNs(c1) || c1 == '!' }
          if (r.peek == '!')
          {
            r.eatToken("!")
            handle += "!"
          }
          else if (handle != "!") throw err("A named tag handle must end in the '!' character.", hloc)
          r.eatWs
          ploc   := r.loc
          prefix := r.eatToken(null, r.uri)
          r.eatCommentLine("A TAG directive")

          // Ensure two parameters are present
          if (prefix.size == 0) throw err("Two parameters for the TAG directive are not present.")

          // Format check the prefix
          if (r.isFlow(prefix[0]))
            throw err("A tag prefix cannot start with a flow character.", ploc)
          if (prefix[0] != '!')
          {
            uri := Uri.fromStr(prefix, false)
            if (uri == null) throw err("$prefix is a not a valid URI.", ploc)
            else if (uri.scheme == null) throw err("The URI $prefix does not include a scheme.", ploc)
          }

          // Add handle-prefix to shorthand mapping
          if (tagShorthands.containsKey(handle))
            throw err("The tag handle \"$handle\" is already registered for this document.", hloc)
          tagShorthands.add(handle, prefix)

        case "":
          throw err("A directive name cannot be empty.")

        default:
          echo("The directive $name is not defined in YAML 1.2.2.")
          r.eatLine
      }
    }

    r.eatToken("---")
  }

  ** Parse a (potentially) block node, where the parent has 'n' indent
  ** level and provides 'ctx' context.
  **
  ** [196] s-l+block-node(n,c)
  private YamlObj parseBlockNode(Int n, Context ctx)
  {
    c := r.peekIndentedNs(n+1, r.docPrefix)

    // [197] s-l+flow-in-block(n)
    // containing [104] c-ns-alias-node
    if (c == '*' && !nextNodeIsKey(n+1,ctx))
    {
      separate(n+1, Context.flowOut)
      a := parseAlias(Context.flowOut)
      sLComments
      return a
    }

    anchor := ""
    tag := ""
    FileLoc? startLoc

    //parse properties, if they are specified
    if ((['&', '!'] as Int?[]).contains(c = r.peekIndentedNs(n+1, r.docPrefix)) &&
        !nextNodeIsKey(n+1,ctx))
    {
      separate(n+1, ctx)
      startLoc = r.loc
      p := parseProperties(n+1, ctx)
      if (p.containsKey("anchor")) anchor = p["anchor"]
      if (p.containsKey("tag")) tag = p["tag"]
      c = r.peekIndentedNs(n+1, r.docPrefix)
    }

    //register anchor as in-progress, if applicable
    if (anchor != "")
      anchorsInProgress.add(anchor)

    node := |->YamlObj|
    {
      //parse block collections
      seqSpacing := ctx == Context.blockOut ? n-1 : n

      if (r.peekIndentedToken(seqSpacing+1, r.any) == "-")
      {
        sLComments
        return parseBlockSeq(seqSpacing, tag, startLoc)
      }
      else if (r.peekIndentedToken(n+1, r.any) == "?" || nextNodeIsKey(n+1,ctx))
      {
        sLComments
        return parseBlockMap(n, tag, startLoc)
      }

      //mark empty nodes ending the document
      if (r.nextTokenEndsDoc) c = null

      //parse any other type of node
      switch (c)
      {
        case '|':
          separate(n+1,ctx)
          return parseLiteral(n+1, tag, startLoc)
        case '>':
          separate(n+1,ctx)
          return parseFolded(n+1, tag, startLoc)
        case '\'':
          separate(n+1, Context.flowOut)
          return objSLComments(r.loc.line, true, parseSingleQuote(n+1, Context.flowOut, tag, startLoc))
        case '"':
          separate(n+1, Context.flowOut)
          return objSLComments(r.loc.line, true, parseDoubleQuote(n+1, Context.flowOut, tag, startLoc))
        case '{':
          separate(n+1, Context.flowOut)
          return objSLComments(r.loc.line, true, parseFlowMap(n+1, Context.flowOut, tag, startLoc))
        case '[':
          separate(n+1, Context.flowOut)
          return objSLComments(r.loc.line, true, parseFlowSeq(n+1, Context.flowOut, tag, startLoc))
        case null:
          sLComments
          if (anchor != "" || tag != "")
            return YamlScalar("", tag, startLoc)
          else
            throw err("A node cannot be completely empty here.")
        default:
          separate(n+1, Context.flowOut)
          return objSLComments(r.loc.line, false, parsePlain(n+1, Context.flowOut, tag, startLoc))
      }
    }()

    //change anchor status from in progress to permanent, if applicable
    if (anchor != "")
    {
      anchorsInProgress.remove(anchor)
      anchors[anchor] = node
    }

    return node
  }

  ** [161] ns-flow-node(n,c)
  private YamlObj parseFlowNode(Int n, Context ctx)
  {
    // [104] c-ns-alias-node
    if (r.peek == '*') return parseAlias(ctx)

    anchor := ""
    tag := ""
    startLoc := r.loc

    //parse properties, if they are specified
    if (r.peek == '&' || r.peek == '!')
    {
      p := parseProperties(n,ctx)
      if (p.containsKey("anchor")) anchor = p["anchor"]
      if (p.containsKey("tag")) tag = p["tag"]
      separate(n,ctx)
    }

    //register anchor as in-progress, if applicable
    if (anchor != "")
      anchorsInProgress.add(anchor)

    node := |->YamlObj|
    {
      c := r.peekIndentedNs(n)

      if (c == '{')       return parseFlowMap(n,ctx,tag,startLoc)
      else if (c == '[')  return parseFlowSeq(n,ctx,tag,startLoc)
      else if (c == '\'') return parseSingleQuote(n,ctx,tag,startLoc)
      else if (c == '"')  return parseDoubleQuote(n,ctx,tag,startLoc)
      else if (c == null ||                        // Empty node (nothing ending it)
               r.peekIndentedToken(n) == ":" ||    // Ended by ": "
              ((ctx == Context.flowIn || ctx == Context.flowKey) &&
               (r.isFlowEnd(c) ||                                       // Ended by } ] ,
                r.peekIndentedUntil(n) |c1| { r.isFlowEnd(c1) } == ":") // Ended by ":}", etc.
              ))
      {
        if (anchor == "" && tag == "")
          throw err("A node cannot be completely empty here.")
        return YamlScalar("", tag, startLoc)
      }
      else return parsePlain(n,ctx,tag,startLoc)
    }()

    //change anchor status from in progress to permanent, if applicable
    if (anchor != "")
    {
      anchorsInProgress.remove(anchor)
      anchors[anchor] = node
    }

    return node
  }

  ** [104] c-ns-alias-node
  private YamlObj parseAlias(Context ctx)
  {
    startLoc := r.loc
    r.eatChar('*')
    name := r.eatUntil |c1| { !r.isNs(c1) || ((ctx == Context.flowIn || ctx == Context.flowKey) && r.isFlowEnd(c1)) }

    if (name == "")
      throw err("An alias name must be at least one character long.")
    else if (anchors.containsKey(name))
      return setLoc(anchors[name], startLoc)
    else if (anchorsInProgress.contains(name))
      throw err("This parser does not support self-containing nodes.")
    else
      throw err("No previous node has been given the anchor &${name}.")
  }

  ** Parse a properties block (tag and/or anchor, in any order),
  ** and return the results in a map of "tag" to the tag and "anchor"
  ** to the anchor (one of which may not be present).
  **
  ** [96] c-ns-properties(n,c)
  private [Str:Str] parseProperties(Int n, Context ctx)
  {
    Int? c
    [Str:Str] res := [:]
    |Int?->Bool| wsOrFlow := |Int? c1->Bool| { !r.isNs(c1) || ((ctx == Context.flowIn || ctx == Context.flowKey) && r.isFlowEnd(c1)) }
    line := r.loc.line

    while ((['&', '!'] as Int?[]).contains(c = r.peekIndentedNs(n)) &&
           ((r.loc.line == line && r.peekNextNs == c) || !nextNodeIsKey(n,ctx)))
    {
      // [101] c-ns-anchor-property
      if (c == '&')
      {
        if (res.containsKey("anchor")) return res
        separate(n,ctx)
        r.eatChar('&')
        name := r.eatUntil(wsOrFlow)
        if (name == "")
          throw err("An anchor name must be at least one character long.")
        res["anchor"] = name
      }
      // [97] c-ns-tag-property
      else
      {
        if (res.containsKey("tag")) return res
        tloc := r.loc
        separate(n,ctx)
        r.eatChar('!')

        // [98] c-verbatim-tag
        if (r.peek == '<')
        {
          r.eatChar('<')
          name := r.eatUntilr(r.uri) |c1| { c1 == '>' }
          r.eatToken(">")

          if (name == "") throw err("A tag cannot be empty.", tloc)
          else if (!name.startsWith("!"))
          {
            uri := Uri.fromStr(name, false)
            if (uri == null) throw err("$name is a not a valid URI.", tloc)
            else if (uri.scheme == null) throw err("The URI $name does not include a scheme.", tloc)
          }
          else if (name == "!") throw err("Verbatim tags aren't resolved, so ! is invalid.", tloc)
          res["tag"] = name
        }

        // [100] c-non-specific-tag
        else if (wsOrFlow(r.peek))
        {
          res["tag"] = "!"
        }

        // [99] c-ns-shorthand-tag
        else
        {
          if (r.peekUntil(wsOrFlow).containsChar('!'))
          {
            handle := "!" + r.eatUntilr(r.tagHandle) |c1| { c1 == '!' } + "!"
            r.eatChar('!')
            suffix := r.eatUntilr(r.tagSuffix, wsOrFlow)

            if (!tagShorthands.containsKey(handle))
              throw err("$handle is not a registered tag shorthand handle in this document.")
            if (suffix == "")
              throw err("The $handle handle has no suffix.")
            res["tag"] = tagShorthands[handle] + suffix
          }
          else
          {
            suffix := r.eatUntilr(r.tagSuffix, wsOrFlow)
            res["tag"] = tagShorthands["!"] + suffix
          }
        }
      }
    }
    return res
  }

  ** [170] c-l+literal(n)
  private YamlScalar parseLiteral(Int n, Str tag, FileLoc? loc)
  {
    startLoc := loc ?: r.loc
    s := StrBuf()

    r.eatChar('|')

    line := r.loc.line
    head := parseBlockHeader(n)
    //edge case where the stream ends after the block header
    if (r.loc.line == line)
      return YamlScalar("", tag == "" ? "!" : tag, startLoc)

    /* Null indent: The indentation has not been assigned or detected.
     * Negative indent: The indentation has been detected, but not confirmed
     *  by the presence of a non-empty line.
     * Non-negative indent: The indentation has been confirmed.
     */
    Int? indent := head.getChecked("indent", false)
    chomp       := head["chomp"]

    // [171] l-nb-literal-text(n)
    // [172] b-nb-literal-next(n)*
    while(!["---", "..."].contains(r.peekToken(r.docPrefix)))
    {
      // Indentation detection
      next := r.peekPast  |c1| { c1 == ' ' }
      i    := r.peekUntil |c1| { c1 != ' ' }.size

      if (indent == null)  indent = -(i+1).max(n+1)
      else if (indent < 0) indent = -(i+1).max(-indent)

      indPos := indent < 0 ? -indent - 1 : indent
      if (i < indPos && next != null && next != '\n')
      {
        if ((next == '#' && indent >= 0) || (i < n && next != '\t')) break
        else throw err("Text cannot be indented less than $indPos spaces in this literal block.")
      }

      // l-empty(n,BLOCK-IN)*
      if ((indent < 0 || i <= indent) && (next == null || next == '\n'))
        r.eatLine(r.ws)

      // s-indent(n) nb-char+
      else
      {
        if (indent < 0) indent = indPos
        r.eatInd(indent)
        s.add(r.eatLine)
      }

      s.addChar('\n')
      if (r.peek(r.docPrefix) == null) break
    }

    sLComments

    if (chomp == "strip")
      while (!s.isEmpty && s[-1] == '\n') s.remove(-1)
    else if (chomp == "clip")
    {
      while (s.size > 1 && s[-1] == '\n' && s[-2] == '\n') s.remove(-1)
      if (s.size == 1 && s[0] == '\n') s.remove(0)
    }

    return YamlScalar(s.toStr, tag == "" ? "!" : tag, startLoc)
  }

  ** [174] c-l+folded(n)
  private YamlScalar parseFolded(Int n, Str tag, FileLoc? loc)
  {
    startLoc := loc ?: r.loc
    s := StrBuf()

    r.eatChar('>')
    head := parseBlockHeader(n)

    /* Null indent: The indentation has not been assigned or detected.
     * Negative indent: The indentation has been detected, but not confirmed
     *  by the presence of a non-empty line.
     * Non-negative indent: The indentation has been confirmed.
     */
    Int? indent := head.getChecked("indent", false)
    chomp       := head["chomp"]
    inFolded    := false

    // [171] l-nb-literal-text(n)
    // [172] b-nb-literal-next(n)*
    while(!["---", "..."].contains(r.peekToken(r.docPrefix)))
    {
      // Indentation detection
      next := r.peekPast  |c1| { c1 == ' ' }
      i    := r.peekUntil |c1| { c1 != ' ' }.size

      if (indent == null)  indent = -(i+1).max(n+1)
      else if (indent < 0) indent = -(i+1).max(-indent)

      indPos := indent < 0 ? -indent - 1 : indent
      if (i < indPos && next != null && next != '\n')
      {
        if ((next == '#' && indent >= 0) || i < n) break
        else throw err("Text cannot be indented less than $indPos spaces in this literal block.")
      }

      // l-empty(n,BLOCK-IN)*
      if ((indent < 0 || i <= indent) && (next == null || next == '\n'))
        r.eatLine(r.ws)

      else
      {
        if (indent < 0) indent = indPos
        r.eatInd(indent)

        // [175] s-nb-folded-text(n)
        if (!r.isWs(r.peek))
        {
          if (inFolded && s.size > 0 && s[-1] == '\n')
          {
            s.remove(-1)
            if (s.size > 0 && s[-1] != '\n') s.addChar(' ')
          }
          inFolded = true
        }
        // [177] s-nb-spaced-text(n)
        else inFolded = false

        s.add(r.eatLine)
      }

      s.addChar('\n')
      if (r.peek(r.docPrefix) == null) break
    }

    sLComments

    if (chomp == "strip")
      while (!s.isEmpty && s[-1] == '\n') s.remove(-1)
    else if (chomp == "clip")
    {
      while (s.size > 1 && s[-1] == '\n' && s[-2] == '\n') s.remove(-1)
      if (s.size == 1 && s[0] == '\n') s.remove(0)
    }

    return YamlScalar(s.toStr, tag == "" ? "!" : tag, startLoc)
  }

  ** [162] c-b-block-header(t)
  private [Str:Obj] parseBlockHeader(Int n)
  {
    res := [:]

    r.eatToken(null, r.blockStyle).chars.each |c1|
    {
      if (c1 == '+' || c1 == '-')
      {
        if (res.containsKey("chomp"))
          throw err("The chomping indicator cannot be specified twice.")
        res["chomp"] = c1 == '+' ? "keep" : "strip"
      }
      else
      {
        if (res.containsKey("indent"))
          throw err("The indentation indicator cannot be specified twice or with multiple digits.")
        res["indent"] = n + c1.fromDigit - 1
      }
    }
    r.eatCommentLine("A block style header")

    if (!res.containsKey("chomp"))
      res["chomp"] = "clip"

    return res
  }

  ** [120] c-single-quoted(n,c)
  private YamlScalar parseSingleQuote(Int n, Context ctx, Str tag, FileLoc? loc)
  {
    Int? c
    s := StrBuf()
    initLoc := r.loc
    endFound := false

    r.eatChar('\'')

    // [122] nb-single-one-line
    // [123] nb-ns-single-in-line
    readSingleLine := |->|
    {
      while (r.peekNextNs(r.str) != '\n' && (c = r.str()()) != null)
      {
        if (c == '\'')
        {
          if (r.peek(r.any) == '\'') c = r.str()()
          else { endFound = true; break }
        }
        s.addChar(c)
      }
    }

    readSingleLine()

    if (ctx == Context.flowOut || ctx == Context.flowIn)
    {
      // [124] s-single-next-line(n)
      while (!endFound && r.peekNextNs(r.str) == '\n' && !r.nextTokenEndsDoc)
      {
        r.eatLine(r.ws)

        if (r.peekNextNs(r.str) == '\n')
          while (r.peekNextNs(r.str) == '\n')
          {
            s.addChar('\n')
            r.eatLine(r.ws)
          }

        else s.addChar(' ')

        r.eatInd(n)
        r.eatWs
        readSingleLine()
      }
    }

    if (c != '\'')
      throw err("Ending ' not found.", initLoc)

    // Error if comment directly adjacent
    if (r.peek == '#')
      throw err("Comments must be preceded by whitespace.")

    return YamlScalar(s.toStr, tag == "" ? "!" : tag, loc ?: initLoc)
  }

  ** [109] c-double-quoted(n,c)
  private YamlScalar parseDoubleQuote(Int n, Context ctx, Str tag, FileLoc? loc)
  {
    Int? c
    s := StrBuf()
    initLoc := r.loc
    endFound := false

    r.eatChar('"')

    // [111] nb-double-one-line
    // [114] nb-ns-double-in-line
    readDoubleLine := |->|
    {
      while (r.peekNextNs(r.str) != '\n' && (c = r.str()()) != null)
      {
        if (c == '"') { endFound = true; break }
        else if (c == '\\')
          switch (c = r.str()())
          {
            // Basic character substitution
            case '0':   s.addChar(0x00)
            case 'a':   s.addChar(0x07)
            case 'b':   s.addChar(0x08)
            case 't':   s.addChar(0x09)
            case 0x09:  s.addChar(0x09)
            case 'n':   s.addChar(0x0A)
            case 'v':   s.addChar(0x0B)
            case 'f':   s.addChar(0x0C)
            case 'r':   s.addChar(0x0D)
            case 'e':   s.addChar(0x1B)
            case 0x20:  s.addChar(0x20)
            case '"':   s.addChar(0x22)
            case '/':   s.addChar(0x2F)
            case '\\':  s.addChar(0x5C)
            case 'N':   s.addChar(0x85)
            case '_':   s.addChar(0xA0)
            case 'L':   s.addChar(0x2028)
            case 'P':   s.addChar(0x2029)

            // Arbitrary unicode character insertion
            case 'x':   digs := [,]
                        2.times |_| { digs.add(r.hex()()) }
                        s.addChar(Int.fromStr(Str.fromChars(digs), 16))
            case 'u':   digs := [,]
                        4.times |_| { digs.add(r.hex()()) }
                        s.addChar(Int.fromStr(Str.fromChars(digs), 16))
            case 'U':   digs := [,]
                        8.times |_| { digs.add(r.hex()()) }
                        s.addChar(Int.fromStr(Str.fromChars(digs), 16))

            // Escaped newline
            case '\n':  if (ctx == Context.flowOut || ctx == Context.flowIn)
                        {
                          if (r.peekNextNs(r.str) != '\n') r.eatInd(n)
                          r.eatWs
                        }
                        else throw err("Ending \" not found.", initLoc)

            case null:  throw err("Ending \" not found.", initLoc)
            default:    throw err("\"\\$c.toChar\" is not a valid escape sequence.")
          }
        else s.addChar(c)
      }
    }

    readDoubleLine()

    if (ctx == Context.flowOut || ctx == Context.flowIn)
    {
      // [115] s-double-next-line(n)
      while (!endFound && r.peekNextNs(r.str) == '\n' && !r.nextTokenEndsDoc)
      {
        r.eatLine(r.ws)

        if (r.peekNextNs(r.str) == '\n')
          while (r.peekNextNs(r.str) == '\n')
          {
            s.addChar('\n')
            r.eatLine(r.ws)
          }

        else if (r.peekNextNs(r.str) == null)
          throw err("Ending \" not found.", initLoc)

        else  s.addChar(' ')

        r.eatInd(n)
        r.eatWs
        readDoubleLine()
      }
    }

    if (c != '"')
      throw err("Ending \" not found.", initLoc)

    // Error if comment directly adjacent
    if (r.peek == '#')
      throw err("Comments must be preceded by whitespace.")

    return YamlScalar(s.toStr, tag == "" ? "!" : tag, loc ?: initLoc)
  }

  ** [137] c-flow-sequence(n,c)
  private YamlList parseFlowSeq(Int n, Context ctx, Str tag, FileLoc? loc)
  {
    YamlObj[] res := [,]
    if (ctx == Context.flowOut)  ctx = Context.flowIn
    if (ctx == Context.blockKey) ctx = Context.flowKey
    startLoc := loc ?: r.loc

    r.eatChar('[')

    separate(n,ctx)
    while (r.peek != null && r.peek != ']' && !r.nextTokenEndsDoc)
    {
      res.add(parseFlowSeqEntry(n,ctx))
      separate(n,ctx)
      if (r.peek == ',')
      {
        r.eatChar(',')
        if (r.peek == '#')
          throw err("Comments must be preceded by whitespace.")
        separate(n,ctx)
      }
      else break
    }

    r.eatChar(']')

    // Error if comment directly adjacent
    if (r.peek == '#')
      throw err("Comments must be preceded by whitespace.")

    return YamlList(res, tag, startLoc)
  }

  ** [139] ns-flow-seq-entry(n,c)
  private YamlObj parseFlowSeqEntry(Int n, Context ctx)
  {
    // [143] ns-flow-map-explicit-entry(n,c)
    if (r.peekToken == "?")
    {
      startLoc := r.loc
      entry := parseFlowMapEntry(n,ctx)
      return YamlMap(YamlObj:YamlObj[entry["key"]:entry["val"]], startLoc)
    }

    // [151] ns-flow-pair-entry(n,c)
    else if (nextNodeIsKey(n,ctx))
    {
      YamlObj key := YamlScalar("", r.loc)

      // non-empty key
      if (r.peek != ':')
        key = parseFlowNode(n, Context.flowKey)

      r.eatWs
      r.eatChar(':')
      separate(n,ctx)

      YamlObj val := YamlScalar("", r.loc)

      // non-empty entry
      if (![']', ',', null].contains(r.peek))
        val = parseFlowNode(n,ctx)

      return YamlMap(YamlObj:YamlObj[key:val], key.loc)
    }

    return parseFlowNode(n,ctx)
  }

  ** [140] c-flow-mapping(n,c)
  private YamlMap parseFlowMap(Int n, Context ctx, Str tag, FileLoc? loc)
  {
    res := YamlObj:YamlObj[:]
    if (ctx == Context.flowOut)  ctx = Context.flowIn
    if (ctx == Context.blockKey) ctx = Context.flowKey
    startLoc := loc ?: r.loc

    r.eatChar('{')

    separate(n,ctx)
    while (r.peek != null && r.peek != '}' && !r.nextTokenEndsDoc)
    {
      entry := parseFlowMapEntry(n,ctx)
      res.add(entry["key"].toImmutable, entry["val"])
      separate(n,ctx)
      if (r.peek == ',')
      {
        r.eatChar(',')
        if (r.peek == '#')
          throw err("Comments must be preceded by whitespace.")
        separate(n,ctx)
      }
      else break
    }

    r.eatChar('}')

    // Error if comment directly adjacent
    if (r.peek == '#')
      throw err("Comments must be preceded by whitespace.")

    return YamlMap(res, tag, startLoc)
  }

  ** [142] ns-flow-map-entry(n,c)
  private [Str:YamlObj] parseFlowMapEntry(Int n, Context ctx)
  {
    YamlObj key := YamlScalar("", r.loc)
    YamlObj val := YamlScalar("", r.loc)
    keyIsJson   := r.nextKeyIsJson

    // [143] ns-flow-map-explicit-entry(n,c)
    if (r.peekToken == "?")
    {
      r.eatToken("?")
      separate(n,ctx)

      if (r.isFlowEnd(r.peek))
        return ["key": key, "val": val]
    }

    // [144] ns-flow-map-implicit-entry(n,c)

    // reset location
    key = YamlScalar("", r.loc)

    // non-empty key
    emptyKey := r.peekUntil |c1| { !r.isNs(c1) || r.isFlow(c1) } == ":"
    if (!emptyKey)
      key = parseFlowNode(n,ctx)

    separate(n,ctx)
    val = YamlScalar("", r.loc)

    // indicated entry
    if (r.peek == ':')
    {
      r.eatChar(':')
      if (!r.isFlowEnd(r.peek) && r.isNs(r.peek) && !keyIsJson)
        throw err("The character '${r.peek?.toChar}' cannot immediately follow a : indicating a mapping. " +
                  "Try putting a space between the : and ${r.peek?.toChar}.")

      separate(n,ctx)

      // non-empty entry
      if (!r.isFlowEnd(r.peek))
        val = parseFlowNode(n,ctx)
    }
    else if (emptyKey)
      throw err("A map entry cannot be completely empty here.")

    return ["key": key, "val": val]
  }

  ** [183] l+block-sequence(n)
  private YamlList parseBlockSeq(Int n, Str tag, FileLoc? loc)
  {
    startLoc := loc

    m := (r.peekUntil |c1| { c1 != ' ' }).size
    if (m <= n) throw err("Your list must be indented by at least ${n+1} spaces, not just ${m}.")

    YamlObj[] res := [,]
    while (r.peekUntil |c1| { c1 != ' ' }.size == m &&
           r.peekPast  |c1| { r.isWs(c1) } == '-' &&
           !r.nextTokenEndsDoc)
    {
      r.eatInd(m)
      if (startLoc == null)
        startLoc = r.loc
      res.add(parseBlockSeqEntry(m))
    }

    return YamlList(res, tag, startLoc)
  }

  ** [184] c-l-block-seq-entry(n)
  private YamlObj parseBlockSeqEntry(Int n)
  {
    r.eatChar('-')
    if (r.isNs(r.peek)) throw err("The - in your list cannot be followed by the non-whitespace character '${r.peek?.toChar}'.")

    return parseBlockIndented(n, Context.blockIn)
  }

  ** [187] l+block-mapping(n)
  private YamlMap parseBlockMap(Int n, Str tag, FileLoc? loc)
  {
    startLoc := loc

    m := (r.peekUntil |c1| { c1 != ' ' }).size
    if (m <= n) throw err("Your list must be indented by at least ${n+1} spaces, not just ${m}.")

    res := YamlObj:YamlObj[:]
    res.ordered = true
    while (r.peekUntil |c1| { c1 != ' ' }.size == m &&
           r.isNs(r.peekPast |c1| { c1 == ' ' }) &&
           (r.peekNextNs == '?' ||
            nextNodeIsKey(m, Context.blockIn)) &&
           !r.nextTokenEndsDoc)
    {
      r.eatInd(m)
      if (startLoc == null)
        startLoc = r.loc
      entry := parseBlockMapEntry(m)
      res.add(entry["key"], entry["val"])
    }

    return YamlMap(res, tag, startLoc)
  }

  ** [188] ns-l-block-map-entry(n)
  private [Str:YamlObj] parseBlockMapEntry(Int n)
  {
    res := [:]

    // [189] c-l-block-map-explicit-entry(n)
    if (r.peekToken == "?")
    {
      r.eatToken("?")
      res["key"] = parseBlockIndented(n, Context.blockOut)

      // [191] l-block-map-explicit-value(n)
      if (r.peekUntil |c1| { c1 != ' ' }.size == n &&
          r.peekPast  |c1| { c1 == ' ' } == ':')
      {
        r.eatInd(n)
        r.eatChar(':')
        if (r.isNs(r.peek))
          throw err("The : in your mapping cannot be followed by the non-whitespace character '${r.peek}'.")
        res["val"] = parseBlockIndented(n, Context.blockOut)
      }
      // empty value
      else res["val"] = YamlScalar("", r.loc)
    }

    // [192] ns-l-block-map-implicit-entry(n)
    else
    {
      if (!nextNodeIsKey(n, Context.blockKey))
        throw err("This node is not a implicit key. " +
                  "Make sure it is not too long (>1024 characters) and only spans a single line, or " +
                  "consider making it an explicit key instead.")
      r.eatWs
      if (r.peekToken == ":") res["key"] = YamlScalar("", r.loc)
      else res["key"] = parseFlowNode(0, Context.blockKey)
      r.eatWs
      r.eatChar(':')

      // empty value
      if (r.nextTokenEndsDoc ||
          (r.peekIndentedNs(n+1, r.docPrefix) == null &&
           r.peekIndentedToken(n, r.docPrefix) != "-"))
      {
        res["val"] = YamlScalar("", r.loc)
        sLComments
      }
      // error if value is compact map
      else if ((r.peekNextNs != '#' && r.peekNextNs != '\n' && nextNodeIsKey(n+1, Context.blockKey)) ||
               r.peekToken == "?")
        throw err("A map embedded in a mapping cannot start on the same line as its corresponding key.")
      // inhabited value
      else res["val"] = parseBlockNode(n, Context.blockOut)
    }

    return res
  }

  ** [185] s-l+block-indented(n,c)
  private YamlObj parseBlockIndented(Int n, Context ctx)
  {
    // [186] ns-l-compact-sequence(n)
    if (r.peekPast |c1| { c1 == ' ' } == '-' &&
        r.peekIndentedToken(0) == "-")
    {
      m := r.eatUntil |c1| { c1 != ' ' }.size

      YamlObj[] res := [,]
      startLoc := r.loc
      res.add(parseBlockSeqEntry(n+1+m))
      while (r.peekUntil |c1| { c1 != ' ' }.size == n+1+m &&
             r.peekPast  |c1| { c1 == ' ' } == '-')
      {
        r.eatInd(n+1+m)
        res.add(parseBlockSeqEntry(n+1+m))
      }

      return YamlList(res, startLoc)
    }

    // [195] ns-l-compact-mapping(n)
    else if (r.isNs(r.peekPast |c1| { c1 == ' ' }) &&
             (r.peekIndentedToken(0) == "?" ||
              nextNodeIsKey(n,ctx)))
    {
      m := r.eatUntil |c1| { c1 != ' ' }.size

      res := YamlObj:YamlObj[:]
      startLoc := r.loc
      entry := parseBlockMapEntry(n+1+m)
      res.add(entry["key"], entry["val"])
      while (r.peekUntil |c1| { c1 != ' ' }.size == n+1+m &&
             r.isNs(r.peekPast |c1| { c1 == ' ' }))
      {
        r.eatInd(n+1+m)
        entry = parseBlockMapEntry(n+1+m)
        res.add(entry["key"], entry["val"])
      }

      return YamlMap(res, startLoc)
    }

    // Empty node
    else if (r.peekIndentedNs(n+1, r.docPrefix) == null &&
            !(ctx == Context.blockOut && r.peekIndentedToken(n, r.docPrefix) == "-"))
    {
      startLoc := r.loc
      sLComments
      return YamlScalar("", startLoc)
    }

    // Regular block node
    else return parseBlockNode(n,ctx)
  }

  ** [131] ns-plain(n,c)
  private YamlScalar parsePlain(Int n, Context ctx, Str tag, FileLoc? loc)
  {
    s := StrBuf()
    startLoc := loc ?: r.loc

    // [133] ns-plain-one-line(c)
    c := r.firstChar(ctx)()
    s.addChar(c)               // add first character (cannot be an indicator)
    s.add(plainInLine(ctx))    // add all other applicable characters in the line

    if (ctx == Context.flowOut || ctx == Context.flowIn)
    {
      while(r.peekNextNs != '#' &&
            r.peekIndentedNs(n, r.docPrefix) != null &&
            !r.nextTokenEndsDoc &&
            r.peekUntil |c1| { !r.isNs(c1) || (ctx == Context.flowIn && r.isFlow(c1) ) } != ":" &&
            (ctx == Context.flowIn ? !r.isFlow(r.peek) : true))
      {
        // [134] s-ns-plain-next-line(n,c)
        r.eatLine(r.ws)
        if (r.peekNextNs != '\n')
          s.addChar(' ')
        else while (r.peekNextNs == '\n')
        {
          s.addChar('\n')
          r.eatLine(r.ws)
        }
        r.eatWs
        s.add(plainInLine(ctx))
      }
    }

    return YamlScalar(s.toStr.trim, tag, startLoc)
  }

  ** Eats the plain scalar from the current position to some other
  ** point within the line (dependent on context).
  **
  ** [130] ns-plain-char(c)
  ** [132] nb-ns-plain-in-line(c)
  private Str plainInLine(Context ctx)
  {
    if (r.peek == '#') return ""

    s := r.eatUntil |c1|
    {
      r.isNl(c1) || //newline
      (r.isWs(c1) && r.peekNextNs == '#') || //WS before comment
      (c1 == ':' && !r.isNs(r.peek)) || // ": "
      ((ctx == Context.flowIn || ctx == Context.flowKey)
      ?
        r.isFlow(c1) ||                  //flow indicator, if applicable
        (c1 == ':' && r.isFlow(r.peek))  //or : followed by flow indicator
      :
        false)
    }.trimEnd
    r.eatWs
    return s
  }

  ** Eat the extra whitespace/empty lines/comment lines between the
  ** current position and the upcoming node, ensuring that the
  ** indentation is respected.
  **
  ** [80] s-separate(n,c)
  private Void separate(Int n, Context ctx)
  {
    if (ctx == Context.blockKey || ctx == Context.flowKey || !(['#', '\n'] as Int?[]).contains(r.peekNextNs)) r.eatWs
    else
    {
      sLComments
      r.eatInd(n)
      r.eatWs
    }
  }

  ** [79] s-l-comments
  private Void sLComments(|->Int?| readRule := r.printable)
  {
    if (r.loc.col != 1) r.eatCommentLine
    while ((['#','\n'] as Int?[]).contains(r.peekNextNs(readRule))) r.eatLine(readRule)
  }

  ** Parse the end of a document, consisting of the document suffix '...'
  ** and optionally a line-ending comment. Then, start parsing the next
  ** document, if it exists in the stream.
  **
  ** [204] c-document-end
  private Void parseDocEnd()
  {
    assertLineStart
    r.eatStr("...")
    r.eatCommentLine("Document suffixes")
    parseDocument
  }

//////////////////////////////////////////////////////////////////////////
// Helper methods
//////////////////////////////////////////////////////////////////////////

  ** Error with line & col info
  private Err err(Str msg, FileLoc? loc := null)
  {
    if (loc == null) loc = r.loc
    return FileLocErr(msg, loc)
  }

  ** Assert that the stream is at the beginning of a line (or the end of
  ** the stream).
  private Void assertLineStart()
  {
    if (r.loc.col != 1 && r.peek(r.any) != null)
      throw err("Internal parser error: The parser should have been at the beginning of the line here.")
  }

  ** Assert that the stream is not followed by ": " ('keyIsJson' false) or
  ** ":" ('keyIsJson' true), erroring appropriately if not.
  ** Then, eats a sLComment block and returns 'ret'.
  private YamlObj objSLComments(Int startLine, Bool keyIsJson, YamlObj ret)
  {
    // Error if followed by :
    r.eatWs
    if (r.peekToken == ":")
    {
      msg := ret.toStr.trim
      if (r.loc.line != startLine)
      {
        if (msg.containsChar('\n')) throw err("The key \n$msg\n spans multiple lines.")
        else                        throw err("The key '$msg' spans multiple lines.")
      }
      else                          throw err("Plain scalars cannot contain \": \".")
    }

    // sLComments
    sLComments

    return ret
  }

  ** Returns whether or not the next node in the stream (skipping over a
  ** separate(n) block) is an implicit key for a mapping.
  private Bool nextNodeIsKey(Int n, Context ctx)
  {
    str := r.nextKeyStr(n).split('\n')[0]

    // Replace last : with char that can't be interpreted as a mapping :
    if (str.getSafe(1025) == ':')
      str = str[0..1024] + 'a'

    return YamlParser(str.in, r.loc).startsWithKey(tagShorthands, anchors, ctx)
  }

  ** Returns whether or not the stream can be interpreted as an implicit key,
  ** assuming this parser is a secondary parser with input length <= 1026.
  internal Bool startsWithKey([Str:Str] tagShorthands, [Str:YamlObj] anchors, Context ctx)
  {
    this.tagShorthands = tagShorthands
    this.anchors = anchors
    try
    {
      // Empty key
      if (r.peekUntil |c1|
          {
            !r.isNs(c1) ||
            (ctx == Context.flowIn && r.isFlowEnd(c1))
          } == ":")
        return true

      // Non-empty key
      f := parseFlowNode(0, ctx.isFlow ? Context.flowKey : Context.blockKey)
      r.eatWs
      r.eatChar(':')
      return !r.isNs(r.peek) || (ctx.isFlow && f.tag != "?")
    }
    catch (FileLocErr e)
    {
      return false
    }
  }

  ** Returns a copy of the given YamlObj with the location set to 'loc'.
  private YamlObj setLoc(YamlObj obj, FileLoc loc)
  {
    return Type.of(obj).make(
      [obj.val,
       obj.tag,
       loc]
    )
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private YamlTokenizer r
  private YamlObj[] docs := [,]

  //Document-based / should be cleared between documents
  private [Str:Str] tagShorthands := [:]
  private [Str:YamlObj] anchors  := [:]
  private Str[] anchorsInProgress := [,]

}

internal enum class Context
{
  blockIn,  // block node that does not allow using -/?/: as part of indentation
  blockOut, // block node that allows using -/?/: as part of indentation
  flowIn,   // flow node contained within a flow node (so flow indicators end the node)
  flowOut,  // flow node contained within a block node (so flow indicators don't end the node)
  blockKey, // block key
  flowKey   // flow key

  Bool isFlow() { this == flowIn || this == flowOut || this == flowKey }
}
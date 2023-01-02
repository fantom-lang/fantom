#! /usr/bin/env fan
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    7 Jul 2022  Kiera O'Flynn   Creation
//

using util

**************************************************************************
** YamlTokenizer
**************************************************************************

internal class YamlTokenizer
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(InStream in, FileLoc loc := FileLoc.unknown)
  {
    this.in = in
    this.loc = FileLoc(loc.file, 1, 1)

    deduceEncoding
  }

//////////////////////////////////////////////////////////////////////////
// General reading helper methods
//////////////////////////////////////////////////////////////////////////

  ** Returns the next character without reading any characters.
  Int? peek(|->Int?| readRule := printable)
  {
    initLoc := loc
    c := readRule()
    if (c != null)
    {
      unread(c)
      loc = initLoc
    }
    return c
  }

  ** Eats the next character, erroring if it is not the expected character.
  Void eatChar(Int expected)
  {
    c := read
    if (c != expected)
      throw err("'$expected.toChar' expected, but \'${c?.toChar}\' found instead.")
  }

  ** Eats the next few characters, erroring if they do not match the given string exactly.
  Void eatStr(Str expected)
  {
    s := StrBuf(expected.size)
    Int? c
    for(i := 0; i < expected.size && (c = read) != null; i++) s.addChar(c)
    if (s.toStr != expected)
      throw err("\"$expected\" expected, but \"$s.toStr\" found instead.")
  }

  ** Reads the characters to the first whitespace/newline/EOF character
  ** encountered, using the given rule to check characters.
  ** Does not consume the ending character, nor does the rule have to accept it.
  ** (As a tradeoff, you should not use the rule to skip over the ending character.)
  Str eatToken(Str? expected := null, |->Int?| readRule := printable)
  {
    s := eatUntilr(readRule) |c| { !isNs(c) }

    if (expected != null && s != expected)
      throw err("\"$expected\" expected, but \"$s\" found instead.")
    return s
  }

  ** Same as eatToken, but does not consume any characters.
  ** The rule does not have to accept the ending character.
  Str peekToken(|->Int?| readRule := printable)
  {
    peekUntilr(readRule) |c| { !isNs(c) }
  }

  ** Same as eatToken, except instead of stopping at whitespace, it
  ** stops when the given formula returns true on a character or
  ** the stream ends. Does not consume the ending character, nor does
  ** the rule have to accept it.
  Str eatUntilr(|->Int?| readRule, |Int->Bool| endRule)
  {
    s := StrBuf()
    Int? c
    lastLoc := loc
    while(true)
    {
      if (peek(any) == null || endRule(peek(any))) break
      else if ((c = readRule()) == null) break
      else if (endRule(c))
      {
        unread(c)
        loc = lastLoc
        break
      }
      s.addChar(c)
      lastLoc = loc
    }
    return s.toStr
  }

  ** Convenience for eatUntilr(printable, endRule).
  Str eatUntil(|Int->Bool| endRule) { eatUntilr(printable, endRule) }

  ** Same as eatToken, except does not consume any characters.
  Str peekUntilr(|->Int?| readRule, |Int->Bool| endRule)
  {
    s := StrBuf()
    Int[] buf := [,]
    Int? c
    initLoc := loc
    while(true)
    {
      if (peek(any) == null || endRule(peek(any))) break
      else if ((c = readRule()) == null) break
      buf.add(c)
      if (endRule(c)) break
      s.addChar(c)
    }
    unreadAll(buf)
    loc = initLoc
    return s.toStr
  }

  ** Convenience for peekUntilr(printable, endRule)
  Str peekUntil(|Int->Bool| endRule) { peekUntilr(printable, endRule) }

  ** Reads the characters to the first newline/EOF character encountered,
  ** using the given rule to check characters. Consumes the newline at the end.
  ** The rule does not have to accept the newline.
  Str eatLine(|->Int?| readRule := printable)
  {
    s := eatUntilr(readRule) |c| { isNl(c) }
    if (peek == '\n') read
    return s
  }

  ** Eats the whitespace between the current position and the next
  ** non-space character.
  Void eatWs()
  {
    while(isWs(peek(any))) { read }
  }

  ** Returns the next non-space character without reading any characters.
  Int? peekNextNs(|->Int?| readRule := printable)
  {
    peekPastr(readRule) |c| { isWs(c) }
  }

  ** Returns the next character for which contRule returns false
  ** without reading any characters.
  Int? peekPastr(|->Int?| readRule, |Int->Bool| contRule)
  {
    Int[] buf := [,]
    Int? c
    initLoc := loc
    while ((c = readRule()) != null && contRule(c)) buf.add(c)
    if (c != null) buf.add(c)
    unreadAll(buf)
    loc = initLoc
    return c
  }

  ** Convenience for peekPastr(printable, contRule)
  Int? peekPast(|Int->Bool| contRule) { peekPastr(printable, contRule) }

//////////////////////////////////////////////////////////////////////////
// Specialized reading helper methods
//////////////////////////////////////////////////////////////////////////

  Void eatCommentLine(Str loc := "This")
  {
    eatWs
    if (!['#', '\n', null].contains(peek))
      throw err("$loc cannot be followed on the same line by content.")
    eatLine
  }

  ** Eats 'n' spaces of indentation, erroring appropriately if not found.
  Void eatInd(Int n)
  {
    for(i := 0; i < n; i++)
      if (read != ' ')
        throw err("This line is indented by $i spaces when $n spaces were expected.")
  }

  ** Peeks forward through a separate(n) block and finds the
  ** next token. Then, it peeks 1026 characters forward in the
  ** line (returning a string made from it), which can be used
  ** to detect whether the next block is an implicit key or not.
  Str nextKeyStr(Int n)
  {
    Int[] buf := [,]
    Int? c
    initLoc := loc

    // Peek through whitespace
    inComment := false
    spacesToGo := loc.col == 1 ? n : 0
    while ((c = peek(docPrefix)) != null && (c == '#' || inComment || isWs(c) || isNl(c)))
    {
      c = read
      buf.add(c)
      if (!inComment && c == '#')
      {
        inComment = true
        spacesToGo = 0
      }
      else if (isNl(c))
      {
        inComment = false
        spacesToGo = n
      }
      else if (spacesToGo > 0)
      {
        if (c == ' ') spacesToGo--
        else if (['#', '\n', null].contains(peekNextNs)) spacesToGo = 0
        else { c = null; break }
      }
    }

    res := [,]

    // Peek line
    if (c != null && spacesToGo <= 0)
    {
      setPeek(1026)
      res = peekArr[0..<1026.min(peekArr.size)]
    }

    unreadAll(buf)
    loc = initLoc
    return Str.fromChars(res)
  }

  ** Assumes the next block constitutes a valid key in a flow mapping.
  ** True if said key is "JSON-like".
  Bool nextKeyIsJson()
  {
    Int[] buf := [,]
    Int? c
    initLoc := loc

    res := false
    while (res == false)
    {
      c = read
      if (c == null) break
      buf.add(c)

      // Skip whitespace
      if (isWs(c)) continue

      // Empty key
      else if (isFlowEnd(c) || (c == ':' && (!isNs(peek) || isFlowEnd(peek)))) break

      // JSON-like key
      else if (['{','[','\'','"'].contains(c)) res = true

      // Property
      else if (['&','!'].contains(c))
      {
        // skip whole property
        while (isNs(c = peek) && ![']', '}', ',', null].contains(c))
        {
          c = read
          if (c == null) break
          buf.add(c)
        }
      }

      // Normal YAML key
      else break
    }

    unreadAll(buf)
    loc = initLoc
    return res
  }

  ** Returns the next non-space character, ignoring comments and newlines,
  ** without reading any characters. If a non-NL, non-comment character is
  ** reached on a new line that is not at least indented by 'n' spaces,
  ** null is returned.
  Int? peekIndentedNs(Int n, |->Int?| readRule := printable)
  {
    Int[] buf := [,]
    Int? c
    initLoc := loc

    // Peek through WS
    inComment := false
    spacesToGo := loc.col == 1 ? n : 0
    while ((c = readRule()) != null && (c == '#' || inComment || isWs(c) || isNl(c)))
    {
      buf.add(c)
      if (!inComment && c == '#')
      {
        inComment = true
        spacesToGo = 0
      }
      else if (isNl(c))
      {
        inComment = false
        spacesToGo = n
      }
      else if (spacesToGo > 0)
      {
        if (c == ' ') spacesToGo--
        else if (['#', '\n', null].contains(peekNextNs)) spacesToGo = 0
        else { c = null; break }
      }
    }
    if (c != null) buf.add(c)

    unreadAll(buf)
    loc = initLoc
    return spacesToGo <= 0 ? c : null
  }

  ** Same as peekIndentedNs, but returns the next whole token (as in peekToken).
  Str? peekIndentedToken(Int n, |->Int?| readRule := printable)
  {
    peekIndentedUntilr(n, readRule) |c1| { !isNs(c1) }
  }

  ** Same as peekIndentedNs, but returns the next whole string until the
  ** end condition is satisfied (as in peekUntil).
  Str? peekIndentedUntilr(Int n, |->Int?| readRule, |Int->Bool| endRule)
  {
    Int[] buf := [,]
    Int? c
    s := StrBuf()
    initLoc := loc

    // Peek through whitespace
    inComment := false
    spacesToGo := loc.col == 1 ? n : 0
    while ((c = readRule()) != null && (c == '#' || inComment || isWs(c) || isNl(c)))
    {
      buf.add(c)
      if (!inComment && c == '#')
      {
        inComment = true
        spacesToGo = 0
      }
      else if (isNl(c))
      {
        inComment = false
        spacesToGo = n
      }
      else if (spacesToGo > 0)
      {
        if (c == ' ') spacesToGo--
        else if (['#', '\n', null].contains(peekNextNs)) spacesToGo = 0
        else { c = null; break }
      }
    }

    if (c != null && spacesToGo > 0) buf.add(c)

    // Peek token
    while(c != null && spacesToGo <= 0)
    {
      buf.add(c)
      s.addChar(c)
      c = readRule()
      if (c != null && endRule(c)) { buf.add(c); break }
    }

    unreadAll(buf)
    loc = initLoc
    return s.size > 0 ? s.toStr : null
  }

  ** Convenience for peekIndentedUntilr(n, printable, endRule)
  Str? peekIndentedUntil(Int n, |Int->Bool| endRule) { peekIndentedUntilr(n, printable, endRule) }

  ** True if the next token (as in peekIndentedToken(docPrefix, 0)) is a token
  ** that ends a document (i.e. "..." or "---").
  Bool nextTokenEndsDoc()
  {
    Int[] buf := [,]
    Int? c
    initLoc := loc

    // Peek through whitespace
    inComment := false
    while ((c = docPrefix()()) != null && (c == '#' || inComment || isWs(c) || isNl(c)))
    {
      buf.add(c)
      if (!inComment && c == '#') inComment = true
      else if (isNl(c)) inComment = false
    }

    res := false

    // Peek token
    if (c != null)
    {
      buf.add(c)
      setPeek(3)
      if (peekArr.size >= 2 && loc.col - 1 == 1)
      {
        tok3 := "${c.toChar}${peekArr[0].toChar}${peekArr[1].toChar}"
        res = ["---", "..."].contains(tok3) && !isNs(peekArr.getSafe(2))
      }
    }

    unreadAll(buf)
    loc = initLoc
    return res
  }

//////////////////////////////////////////////////////////////////////////
// Char read rules
//////////////////////////////////////////////////////////////////////////

  /* The way this section works is that each method provides a 'rule' for
   * charset checking, typically reading in a character, making sure it
   * is allowed according to the rule (erroring if not), and returning the
   * read character. Then, they can either be used on their own to read
   * individual characters from the stream or in the methods above as
   * described.
   *
   * A rule may either be associated with a general rule (e.g. 'printable')
   * or a specific section/node type of a document (e.g. 'docPrefix'). */

  once |->Int?| docPrefix()
  {
    |->Int?|
    {
      c := read
      if (c == 0xFFFE && loc.col - 1 == 1) { decCol; return docPrefix()() }
      else if (!isPrintable(c)) throw charsetErr(c)
      return c
    }
  }

  ** [38] ns-word-char
  once |->Int?| tagHandle()
  {
    |->Int?|
    {
      c := read
      if (!isWordChar(c))
        throw charsetErr(c, "in a tag handle")
      return c
    }
  }

  ** [40] ns-tag-char
  once |->Int?| tagSuffix()
  {
    |->Int?|
    {
      c := read
      if (!isUriChar(c) || isFlow(c) || c == '!')
        throw charsetErr(c, "in a tag suffix")
      if (c == '%')
      {
        setPeek(2)
        if (peekArr.size < 2 || !isHexChar(peekArr[0]) || !isHexChar(peekArr[1]))
          throw err("The % sign is not followed by two hex digits.")
      }
      return c
    }
  }

  ** [39] ns-uri-char
  once |->Int?| uri()
  {
    |->Int?|
    {
      c := read
      if (!isUriChar(c))
        throw charsetErr(c, "in URI strings")
      if (c == '%')
      {
        setPeek(2)
        if (peekArr.size < 2 || !isHexChar(peekArr[0]) || !isHexChar(peekArr[1]))
          throw err("The % sign is not followed by two hex digits.")
      }
      return c
    }
  }

  ** Matches the first character of a plain scalar
  ** [126] ns-plain-first(c)
  |->Int?| firstChar(Context ctx)
  {
    |->Int?|
    {
      c := read
      if (c == null || !isPrintable(c))
        throw charsetErr(c)
      if (['?', ':', '-'].contains(c))
      {
        setPeek(1)
        if (!isNs(peekArr.getSafe(0)))
          throw err("A plain scalar cannot begin with \"$c.toChar \".")
        else if ((ctx == Context.flowIn || ctx == Context.flowKey) &&
                 isFlow(peekArr.getSafe(0)))
          throw err("A plain scalar cannot consist of '-' alone.")
      }
      else if (isIndicator(c))
        throw charsetErr(c, "to be the first character of a plain scalar")
      return c
    }
  }

  ** [163] c-indentation-indicator
  ** [164] c-chomping-indicator(t)
  once |->Int?| blockStyle()
  {
    |->Int?|
    {
      c := read
      if (c == null)
        throw charsetErr(c)
      if (c != '-' && c != '+' && !('1' <= c && c <= '9'))
        throw charsetErr(c, "in a block style header")
      return c
    }
  }

  ** Matches characters that are allowed in quoted strings
  ** [2] nb-json
  once |->Int?| str()
  {
    |->Int?|
    {
      c := read
      if (c != null && c < 0x20 && !isPrintable(c))
        throw charsetErr(c)
      return c
    }
  }

  ** [36] ns-hex-digit
  once |->Int?| hex()
  {
    |->Int?|
    {
      c := read
      if (!isHexChar(c))
        throw err("The character '$c.toChar' is not a hexadecimal digit.")
      return c
    }
  }

  ** [33] s-white
  once |->Int?| ws()
  {
    |->Int?|
    {
      c := read
      if (!isWs(c))
        throw charsetErr(c, "in this whitespace-only area")
      return c
    }
  }

  ** [1] c-printable
  once |->Int?| printable()
  {
    |->Int?|
    {
      c := read
      if (!isPrintable(c))
        throw charsetErr(c)
      return c
    }
  }

  // Should only be used for detecting byte order marks/
  // peeking characters with guarantee of no error
  once |->Int?| any()
  {
    |->Int?|
    {
      c := read
      if (c == 0xFFFE) decCol
      return c
    }
  }

//////////////////////////////////////////////////////////////////////////
// Loc helper methods
//////////////////////////////////////////////////////////////////////////

  ** Increments the column location
  Void incCol() { loc = FileLoc(loc.file, loc.line, loc.col + 1) }

  ** Decrements the column location
  Void decCol() { loc = FileLoc(loc.file, loc.line, loc.col - 1) }

  ** Increments the line & resets the column
  Void incLine() { loc = FileLoc(loc.file, loc.line + 1, 1) }

//////////////////////////////////////////////////////////////////////////
// Internal helper methods
//////////////////////////////////////////////////////////////////////////

  ** Deduces the stream encoding from the first four bytes.
  private Void deduceEncoding()
  {
    // Deduce encoding
    Int?[] beg := [,]
    try
    { beg = [in.read, in.read, in.read, in.read] }
    catch(UnsupportedErr e) { return }
    beg.reverse.each |b| { if (b != null) in.unread(b) }

    //UTF-32
    if ((beg[0] == 0x00 && beg[1] == 0x00 && beg[2] == 0xFE && beg[3] == 0xFF) ||
        (beg[0] == 0x00 && beg[1] == 0x00 && beg[2] == 0x00) ||
        (beg[0] == 0xFF && beg[1] == 0xFE && beg[2] == 0x00 && beg[3] == 0x00) ||
        (beg[1] == 0x00 && beg[2] == 0x00 && beg[3] == 0x00))
      throw err("This YAML parser does not support the UTF-32 encoding.")

    //UTF-16BE
    else if ((beg[0] == 0xFE && beg[1] == 0xFF) ||
              beg[0] == 0x00)
    {
      in.charset = Charset.utf16BE
      in.endian = Endian.big
    }

    //UTF-16LE
    else if ((beg[0] == 0xFF && beg[1] == 0xFE) ||
              beg[1] == 0x00)
    {
      in.charset = Charset.utf16LE
      in.endian = Endian.little
    }

    //otherwise just UTF-8 - default
  }

  ** Read the next character, normalizing line breaks.
  private Int? read()
  {
    Int? c
    if (peekArr.size != 0) c = peekArr.removeAt(0)
    else c = in.readChar
    if (c != null) incCol
    if (c == '\r')
    {
      setPeek(1)
      if (peekArr[0] == '\n') return read
      else c = '\n'
    }
    if (c == '\n') incLine
    return c
  }

  ** Ensure that the peek extends to at least n characters.
  private Void setPeek(Int n)
  {
    Int? c
    while (peekArr.size < n && (c = in.readChar) != null) peekArr.add(c)
  }

  ** Unreads the given character. The text location must be managed
  ** manually.
  private Void unread(Int c)
  {
    peekArr.insert(0, c)
  }

  ** Unreads all the given characters. They should appear in the
  ** order they were read, e.g ['t','h','i','s',' ','w','a','y'].
  ** The text location must be managed manually.
  private Void unreadAll(Int[] cs)
  {
    peekArr.insertAll(0, cs)
  }

  ** Character is whitespace (space or tab)
  Bool isWs(Int? c) { c == ' ' || c == '\t' }

  ** Character is a newline character
  Bool isNl(Int? c) { c == '\n' || c == '\r' }

  ** Character is a non-space character, i.e. not EOF/whitespace/newline
  Bool isNs(Int? c) { c != null && !isWs(c) && !isNl(c) }

  ** Character is a flow indicator, i.e. [] {} ,
  Bool isFlow(Int? c) { (['[', ']', '{', '}', ','] as Int?[]).contains(c) }

  ** Character is a flow ending indicator, i.e. ] } ,
  Bool isFlowEnd(Int? c) { ([']', '}', ','] as Int?[]).contains(c) }

  ** Is a word char (0-9, A-Z, a-z, -)
  static Bool isWordChar(Int? c)
  {
    if (c == null) return false
    return ('0' <= c && c <= '9') ||
           ('A' <= c && c <= 'Z') ||
           ('a' <= c && c <= 'z') ||
           (c == '-')
  }

  ** Is a hex digit character (0-9, A-F, a-f)
  static Bool isHexChar(Int? c)
  {
    if (c == null) return false
    return ('0' <= c && c <= '9') ||
           ('A' <= c && c <= 'F') ||
           ('a' <= c && c <= 'f')
  }

  ** Is a character allowed in URI strings
  static Bool isUriChar(Int? c)
  {
    return isWordChar(c) ||
           (['%', '#', ';', '/', '?', ':', '@', '&',
            '=', '+', '$', ',', '_', '.', '!', '~',
            '*', '\'', '(', ')', '[', ']'] as Int?[]).contains(c)
  }

  ** Character is a printable character
  static Bool isPrintable(Int? c)
  {
    if ([0x09, 0x0A, 0x0D, 0x85, null].contains(c)) return true
    if (c <= 0x1F) return false
    if ([0x7F, 0xFFFE, 0xFFFF].contains(c)) return false
    if ((0x80 <= c && c <= 0x9F) || (0xD800 <= c && c <= 0xDFFF)) return false
    return true
  }

  ** Character is an indicator character
  static Bool isIndicator(Int? c)
  {
    return (['-', '?', ':', ',', '[', ']', '{', '}',
            '#', '&', '*', '!', '|', '>', "'", '"',
            '%', '@', '`'] as Int?[]).contains(c)
  }

  ** Error with line & col info
  private Err err(Str msg, FileLoc? loc := null)
  {
    if (loc == null) loc = this.loc
    return FileLocErr(msg, loc)
  }

  ** Error from character outside allowed charset
  private Err charsetErr(Int? c, Str errLoc := "here")
  {
    if (c == null)           return err("End of file reached too soon.")
    else if (isPrintable(c)) return err("Character '$c.toChar' is not allowed ${errLoc}.")
    else                     return err("Character 0x$c.toHex is not a printable character.")
  }

  internal Void debug()
  {
    setPeek(10)
    echo(peekArr.map |c| { c.toChar }.toStr)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private InStream in
  private Int[] peekArr := [,]

  FileLoc loc

}
//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2021 Matthew Giannini   Creation
//

using asn1

**
** Parse a DN using the grammar defined by [RFC4514]`https://tools.ietf.org/html/rfc4514`.
**
class DnParser
{
  new make(Str name)
  {
    this.name = name
  }

  Dn dn() { Dn(parse) }

  Rdn[] parse()
  {
    // init
    pos = -1
    consume

    rdns := Rdn[,]
    while (true)
    {
      type := parseType
      consume('=')
      val  := parseVal
      rdns.add(Rdn(type, val))
      if (cur == ',') consume(',')
      else if (pos >= name.size) break
      else throw err("expected COMMA")
    }
    return rdns
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  private AsnOid parseType()
  {
    startIdx := pos
    buf := StrBuf()
    if (cur.isAlpha)
    {
      // keystring
      while (cur.isAlpha || cur.isDigit || cur == '-')
      {
        buf.addChar(cur)
        consume
      }
      key := buf.toStr.upper
      return Rdn.keywords[key] ?: throw err("Must use OID for type ${key}", startIdx)
    }
    else if (cur.isDigit)
    {
      // numericoid
      buf.add(number)
      while (cur == '.')
      {
        buf.addChar(consume('.'))
        buf.add(number)
      }
      return Asn.oid(buf.toStr)
    }
    else throw err("Invalid attribute type")
  }

  private Str number()
  {
    if (!cur.isDigit) throw err("expected number")
    start := pos
    if (cur == '0') return consume('0').toChar
    while (cur.isDigit) consume
    return name[start..<pos]
  }

//////////////////////////////////////////////////////////////////////////
// Val
//////////////////////////////////////////////////////////////////////////

  private Str parseVal()
  {
    if (cur == '#') return hexstring

    // string
    start := pos

    // check valid first character
    if (isLeadChar) consume
    else if (cur == ESC) consumePair
    else return ""

    // check for rest
    prevValidEnd := true
    while (true)
    {
      if (cur == ESC) { consumePair; prevValidEnd = true }
      else if (isTrailChar) { consume; prevValidEnd = true }
      else if (isStringChar) { consume; prevValidEnd = false }
      else break
    }
    if (!prevValidEnd) throw err("Invalid trailing char", (pos-1))
    return name[start..<pos]
  }

  private Str hexstring()
  {
    start := pos
    consume('#')
    consumeHexPair()
    while (isHex()) consumeHexPair()
    return name[start..<pos]
  }

  private Bool isHex()
  {
    cur.isDigit || ('A' <= cur.upper && cur.upper <= 'F')
  }

  private Void consumeHexPair()
  {
    2.times {
      if (!isHex()) throw err("expected hex pair")
      consume
    }
  }

  private Bool isLeadChar(Int c := cur)
  {
    0x01 <= c && c <= 0x1F ||
    c == 0x21              ||
    0x24 <= c && c <= 0x2A ||
    0x2D <= c && c <= 0x3A ||
    isCommonChar
  }

  private Bool isStringChar(Int c := cur)
  {
    0x01 <= c && c <= 0x21 ||
    0x23 <= c && c <= 0x2A ||
    0x2D <= c && c <= 0x3A ||
    isCommonChar
  }

  private Bool isTrailChar(Int c := cur)
  {
    0x01 <= c && c <= 0x1F ||
    c == 0x21              ||
    0x23 <= c && c <= 0x2A ||
    isCommonChar
  }

  private Bool isCommonChar(Int c := cur)
  {
    0x2D <= c && c <= 0x3A ||
    c == 0x3D              ||
    0x3F <= c && c <= 0x5B ||
    0x5D <= c
  }

  private Void consumePair()
  {
    consume(ESC)
    switch (cur)
    {
      case ESC:
      case SP:
      case '#':
      case '=':
      case '"':
      case '+':
      case ',':
      case ';':
      case '<':
      case '>':
        consume
      default:
        consumeHexPair
    }
  }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  private Err err(Str msg, Int p := pos)
  {
    ParseErr("${msg}. [pos=${p}, char='${name.getSafe(p).toChar}'] ${name}")
  }

  private Int peek(Int n := 1) { name.getSafe(pos+n, -1) }
  private Int consume(Int? c := null)
  {
    temp := cur
    if (c != null && cur != c)
      throw err("Expected '${c.toChar}' but got '${cur.toChar}' at pos ${pos}")
    ++pos
    cur = name.getSafe(pos, -1)
    return temp
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  const Str name

  private static const Int ESC := '\\'
  private static const Int SP  := ' '
  private Int pos := -1
  private Int cur := -1

}
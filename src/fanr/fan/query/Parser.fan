//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    9 May 11  Brian Frank  Creation
//

**
** Parser for fanr query language.
**
internal class Parser
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Str input)
  {
    tokenizer = Tokenizer(input)
    cur = peek = Token.eof
    consume
    consume
  }

//////////////////////////////////////////////////////////////////////////
// Parse query
//////////////////////////////////////////////////////////////////////////

  Query parse()
  {
    parts := QueryPart[,]
    parts.add(part)
    while (cur === Token.comma)
    {
      consume
      parts.add(part)
    }
    if (cur !== Token.eof) throw err("Expecting end of file, not $cur ($curVal)")
    return Query(parts)
  }

  private QueryPart part()
  {
    QueryPart(partName, partVersion, partMetas)
  }

  private Str partName()
  {
    if (cur === Token.id || cur === Token.idPattern)
    {
      name := curVal
      consume
      return name
    }
    throw err("Expecting pod name pattern, not $cur ($curVal)")
  }

  private Depend? partVersion()
  {
    if (cur !== Token.int && cur !== Token.version) return null

    s := StrBuf().add("v ")
    while ((cur === Token.int)     ||
           (cur === Token.version) ||
           (cur === Token.plus)    ||
           (cur === Token.minus)   ||
           (cur === Token.comma && (peek === Token.int || peek === Token.version)))
    {
      s.add(curVal ?: cur.symbol)
      consume
    }
    d := Depend.fromStr(s.toStr, false)
    if (d == null) throw err("Invalid version constraint: $s")
    return d
  }

  private QueryMeta[] partMetas()
  {
    if (cur !== Token.id) return QueryMeta#.emptyList

    metas := QueryMeta[,]
    while (cur === Token.id) metas.add(meta)
    return metas
  }

  private QueryMeta meta()
  {
    name := metaName
    op   := QueryOp.has
    val  := null
    if (cur.queryOp != null)
    {
      op = cur.queryOp
      consume
      val = consumeScalar
    }
    return QueryMeta(name, op, val)
  }

  private Str metaName()
  {
    s := StrBuf()
    s.add(consumeId)
    while (cur === Token.dot)
    {
      consume
      s.addChar('.').add(consumeId)
    }
    return s.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Char Reads
//////////////////////////////////////////////////////////////////////////

  private ParseErr err(Str msg) { tokenizer.err(msg) }

  private Str consumeId()
  {
    verify(Token.id)
    id := curVal
    consume
    return id
  }

  private Obj consumeScalar()
  {
    if (cur === Token.minus && peek === Token.int)
    {
      consume
      int := (Int)curVal
      consume
      return -int
    }

    if (!cur.isScalar)
      throw err("Expected scalar, not $cur")
    val := curVal
    consume
    return val
  }

  private Void verify(Token expected)
  {
    if (cur != expected)
    {
      if (cur === Token.id)
        throw err("Expected $expected, not identifier '$curVal'")
      else
        throw err("Expected $expected, not $cur")
    }
  }

  private Void consume(Token? expected := null)
  {
    if (expected != null) verify(expected)
    cur     = peek
    curVal  = peekVal
    peek    = tokenizer.next
    peekVal = tokenizer.val
 }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Tokenizer tokenizer  // tokenizer
  private Token cur            // current token
  private Obj? curVal          // current token value
  private Token peek           // next token
  private Obj? peekVal         // next token value
}


//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 July 2024  Mike Jarmy   Creation
//

**************************************************************************
**
** Tokenizer transforms a parameterized SQL string into JDBC SQL, using escape
** syntax to transform "\@" and "\\" into "\@" and "\" respectively.
**
**************************************************************************

internal class Tokenizer
{
  internal new make(Str origSql)
  {
    this.origSql = origSql

    next := nextToken()
    while (true)
    {
      switch (next)
      {
        case Token.text:   next = text()
        case Token.param:  next = param()
        case Token.escape: next = escape()
        case Token.quoted: next = quoted()

        case Token.end:
          this.sql = sqlBuf.toStr
          return

        default: throw Err("unreachable")
      }
    }
  }

  ** Process a text token.
  private Token text()
  {
    start := cur++
    tok := nextToken()
    while (tok == Token.text)
    {
      cur++
      tok = nextToken()
    }

    sqlBuf.add(origSql[start..<cur])
    return tok
  }

  ** Process a parameter token: @foo
  private Token param()
  {
    start := cur++
    while (cur < origSql.size && isIdent(origSql[cur]))
      cur++

    // add the JDBC placeholder
    sqlBuf.add("?")

    // remove the leading '@' from the param name
    name := origSql[(start+1)..<cur]

    // save the parameter's location
    locs := params.getOrAdd(name, |k->Int[]| {Int[,]})
    locs.add(++numParams)

    return nextToken()
  }

  ** Process a escaped "@" or "\"
  private Token escape()
  {
    sqlBuf.addChar(origSql[cur+1])
    cur += 2

    return nextToken()
  }

  ** Process a quoted token
  private Token quoted()
  {
    start := cur++
    while (cur < origSql.size)
    {
      if (origSql[cur] == '\'')
      {
        sqlBuf.add(origSql[start..(cur++)])
        return nextToken()
      }
      cur++
    }
    throw SqlErr("Unterminated quoted text.")
  }

  ** Figure out the next token
  private Token nextToken()
  {
    if (cur >= origSql.size)
      return Token.end

    switch(origSql[cur])
    {
      case '@':

        if (isIdent(lookahead(1)))
          return Token.param // @foo
        else
          return Token.text

      case '\\':

        look := lookahead(1)
        if ((look == '@') || (look == '\\'))
          return Token.escape
        else
          throw SqlErr("Invalid escape sequence '${origSql[cur..(cur+1)]}'.")

      case '\'':
          return Token.quoted

      default:
          return Token.text
    }
  }

  ** Is the character part of a valid identifier?
  private static Bool isIdent(Int ch)
  {
    return ((ch >= 'a') && (ch <= 'z')) ||
           ((ch >= 'A') && (ch <= 'Z')) ||
           ((ch >= '0') && (ch <= '9')) ||
           (ch == '_')
  }

  ** Look ahead by n chars, or return -1 if past the end.
  private Int lookahead(Int n)
  {
    return ((cur+n) < origSql.size) ? origSql[cur+n] : -1
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Str origSql
  private Int cur := 0
  private Int numParams := 0
  private StrBuf sqlBuf := StrBuf()

  internal Str? sql
  internal Str:Int[] params := Str:Int[][:]
}

**************************************************************************
** Fields
**************************************************************************

internal enum class Token
{
  text,
  param,
  escape,
  quoted,
  end
}

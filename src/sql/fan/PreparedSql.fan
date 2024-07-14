//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 July 2024  Mike Jarmy   Creation
//

**
** PreparedSql transforms a parameterized SQL string into JDBC format.
**
internal const class PreparedSql
{
  internal new make(Str paramSql)
  {
    // There might be a parameter
    if (paramSql.contains("@"))
    {
      t := Tokenizer(paramSql)
      this.sql = t.sqlBuf.toStr
      this.params = t.params
    }
    // No parameters, so we don't need to tokenize.
    else
    {
      this.sql = paramSql
      this.params = Str:Int[][:]
    }
  }

  ** The transformed sql string. The named parameters are replaced with '?'.
  internal const Str sql

  ** The parameter mapping: <name,list-of-locations>
  internal const Str:Int[] params
}

**************************************************************************
** Tokenizer transforms a parameterized SQL string into PreparedSQL
**************************************************************************

internal class Tokenizer
{
  internal new make(Str sql)
  {
    this.sql = sql

    next := nextToken()
    while (true)
    {
      switch (next)
      {
        case Token.text:       next = text()
        case Token.param:      next = param()
        case Token.escapedVar: next = escapedVar()
        case Token.quoted:     next = quoted()
        case Token.end:        return

        default: throw Err("unreachable")
      }
    }
  }

  ** Process a text token.
  private Token text()
  {
    Int start := cur++
    tok := nextToken()
    while (tok == Token.text)
    {
      cur++
      tok = nextToken()
    }

    sqlBuf.add(sql[start..<cur])
    return tok
  }

  ** Process a parameter token: @foo
  private Token param()
  {
    Int start := cur++
    while (cur < sql.size && isIdent(sql[cur]))
      cur++

    // add the JDBC placeholder
    sqlBuf.add("?")

    // remove the leading '@' from the param name
    name := sql[(start+1)..<cur]

    // save the parameter's location
    locs := params.getOrAdd(name, |k->Int[]| {Int[,]})
    locs.add(++numParams)

    return nextToken()
  }

  ** Process a escaped mysql variable token: @@foo
  private Token escapedVar()
  {
    Int start := cur
    cur += 2
    while (cur < sql.size && isIdent(sql[cur]))
      cur++

    // remove the leading '@' from the escaped variable
    sqlBuf.add(sql[(start+1)..<cur])

    return nextToken()
  }

  ** Process a quoted token
  private Token quoted()
  {
    Int start := cur++
    while (cur < sql.size)
    {
      if (sql[cur] == '\'')
      {
        sqlBuf.add(sql[start..(cur++)])
        return nextToken()
      }
      cur++
    }
    throw SqlErr("Unterminated quoted text.");
  }

  ** Figure out the next token
  private Token nextToken()
  {
    if (cur >= sql.size)
      return Token.end

    switch(sql[cur])
    {
      case '@':
        look := lookahead(1)

        if (isIdent(look))
          return Token.param // @foo

        else if ((look == '@') && isIdent(lookahead(2)))
          return Token.escapedVar // @@foo

        else
          return Token.text

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
    return ((cur+n) < sql.size) ? sql[cur+n] : -1;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Str sql
  private Int cur := 0
  private Int numParams := 0

  internal StrBuf sqlBuf := StrBuf()
  internal Str:Int[] params := Str:Int[][:]
}

**************************************************************************
** Fields
**************************************************************************

internal enum class Token
{
  text,
  param,
  escapedVar,
  quoted,
  end
}

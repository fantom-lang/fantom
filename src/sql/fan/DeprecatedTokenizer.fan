//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 July 2024  Mike Jarmy   Creation
//

**************************************************************************
**
** DeprecatedTokenizer transforms a parameterized SQL string into JDBC SQL,
** using the deprecated '@@foo' syntax for escaped MySql variables.
**
** This tokenizer works according to the following algorithm:
**
**   "foo" means one or more valid identifier characters: [a-z,A-Z,0-9,_]
**
**   (1) Anything between single quotes is translated as is.
**
**   (2) Otherwise:
**
**       (a) "@foo" is a named parameter.
**           A new parameter named "foo" is created.
**           The sql is translated to "?".
**
**       (b) "@@foo" is an escaped mysql user variable.
**           The sql is translated to "@foo".
**
**       (c) Anything else is translated as is.
**
**************************************************************************

internal class DeprecatedTokenizer
{
  internal new make(Str origSql)
  {
    this.origSql = origSql

    next := nextToken()
    while (true)
    {
      switch (next)
      {
        case DeprecatedToken.text:       next = text()
        case DeprecatedToken.param:      next = param()
        case DeprecatedToken.escapedVar: next = escapedVar()
        case DeprecatedToken.quoted:     next = quoted()

        case DeprecatedToken.end:
          this.sql = sqlBuf.toStr
          return

        default: throw Err("unreachable")
      }
    }
  }

  ** Process a text token.
  private DeprecatedToken text()
  {
    start := cur++
    tok := nextToken()
    while (tok == DeprecatedToken.text)
    {
      cur++
      tok = nextToken()
    }

    sqlBuf.add(origSql[start..<cur])
    return tok
  }

  ** Process a parameter token: @foo
  private DeprecatedToken param()
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

  ** Process a escaped mysql variable token: @@foo
  private DeprecatedToken escapedVar()
  {
    start := cur
    cur += 2
    while (cur < origSql.size && isIdent(origSql[cur]))
      cur++

    // remove the leading '@' from the escaped variable
    sqlBuf.add(origSql[(start+1)..<cur])

    return nextToken()
  }

  ** Process a quoted token
  private DeprecatedToken quoted()
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
    throw SqlErr("Unterminated quoted text.");
  }

  ** Figure out the next token
  private DeprecatedToken nextToken()
  {
    if (cur >= origSql.size)
      return DeprecatedToken.end

    switch(origSql[cur])
    {
      case '@':
        look := lookahead(1)

        if (isIdent(look))
          return DeprecatedToken.param // @foo

        else if ((look == '@') && isIdent(lookahead(2)))
          return DeprecatedToken.escapedVar // @@foo

        else
          return DeprecatedToken.text

      case '\'':
          return DeprecatedToken.quoted

      default:
          return DeprecatedToken.text
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
    return ((cur+n) < origSql.size) ? origSql[cur+n] : -1;
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

internal enum class DeprecatedToken
{
  text,
  param,
  escapedVar,
  quoted,
  end
}

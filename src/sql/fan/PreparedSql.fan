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
    t := Transformer(paramSql)
    this.sql = t.sqlBuf.toStr
    this.params = t.params
  }

  ** The transformed sql string. The named parameters are replaced with '?'.
  internal const Str sql

  ** The parameter mapping: <name,list-of-locations>
  internal const Str:Int[] params
}

**************************************************************************
** Transformer transforms a parameterized SQL string into PreparedSQL
**************************************************************************

internal class Transformer
{
  internal new make(Str sql)
  {
    // If there is no "@", then there are no parameters,
    // so we don't need to parse.
    if (!sql.contains("@"))
    {
      sqlBuf.add(sql)
      return
    }

    this.sql = sql
    while (cur < sql.size)
    {
      switch(sql[cur])
      {
        case '@':
          next := lookahead(1)

          if (isIdent(next))
            param() // @foo

          else if ((next == '@') && isIdent(lookahead(2)))
            escapedVariable() // @@foo

          else
            text()

        case '\'':
          quoted()

        default:
          text()
      }
    }
  }

  ** Process the next parameter token: @foo
  private Void param()
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
  }

  ** Process the next escaped mysql variable token: @@foo
  private Void escapedVariable()
  {
    Int start := cur
    cur += 2
    while (cur < sql.size && isIdent(sql[cur]))
      cur++

    // remove the leading '@' from the escaped variable
    sqlBuf.add(sql[(start+1)..<cur])
  }

  ** Process the next quoted token
  private Void quoted()
  {
    Int start := cur++
    while (cur < sql.size)
    {
      if (sql[cur] == '\'')
      {
        sqlBuf.add(sql[start..(cur++)])
        return
      }
      cur++
    }
    throw SqlErr("Unterminated quoted text.");
  }

  ** Process the next text token
  private Void text()
  {
    Int start := cur++
    while (!isTextEnd())
      cur++

    sqlBuf.add(sql[start..<cur])
  }

  ** Have we reached the end of a text token?
  private Bool isTextEnd()
  {
    // reached the end
    if (cur >= sql.size)
      return true;

    switch(sql[cur])
    {
      case '@':
        next := lookahead(1)

        if (isIdent(next))
          return true // @foo

        else if ((next == '@') && isIdent(lookahead(2)))
          return true // @@foo

        else
          return false

      case '\'':
        return true // quoted text

      default:
        return false
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

  private Str sql := ""
  private Int cur := 0
  private Int numParams := 0

  internal StrBuf sqlBuf := StrBuf()
  internal Str:Int[] params := Str:Int[][:] // name -> list of locations
}

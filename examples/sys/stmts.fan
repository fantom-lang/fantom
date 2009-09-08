#! /usr/bin/env fan
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Aug 07  Brian Frank  Creation
//   08 Sep 09  Brian Frank  Rework fandoc -> example
//

**
** Basic language statement constructs
**
class Stmts
{

  Void main()
  {
    stmtIf
    stmtWhile
    stmtFor
    stmtSwitch
    stmtTry
  }

  Void stmtIf()
  {
    echo("\n--- if/else ---")

    // single if with no else
    b := true
    if (true)
      echo("b is true")

    // if/else
    b = false
    if (true)
      echo("b is true")
    else
      echo("b is false")

    // if/else if/else
    i := 1
    if (i == 0)
      echo("i is 0")
    else if (i == 1)
      echo("i is 1")
    else
      echo("i is > 1")
  }

  Void stmtWhile()
  {
    echo("\n--- while ---")

    i := 0
    while (i < 3)
      echo("while-a: " + (i++))

    i = 0
    while (i < 100)
    {
      ++i
      if (i == 1) continue
      if (i == 4) break
      echo("while-b: $i")
    }
  }

  Void stmtFor()
  {
    echo("\n--- for ---")
    for (i:=0; i<3; ++i) echo("for-a: $i")

    for (i:=0;;)
    {
      ++i
      if (i == 2) continue
      if (i == 4) break
      echo("for-b: $i")
    }
  }

  Void stmtSwitch()
  {
    echo("\n--- switch ---")
    method := "get"
    switch (method)
    {
      case "head":
      case "get":
        echo("service-get")
      case "post":
        echo("service-post")
      default:
        echo("service-bad-method")
    }
  }

  Void stmtTry()
  {
    echo("\n--- try ---")
    try
      echo("no throw")
    catch (Err e)
      e.trace

    try
      throw IOErr()
    catch (Err e)
      e.trace
    finally
      echo("finally")
  }

}





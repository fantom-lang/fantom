#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Dec 09  Brian Frank  Creation
//

using util

**
** Illustrates how to use AbstractMain.
**
class DemoMain : AbstractMain
{
  @Opt { help = "Integer option" }
  Int int := 123

  @Opt { help = "String option" }
  Str? str

  @Opt { help = "Date option" }
  Date? date

  @Opt { help = "Bool debug option"; aliases=["v"] }
  Bool debug := false

  @Opt { help = "Use Opt suffix to avoid naming conflicts" }
  Bool logOpt := false

  @Arg { help = "1st argument" }
  File? arg1

  @Arg { help = "2nd argument" }
  Str? arg2

  @Arg { help = "List argument" }
  Str[]? varArg

  override Int run()
  {
    echo("DemoMain.run")
    echo("  log      = $log")
    echo("  homeDir  = $homeDir")
    this.typeof.fields.each |f|
    {
      if (f.isStatic) return
      echo("  ${f.name.padr(8)} = ${f.get(this)}")
    }
    return 0
  }
}
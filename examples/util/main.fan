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
  @opt="integer option"
  Int int := 123

  @opt="string option"
  Str? str

  @opt="date option"
  Date? date

  @opt="bool debug option"
  @optAliases=["v"]
  Bool debug := false

  @opt="use Opt suffix to avoid naming conflicts"
  Bool logOpt := false

  @arg="1st argument"
  File? arg1

  @arg="2nd argument"
  Str? arg2

  @arg="list argument"
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
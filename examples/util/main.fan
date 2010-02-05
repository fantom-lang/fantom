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
  ** integer option
  @Opt Int int := 123

  ** String option"
  @Opt Str? str

  ** date option
  @Opt Date? date

  ** bool debug option
  @Opt { aliases=["v"] } Bool debug := false

  ** use Opt suffix to avoid naming conflicts
  @Opt Bool logOpt := false

  ** 1st argument
  @Arg File? arg1

  ** 2n argument
  @Arg Str? arg2

  ** list argument
  @Arg Str[]? varArg

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
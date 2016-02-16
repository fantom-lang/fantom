#! /usr/bin/env fan
//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Feb 16  Matthew Giannini  Creation
//

**
** Install the language-fantom plugin for the Atom editor.
** Requires 'apm' to be in the PATH.
**
class Install
{

  static Void main()
  {
    args := Env.cur.args
    if (args.size != 0)
    {
      echo("  usage: install")
    }
    c := Process(["apm", "install", "language-fantom"])
    c.run()
    c.join
  }
}

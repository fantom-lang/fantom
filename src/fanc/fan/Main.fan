//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 2025  Brian Frank  Creation
//

using util

**
** Fantom command line compiler tools
**
class Main
{
  static Int main(Str[] args)
  {
    // special handling for -help or -version without cluttering help listing
    if (args.isEmpty || args.first == "-?" || args.first == "-help" || args.first == "--help") args = ["help"]
    else if (args.first == "-version" || args.first == "--version") args = ["version"]

    // lookup command
    cmdName := args.first
    cmd := FancCmd.find(cmdName)
    if (cmd == null)
    {
      echo("ERROR: unknown fanc command '$cmdName'")
      return 1
    }

    // strip command from args and process as util::AbstractMain
    return cmd.main(args.dup[1..-1])
  }
}


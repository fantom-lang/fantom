//
// Copyright (c) 2023, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   27 Jul 2023  Matthew Giannini  Creation
//

using util

**
** Command line main
**
class Main
{
  static Int main(Str[] args)
  {
    // lookup command
    if (args.isEmpty) args = ["help"]
    name := args.first
    cmd := NodeJsCmd.find(name)
    if (cmd == null)
    {
      echo("ERROR: unknown nodeJs command '$name'")
      return 1
    }

    // strip commandname from args and process as util::AbstractMain
    return cmd.main(args.dup[1..-1])
  }
}

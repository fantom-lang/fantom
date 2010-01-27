//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jul 09  Brian Frank  Creation
//

**
** Fanb main
**
class Main
{

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  Void run(Str[] args)
  {
    // process args
    for (i:=0; i<args.size; ++i)
    {
      a := args[i]
      if (a.isEmpty) return
      if (a == "-help" || a == "-h" || a == "-?")
      {
        help
        return
      }
      else if (a[0] == '-')
      {
        echo("WARNING: Unknown option $a")
      }
    }

    echo("build it!")
  }

  Void help()
  {
    echo("Fantom Build Tool");
    echo("Usage:");
    echo("  fanb [options] [dir] [target]");
    echo("Options:");
    echo("  -help, -h, -?   print usage help");
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  static Void main() { make.run(Env.cur.args) }

}
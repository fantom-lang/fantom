//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using fwt

**
** Main launcher for flux.
**
internal class Main
{
  static Void main(Str[] args)
  {
    // touch classes to load
    FileIndex.instance.rebuild

    // initialize frame
    f := Frame.make
    f.loadState

    // load first uri from configured homePage or command line
    if (args.isEmpty)
    {
      f.load(GeneralOptions.load.homePage)
    }
    else
    {
      args.each |arg, i|
      {
        uri := `./`.toFile.normalize.uri + arg.toUri
        if (i == 0) f.load(uri)
        else f.load(uri, LoadMode { newTab = true })
      }
    }

    // open the frame and let's get this party started!
    f.open
  }

  static Void exit(Frame f)
  {
    f.saveState
    Env.cur.exit(0)
  }

}
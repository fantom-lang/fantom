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
    // initialize frame
    f := Frame.make
    f.loadState

    // load first uri from configured homePage or command line
    uri := GeneralOptions.load.homePage
    if (!args.isEmpty) uri = `./`.toFile.normalize.uri + args.first.toUri
    f.load(uri)

    // open the frame and let's get this party started!
    f.open
  }

  static Void exit(Frame f)
  {
    f.saveState
    Sys.exit(0)
  }

}
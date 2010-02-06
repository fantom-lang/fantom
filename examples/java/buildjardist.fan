#! /usr/bin/env fan
//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Feb 10  Brian Frank  Creation
//

using build

**
** Example of how to build a set of Fantom pods into a single Java JAR
**
class Build : BuildScript
{
  @Target { help = "build fansh pod as a single JAR dist" }
  Void dist()
  {
    dist := JarDist(this)
    dist.outFile = `./fansh.jar`.toFile.normalize
    dist.podNames = Str["compiler", "fansh"]
    dist.mainMethod = "fansh::Main.main"
    dist.run
  }
}
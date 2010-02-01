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
  @target="build util::Foo as a single JAR dist"
  Void foo()
  {
    dist := JarDist(this)
    dist.outFile = `./foo.jar`.toFile.normalize
    dist.podNames = ["util"]
    dist.mainMethod = "util::Foo.main"
    dist.run
  }
}
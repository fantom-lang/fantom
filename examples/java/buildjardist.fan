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
  Void distFansh()
  {
    dist := JarDist(this)
    dist.outFile = `./fansh.jar`.toFile.normalize
    dist.podNames = Str["compiler", "concurrent", "fansh"]
    dist.mainMethod = "fansh::Main.main"
    dist.run
  }

  @Target { help = "build wisp pod as a single JAR dist" }
  Void distWisp()
  {
    dist := JarDist(this)
    dist.outFile = `./wisp.jar`.toFile.normalize
    dist.podNames = Str["concurrent", "inet", "util", "web", "webmod", "wisp"]
    dist.mainMethod = "wisp::WispService.main"
    dist.run
  }

  @Target { help = "build testSys pod as a single JAR dist" }
  Void distTestSys()
  {
    dist := JarDist(this)
    dist.outFile = `./testSys.jar`.toFile.normalize
    dist.podNames = Str["concurrent", "testSys"]
    dist.mainMethod = "[java]fanx.tools::Fant.fanMain"
    dist.run
  }

  @Target { help = "build FWT test app as JAR; must put swt.jar into classpath!" }
  Void distFwtTest()
  {
    dist := JarDist(this)
    dist.outFile = `./fwtTest.jar`.toFile.normalize
    dist.podNames = Str["concurrent", "gfx", "fwt"]
    dist.mainMethod = "fwt::FwtTestMain.main"
    dist.run

    // test example:
    // java -cp lib\java\ext\win32-x86_64\swt.jar;fwtTest.jar fanjardist.Main
  }
}
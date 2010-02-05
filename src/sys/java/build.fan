#! /usr/bin/env fansubstitute
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Nov 06  Brian Frank  Creation
//

using build

**
** Build: sys.jar
**
** Note: this script builds the Java runtime for Fantom's sys pod.
**
class Build : BuildJava
{

  new make()
  {
    jar = devHomeDir.uri + `lib/java/sys.jar`
    mainClass = "fanx.tools.Fan"
    packages = ["fan.sys",
                "fanx.emit",
                "fanx.fcode",
                "fanx.interop",
                "fanx.serial",
                "fanx.test",
                "fanx.tools",
                "fanx.util"]
  }

}
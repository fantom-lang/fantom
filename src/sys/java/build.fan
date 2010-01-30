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

  override Void setup()
  {
    if (devHomeDir == Env.cur.homeDir)
      throw fatal("Must update etc/build/config.props devHome for bootstrap")

    jar = libJavaDir + `sys.jar`
    mainClass = "fanx.tools.Fan"
    packages = ["fan.sys",
                "fanx.emit",
                "fanx.fcode",
                "fanx.interop",
                "fanx.serial",
                "fanx.typedb",
                "fanx.test",
                "fanx.tools",
                "fanx.util"]
  }

}
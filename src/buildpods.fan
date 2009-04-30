#! /usr/bin/env fan
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jan 07  Brian Frank  Creation
//

using build

**
** buildpods.fan
**
** This is the second sub-script of the two part buildall script.
** Once buildboot has completed this development environment now has
** the necessary infrastructure to self build the rest of the pod
** library.
**
class Build : BuildGroup
{

  override Void setup()
  {
    childrenScripts =
    [
      `testSys/build.fan`,
      `testNative/build.fan`,
      `testCompiler/build.fan`,
      `testJava/build.fan`,
      `fand/build.fan`,
      `inet/build.fan`,
      `fansh/build.fan`,
      `web/build.fan`,
      `webapp/build.fan`,
      //`webServlet/build.fan`,
      `compilerJavascript/build.fan`,
      `webappClient/build.fan`,
      `testWeb/build.fan`,
      `wisp/build.fan`,
      `fandoc/build.fan`,
      `docCompiler/build.fan`,
      `doc/build.fan`,
      `sql/build.fan`,
      `email/build.fan`,
      `gfx/build.fan`,
      `fwt/build.fan`,
      `icons/build.fan`,
      `flux/build.fan`,
      `xml/build.fan`,
      `json/build.fan`,
      `obix/build.fan`,
    ]
  }

}
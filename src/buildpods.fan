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

  new make()
  {
    childrenScripts =
    [
      `compilerJs/build.fan`,
      `concurrent/build.fan`,
      `testSys/build.fan`,
      `testNative/build.fan`,
      `testCompiler/build.fan`,
      `testJava/build.fan`,
      `math/build.fan`,
      `util/build.fan`,
      `inet/build.fan`,
      `fansh/build.fan`,
      `web/build.fan`,
      `fanr/build.fan`,
      `webmod/build.fan`,
      `wisp/build.fan`,
      `fandoc/build.fan`,
      `syntax/build.fan`,
      `sql/build.fan`,
      `email/build.fan`,
      `graphics/build.fan`,
      `gfx/build.fan`,
      `compilerDoc/build.fan`,
      `dom/build.fan`,
      `domkit/build.fan`,
      `testDomkit/build.fan`,
      `fwt/build.fan`,
      `webfwt/build.fan`,
      `icons/build.fan`,
      `flux/build.fan`,
      `xml/build.fan`,
      `obix/build.fan`,
      `doc/build.fan`,
    ]
  }

}
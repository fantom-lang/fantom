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
      `compilerEs/build.fan`,
      `fandoc/build.fan`,
      `concurrent/build.fan`,
      `util/build.fan`,
      `nodeJs/build.fan`,
      `math/build.fan`,
      `asn1/build.fan`,
      `crypto/build.fan`,
      `inet/build.fan`,
      `fansh/build.fan`,
      `web/build.fan`,
      `fanr/build.fan`,
      `webmod/build.fan`,
      `wisp/build.fan`,
      `syntax/build.fan`,
      `sql/build.fan`,
      `email/build.fan`,
      `graphics/build.fan`,
      `graphicsJava/build.fan`,
      `compilerDoc/build.fan`,
      `dom/build.fan`,
      `domkit/build.fan`,
      `xml/build.fan`,
      `yaml/build.fan`,
      `doc/build.fan`,
      `cryptoJava/build.fan`,
      `testSys/build.fan`,
      `testNative/build.fan`,
      `testCompiler/build.fan`,
      `testJava/build.fan`,
      `testGraphics/build.fan`,
      `testDomkit/build.fan`,
    ]
  }

}
#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Dec 08  Andy Frank  Creation
//

using build

**
** Build: compilerJs
**
class Build : BuildPod
{
  new make()
  {
    podName = "compilerJs"
    summary = "Fantom to JavaScript Compiler"
    depends = ["sys 1.0", "compiler 1.0", "build 1.0"]
    srcDirs = [`fan/`, `fan/ast/`, `fan/runner/`, `fan/util/`]
    docSrc  = true
  }
}
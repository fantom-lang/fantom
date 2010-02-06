#! /usr/bin/env fansubstitute
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Nov 06  Brian Frank  Creation
//

using build

**
** Build: compiler
**
class Build : BuildPod
{
  new make()
  {
    podName    = "compiler"
    summary    = "Fantom compiler"
    depends    = ["sys 1.0"]
    srcDirs    = [`fan/`,
                  `fan/assembler/`,
                  `fan/ast/`,
                  `fan/dsl/`,
                  `fan/fcode/`,
                  `fan/namespace/`,
                  `fan/parser/`,
                  `fan/steps/`,
                  `fan/util/`]
    docSrc     = true
    dependsDir = devHomeDir.uri + `lib/fan/`
    outDir     = devHomeDir.uri + `lib/fan/`
    index =
    [
      // DSL plugins
      "compiler.dsl.sys::Regex": "compiler::RegexDslPlugin",
      "compiler.dsl.sys::Str": "compiler::StrDslPlugin"
    ]
  }
}
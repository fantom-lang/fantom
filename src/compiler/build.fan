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

  override Void setup()
  {
    podName     = "compiler"
    version     = globalVersion
    description = "Fan compiler"
    depends     = ["sys 1.0"]
    dependsDir  = libFanDir.uri
    srcDirs     = [`fan/`,
                   `fan/assembler/`,
                   `fan/ast/`,
                   `fan/dsl/`,
                   `fan/fcode/`,
                   `fan/namespace/`,
                   `fan/parser/`,
                   `fan/steps/`,
                   `fan/util/`]
    includeSrc  = true
    podFacets =
    [
      "indexFacets": ["compilerBridge", "compilerDsl"]
    ]
  }

}
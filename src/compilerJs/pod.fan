//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    9 Dec 08  Andy Frank   Original
//   17 Jul 09  Brian Frank  Create from "build.fan"
//

**
** Fantom to JavaScript Compiler
**

@podDepends = [Depend("sys 1.0"), Depend("compiler 1.0"), Depend("build 1.0")]
@podSrcDirs = [`fan/`, `fan/ast/`, `fan/runner/`]
@docsrc

pod compilerJs {}
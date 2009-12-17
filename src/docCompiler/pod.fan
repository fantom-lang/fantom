//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    5 May 07  Brian Frank  Original
//   17 Jul 09  Brian Frank  Create from "build.fan"
//

**
** Fantom documentation compiler
**

@podDepends = [Depend("sys 1.0"),
               Depend("compiler 1.0"),
               Depend("build 1.0"),
               Depend("util 1.0"),
               Depend("fandoc 1.0")]
@podSrcDirs = [`fan/`, `fan/steps/`, `fan/html/`, `test/`]
@podResDirs = [`res/`]

pod docCompiler {}
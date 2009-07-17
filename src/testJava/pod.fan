//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Nov 08  Brian Frank  Break out tests
//   14 Jul 09  Brian Frank  Create from "build.fan"
//

**
** Test suite for Java FFI compiler plugin
**

@podDepends = [Depend("sys 1.0"), Depend("compiler 1.0"), Depend("compilerJava 1.0"), Depend("testCompiler 1.0")]
@podSrcDirs = [`fan/`]
@nodoc

pod testJava {}
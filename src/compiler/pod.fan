//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    4 Nov 06  Brian Frank  Original
//   16 Jul 09  Brian Frank  Create from "build.fan"
//

**
** Fantom compiler
**

@podDepends = [Depend("sys 1.0")]
@podSrcDirs = [`fan/`,
               `fan/assembler/`,
               `fan/ast/`,
               `fan/dsl/`,
               `fan/fcode/`,
               `fan/namespace/`,
               `fan/parser/`,
               `fan/steps/`,
               `fan/util/`]
@podIndexFacets = [@compilerBridge, @compilerDsl]
@docsrc

pod compiler
{
  **
  ** Facet used to bind a `DslPlugin` to a anchor type qname.
  **
  Str compilerDsl := ""

  **
  ** Facet used to bind a `CBridge` to FFI name.
  **
  Str compilerBridge := ""
}
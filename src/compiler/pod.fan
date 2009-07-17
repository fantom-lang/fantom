//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jul 09  Brian Frank  Creation
//

**
** Fan compiler
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
@indexFacets = ["compiler::compilerBridge", "compiler::compilerDsl"]

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


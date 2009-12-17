//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Nov 07  Brian Frank  Original
//   17 Jul 09  Brian Frank  Create from "build.fan"
//    1 Dec 09  Brian Frank  Rename fand to util
//

**
** Utilities
**

@podDepends = [Depend("sys 1.0")]
@podSrcDirs = [`fan/`]
@docsrc

pod util
{
  ** Facet for annotating an `AbstractMain` argument field.
  Str arg := ""

  ** Facet for annotating an `AbstractMain` option field.
  Str opt := ""

  ** Facet for annotating an `AbstractMain` option field.
  Str[] optAliases := Str[,]

}


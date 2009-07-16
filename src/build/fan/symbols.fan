//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Jul 09  Brian Frank  Creation
//

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

**
** Target facet is applied to a `BuildScript` method to
** indicate it is a build target or goal.
**
Bool target := false

** User account used to build target
Str buildUser := ""

** Host machine used to build target
Str buildHost := ""

** Time target was build
** TODO-SYM
Str buildTime := ""


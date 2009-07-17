//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Jul 09  Brian Frank  Creation
//

**
** Fan build utility
**

@podDepends = [Depend("sys 1.0"), Depend("compiler 1.0")]
@podSrcDirs = [`fan/`, `fan/tasks/`]

pod build
{

  **
  ** Target facet is applied to a `BuildScript` method to
  ** indicate it is a build target or goal.
  **
  Bool target := false

}



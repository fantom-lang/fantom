//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    4 Nov 06  Brian Frank  Original
//   14 Jul 09  Brian Frank  Create from "build.fan"
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
  ** indicate it is a build target or goal.  The string value
  ** should be a description of the target.
  **
  Str target := false

}



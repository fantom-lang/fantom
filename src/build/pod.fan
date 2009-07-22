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

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  **
  ** Target facet is applied to a `BuildScript` method to
  ** indicate it is a build target or goal.  The string value
  ** should be a description of the target.
  **
  Str target := false

//////////////////////////////////////////////////////////////////////////
// Configuration
//////////////////////////////////////////////////////////////////////////

  ** Version to use by default for building pods (and other targets).
  virtual Version buildVersion := Version("0.0.0")

  ** Home directory of development installation - typically this
  ** is boot repo.  But we override it for bootstrap builds.
  virtual Uri? buildDevHome := null

  ** Home directory of JDK installation - required for
  ** Java related build tasks.
  virtual Uri? buildJdkHome := null

  ** Home directory of .NET installation - required for
  ** .NET related build tasks.
  virtual Uri? buildDotnetHome := null

}



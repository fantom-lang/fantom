#! /usr/bin/env fan
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jan 07  Brian Frank  Creation
//

using build

**
** builddocs.fan
**
**
class Build : BuildGroup
{

  override Void setup()
  {
    childrenScripts =
    [
      `docIntro/build.fan`,
      `docLang/build.fan`,
      `docLib/build.fan`,
      `docTools/build.fan`,
    ]
  }

}
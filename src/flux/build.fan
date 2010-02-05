#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jan 08  Brian Frank  Creation
//

using build

**
** Build flux/ pods
**
class Build : BuildGroup
{

  new make()
  {
    childrenScripts =
    [
      `flux/build.fan`,
      `fluxText/build.fan`,
    ]
  }

}
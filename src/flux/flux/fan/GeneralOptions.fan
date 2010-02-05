//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   09 Aug 08  Brian Frank  Creation
//

**
** GeneralOptions is a catch-all for general purpose options.
**
@Serializable
const class GeneralOptions
{

  **
  ** Convenience for loading from "general"
  **
  static GeneralOptions load()
  {
    return Flux.loadOptions(Flux.pod, "general", GeneralOptions#)
  }

  **
  ** Default constructor with it-block
  **
  new make(|This|? f := null) { if (f != null) f(this) }

  **
  ** Default uri to display on startup.
  **
  const Uri homePage := `flux:start`

  **
  ** Directories to index for Goto-File command.
  **
  const Uri[] indexDirs := Uri[,]

}
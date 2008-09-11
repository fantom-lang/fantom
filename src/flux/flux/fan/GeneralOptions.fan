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
@serializable
const class GeneralOptions
{

  **
  ** Convenience for loading from "general"
  **
  static GeneralOptions load()
  {
    return Flux.loadOptions("general", GeneralOptions#)
  }

  **
  ** Default uri to display on startup.
  **
  const Uri homePage := `flux:start`

}

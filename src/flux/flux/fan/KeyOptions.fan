//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Aug 08  Brian Frank  Creation
//

**
** KeyOptions allow the user to redefine accelerators for
** the flux command set.
**
@Serializable
const class KeyOptions
{

  **
  ** Convenience for loading from "keys"
  **
  static KeyOptions load()
  {
    return Flux.loadOptions(Flux.pod, "keys", KeyOptions#)
  }

  **
  ** Default constructor with it-block
  **
  new make(|This|? f := null) { if (f != null) f(this) }

  **
  ** Binding of command ids to key accelerators.  The keys of this
  ** map are [FluxCommand.ids]`FluxCommand.id`.  See `CommandId` for
  ** the commonly used predefined commmands.  The values of the map
  ** are string representations of `fwt::Key`.  If a command is not mapped
  ** in this table, then it defaults to the accelerator defined by
  ** the command's localized props.
  **
  const Str:Str bindings := Str:Str[:]

}
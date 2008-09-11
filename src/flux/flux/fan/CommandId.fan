//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Aug 08  Brian Frank  Creation
//

**
** Commonly used `FluxCommand` ids for the commands
** built-in into the flux runtime.
**
class CommandId
{
  // file menu
  static const Str start        := "start"
  static const Str newWindow    := "newWindow"
  static const Str newTab       := "newTab"
  static const Str openLocation := "openLocation"
  static const Str save         := "save"
  static const Str exit         := "exit"

  // edit menu
  static const Str undo       := "undo"
  static const Str redo       := "redo"
  static const Str cut        := "cut"
  static const Str copy       := "copy"
  static const Str paste      := "paste"

  // view menu
  static const Str reload     := "refresh"

  // history menu
  static const Str back       := "back"
  static const Str forward    := "forward"
  static const Str up         := "up"

  // tools menu
  static const Str options    := "options"

  // help menu
  static const Str about      := "about"
}
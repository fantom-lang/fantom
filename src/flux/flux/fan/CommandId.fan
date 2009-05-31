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
  static const Str newTab         := "newTab"
  static const Str openLocation   := "openLocation"
  static const Str closeTab       := "closeTab"
  static const Str save           := "save"
  static const Str saveAll        := "saveAll"
  static const Str exit           := "exit"

  // edit menu
  static const Str undo           := "undo"
  static const Str redo           := "redo"
  static const Str cut            := "cut"
  static const Str copy           := "copy"
  static const Str paste          := "paste"
  static const Str find           := "find"             // view managed
  static const Str findNext       := "findNext"         // view managed
  static const Str findPrev       := "findPrev"         // view managed
  static const Str findInFiles    := "findInFiles"
  static const Str replace        := "replace"          // view managed
  static const Str replaceInFiles := "replaceInFiles"
  static const Str goto           := "goto"             // view managed
  static const Str gotoFile       := "gotoFile"
  static const Str jumpNext       := "jumpNext"
  static const Str jumpPrev       := "jumpPrev"
  static const Str selectAll      := "selectAll"

  // view menu
  static const Str reload         := "refresh"

  // history menu
  static const Str back           := "back"
  static const Str forward        := "forward"
  static const Str up             := "up"
  static const Str home           := "home"
  static const Str recent         := "recent"

  // tools menu
  static const Str options        := "options"
  static const Str refreshTools   := "refreshTools"

  // help menu
  static const Str about          := "about"
}
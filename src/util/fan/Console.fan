//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jun 24  Brian Frank  Creation
//

**
** Console provides utility to work with terminal or JS debugging window
**
//@Js
native const final class Console
{
  ** Get the default console for the virtual machine
  static Console cur()

  ** Number of chars that fit horizontally in console or null if unknown
  Int? width()

  ** Number of lines that fit vertically in console or null if unknown
  Int? height()

  ** Print a message to the console at the debug level
  This debug(Obj? msg)

  ** Print a message to the console at the informational level
  This info(Obj? msg)

  ** Print a message to the console at the warning level
  This warn(Obj? msg)

  ** Print a message to the console at the error level
  This err(Obj? msg)

  ** Print tabular data to the console.
  ** TODO: more docs around how lists and maps work...
  This table(Obj? obj)

  ** Clear the console of all text if supported
  This clear()

  ** Enter an indented group level in the console.  The JS debug
  ** window can specify the group to default in a collapsed state (this
  ** flag is ignored in a standard terminal).
  This group(Obj? msg, Bool collapsed := false)

  ** Exit an indented, collapsable group level
  This groupEnd()

  ** Prompt the user to enter a string from standard input.
  ** Return null if end of stream has been reached.
  Str? prompt(Str msg := "")

  ** Prompt the user to enter a password string from standard input
  ** with echo disabled.  Return null if end of stream has been reached.
  Str? promptPassword(Str msg := "")
}


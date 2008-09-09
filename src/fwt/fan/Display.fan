//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Sep 08  Brian Frank  Creation
//

**
** Display represents the user's display device (typically
** one or more monitors).
**
class Display
{

  **
  ** The the current display instance for the application.
  **
  native static Display current()

  **
  ** Get the current focused widget or return null.
  **
  native Widget focus()

}
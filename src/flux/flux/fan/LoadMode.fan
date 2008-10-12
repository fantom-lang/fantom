//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Sep 08  Brian Frank  Creation
//

using fwt

**
** LoadMode is used to configure how a resource is
** loaded into view such as whether to use a new tab.
**
class LoadMode
{

  **
  ** Construct with an optional user event.  If the user
  ** was holding down the Ctrl key (Command for Macs), then
  ** set newTab to true.
  **
  new make(Event? event := null)
  {
    key := event?.key
    if (key != null)
      newTab = Desktop.isMac ? key.isCommand : key.isCtrl
  }

  **
  ** If true, then load using a new tab in the current window.
  **
  Bool newTab := false

  **
  ** If true then the uri is added to the browser's history.
  ** Typically only predefined commands like back, forward, or
  ** reload should set this to false.
  **
  Bool addToHistory := true

}
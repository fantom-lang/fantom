//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Sep 08  Brian Frank  Creation
//

**
** LoadMode is used to configure how a resource is
** loaded into view such as whether to use a new tab.
**
class LoadMode
{

  **
  ** If true, then load using a new window.
  **
  Bool newWindow := false

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
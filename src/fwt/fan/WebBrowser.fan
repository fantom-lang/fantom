//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jun 08  Brian Frank  Creation
//

**
** WebBrowser is used to display HTML text or view a URL.
**
@Serializable
class WebBrowser : Widget
{

  **
  ** Callback when the user clicks a hyperlink.  The callback
  ** is invoked before the actual hyperlink.  The event handler
  ** can modify the 'data' field with a new Uri or set to null
  ** to cancel the hyperlink.  This callback is *not* called if
  ** explicitly loaded via the `load` method.
  **
  ** Event id fired:
  **   - `EventId.hyperlink`
  **
  ** Event fields:
  **   - `Event.data`: the `sys::Uri` of the new page.
  **
  once EventListeners onHyperlink() { EventListeners() }

  **
  ** Navigate to the specified URI.
  **
  native This load(Uri uri)

  **
  ** Load the given HTML into the browser.
  **
  native This loadStr(Str html)

  **
  ** Refresh the current page.
  **
  native This refresh()

  **
  ** Stop any load activity.
  **
  native This stop()

  **
  ** Navigate to the previous session history.
  **
  native This back()

  **
  ** Navigate to the next session history.
  **
  native This forward()

}
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//   8 Jul 09  Andy Frank  Split webappClient into sys/dom
//

using graphics

**
** Win models the DOM window object.
**
** See [pod doc]`pod-doc#win` for details.
**
@Js
class Win
{

//////////////////////////////////////////////////////////////////////////
// Constrcutor
//////////////////////////////////////////////////////////////////////////

  ** Private ctor.
  private new make()
  {
    ua := userAgent

    this.isMac     = ua.contains("Mac OS X")
    this.isWindows = ua.contains("Windows")
    this.isLinux   = ua.contains("Linux")

    this.isWebkit  = ua.contains("AppleWebKit/")
    this.isChrome  = ua.contains("Chrome/")
    this.isSafari  = ua.contains("Safari/") && ua.contains("Version/")
    this.isFirefox = ua.contains("Firefox/")
    this.isIE      = ua.contains("MSIE") || ua.contains("Trident/")
    this.isEdge    = ua.contains("Edge/")
  }

  ** Return the current window instance.
  static native Win cur()

//////////////////////////////////////////////////////////////////////////
// Secondary Windows
//////////////////////////////////////////////////////////////////////////

  ** Open a new window. Returns the new window instance.
  native Win open(Uri uri := `about:blank`, Str? winName := null, [Str:Str]? opts := null)

  ** Close this window.  Only applicable to windows created with
  ** `open`. Otherwise method has no effect.  Returns this.
  native Win close()

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  ** Return the Doc instance for this window.
  native Doc doc()

  ** Return current text selection model.
  @NoDoc native TextSel textSel()

  ** Add new CSS style rules to this page.
  native Void addStyleRules(Str rules)

  ** Display a modal message box with the given text.
  native Void alert(Obj obj)

  ** Display a confirmation dialog box with the given text.
  ** Returns 'true' if 'ok' was selected, 'false' othterwise.
  native Bool confirm(Obj obj)

  ** Return the size of the window viewport in pixels.
  native Size viewport()

  ** Return the size of the screen in pixels.
  native Size screenSize()

  ** Returns a reference to the parent of the current window
  ** or subframe, or null if this is the top-most window.
  native Win? parent()

  ** Returns a reference to the topmost window in the window
  ** hierarchy.  If this window is the topmost window, returns
  ** self.
  native Win top()

  ** Evaluate given JavaScript code.
  static native Obj eval(Str js)

  ** Log object to console.
  native Void log(Obj? obj)

//////////////////////////////////////////////////////////////////////////
// Scrolling
//////////////////////////////////////////////////////////////////////////

  ** Return current scroll position of document in this window.
  native Point scrollPos()

  ** Scrolls to a particular set of coordinates in the document.
  native This scrollTo(Int x, Int y)

  ** Scrolls the document in the window by the given amount.
  native This scrollBy(Int x, Int y)

//////////////////////////////////////////////////////////////////////////
// Uri
//////////////////////////////////////////////////////////////////////////

  ** Get the Uri for this window.
  native Uri uri()

  ** Hyperlink to the given Uri in this window.
  native Void hyperlink(Uri uri)

  ** Reload the current page. Use 'force' to bypass browse cache.
  native Void reload(Bool force := false)

//////////////////////////////////////////////////////////////////////////
// Clipboard
//////////////////////////////////////////////////////////////////////////

  **
  ** Read textual contents of the system clipboard. Returns an empty
  ** string if the clipboard is empty, does not contain text, or does
  ** not include a textual representation of clipboard's contents.
  **
  ** The user has to interact with the page or a UI element in order
  ** for this feature to work.
  **
  native Void clipboardReadText(|Str text| f)

  **
  ** Write given text to the system clipboard.
  **
  ** The user has to interact with the page or a UI element in order
  ** for this feature to work.
  **
  native Void clipboardWriteText(Str text)

//////////////////////////////////////////////////////////////////////////
// History
//////////////////////////////////////////////////////////////////////////

  ** Go to previous page in session history.
  native Void hisBack()

  ** Go to next page in the session history.
  native Void hisForward()

  **
  ** Push a new history item onto the history stack. Use 'onpopstate'
  ** to listen for changes:
  **
  **   // Event.stash contains state map passed into pushState
  **   Win.cur.onEvent("popstate", false) |e| { echo("# state: $e.stash") }
  **
  native Void hisPushState(Str title, Uri uri, Str:Obj map)

  **
  ** Modify the current history item.
  **
  native Void hisReplaceState(Str title, Uri uri, Str:Obj map)

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  ** Attach an event handler for the given event on this window.
  ** Returns callback function instance.
  native Func onEvent(Str type, Bool useCapture, |Event e| handler)

  ** Remove the given event handler from this window.  If this
  ** handler was not registered, this method does nothing.
  native Void removeEvent(Str type, Bool useCapture, Func handler)

  ** Request the browser to perform an animation before the next repaint.
  native Void reqAnimationFrame(|This| f)

//////////////////////////////////////////////////////////////////////////
// Timers
//////////////////////////////////////////////////////////////////////////

  ** Call the specified function after a specified delay. Returns
  ** a timeoutId that can be used in `clearTimeout`.
  native Int setTimeout(Duration delay, |This win| f)

  ** Clears the delay set by `setTimeout`.
  native Void clearTimeout(Int timeoutId)

  ** Calls a function repeatedly, with a fixed time delay between
  ** each call to that function. Returns an intervalId that can be
  ** used in `clearInterval`.
  native Int setInterval(Duration delay, |This win| f)

  ** Cancels a repeated action which was set up using `setInterval`.
  native Void clearInterval(Int intervalId)

//////////////////////////////////////////////////////////////////////////
// Geolocation
//////////////////////////////////////////////////////////////////////////

  ** Get the the current position of this device. This feature
  ** is only available in secure contexts (HTTPS).
  native Void geoCurPosition(|DomCoord| onSuccess, |Err|? onErr := null, [Str:Obj]? opts := null)

  ** Register a handler function that will be called automatically each
  ** time the position of the device changes. This method returns a watch
  ** ID value that then can be used to unregister the handler with the
  ** `geoClearWatch` method. This feature is only available in secure
  ** contexts (HTTPS).
  native Int geoWatchPosition(|DomCoord| onSuccess, |Err|? onErr := null, [Str:Obj]? opts := null)

  ** Unregister location/error monitoring handlers previously installed
  ** using `geoWatchPosition`. This feature is only available in secure
  ** contexts (HTTPS).
  native Void geoClearWatch(Int id)

//////////////////////////////////////////////////////////////////////////
// Storage
//////////////////////////////////////////////////////////////////////////

  ** Return session storage instance for window.
  native Storage sessionStorage()

  ** Return local storage instance for window.
  native Storage localStorage()

//////////////////////////////////////////////////////////////////////////
// UA
//////////////////////////////////////////////////////////////////////////

  ** Get the browser user agent string.
  @NoDoc native Str userAgent()

  @NoDoc const Bool isMac
  @NoDoc const Bool isWindows
  @NoDoc const Bool isLinux

  @NoDoc const Bool isWebkit
  @NoDoc const Bool isChrome
  @NoDoc const Bool isSafari
  @NoDoc const Bool isFirefox
  @NoDoc const Bool isIE
  @NoDoc const Bool isEdge

//////////////////////////////////////////////////////////////////////////
// Diagnostics
//////////////////////////////////////////////////////////////////////////

  ** Poll for a browser dependent map of diagnostics name/value pairs
  ** for current state of JsVM and DOM.
  @NoDoc native Str:Obj diagnostics()
}
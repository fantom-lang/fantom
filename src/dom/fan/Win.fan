//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//   8 Jul 09  Andy Frank  Split webappClient into sys/dom
//

using gfx

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

  **
  ** Private ctor.
  **
  private new make() {}

  **
  ** Return the current window instance.
  **
  static native Win cur()

//////////////////////////////////////////////////////////////////////////
// Secondary Windows
//////////////////////////////////////////////////////////////////////////

  **
  ** Open a new window. Returns the new window instance.
  **
  static native Win open(Uri uri := `about:blank`, Str? winName := null, [Str:Str]? opts := null)

  **
  ** Close this window.  Only applicable to windows created with
  ** `open`. Otherwise method has no effect.  Returns this.
  **
  native Win close()

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the Doc instance for this window.
  **
  native Doc doc()

  **
  ** Display a modal message box with the given text.
  **
  native Void alert(Obj obj)

  **
  ** Return the size of the window viewport in pixels.
  **
  native Size viewport()

  **
  ** Returns a reference to the parent of the current window
  ** or subframe, or null if this is the top-most window.
  **
  native Win? parent()

  **
  ** Returns a reference to the topmost window in the window
  ** hierarchy.  If this window is the topmost window, returns
  ** self.
  **
  native Win top()

//////////////////////////////////////////////////////////////////////////
// Uri
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the Uri for this window.
  **
  native Uri uri()

  **
  ** Hyperlink to the given Uri in this window.
  **
  native Void hyperlink(Uri uri)

  **
  ** Reload the current page. Use 'force' to bypass browse cache.
  **
  native Void reload(Bool force := false)

//////////////////////////////////////////////////////////////////////////
// History
//////////////////////////////////////////////////////////////////////////

  **
  ** Go to previous page in session history.
  **
  native Void hisBack()

  **
  ** Go to next page in the session history.
  **
  native Void hisForward()

  **
  ** Push a new history item onto the history stack. Use 'onpopstate'
  ** to listen for changes:
  **
  **   // Event.meta contains state map passed into pushState
  **   Win.cur.onEvent("popstate", false) |e| { echo("# state: $e.meta") }
  **
  native Void hisPushState(Str title, Uri uri, Str:Obj map)

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  **
  ** Attach an event handler to the given event on this element.
  **
  native Void onEvent(Str type, Bool useCapture, |DomEvent e| handler)

//////////////////////////////////////////////////////////////////////////
// Storage
//////////////////////////////////////////////////////////////////////////

  **
  ** Return session storage instance for window.
  **
  native Storage sessionStorage()

  **
  ** Return local storage instance for window.
  **
  native Storage localStorage()

}
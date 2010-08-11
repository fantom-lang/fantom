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
// Events
//////////////////////////////////////////////////////////////////////////

  **
  ** Attach an event handler to the given event on this element.
  **
  native Void onEvent(Str type, Bool useCapture, |Event e| handler)

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
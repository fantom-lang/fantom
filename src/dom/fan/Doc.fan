//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

using web

**
** Doc models the DOM document object.
**
** See [pod doc]`pod-doc#doc` for details.
**
@Js
class Doc
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  ** Private ctor.
  private new make() {}

//////////////////////////////////////////////////////////////////////////
// Meta
//////////////////////////////////////////////////////////////////////////

  ** The title of this document.
  native Str title

//////////////////////////////////////////////////////////////////////////
// Elements
//////////////////////////////////////////////////////////////////////////

  ** Get the body element.
  native Elem body()

  **
  ** Get the element with this 'id', or 'null' if no
  ** element is found with this 'id'.
  **
  native Elem? elem(Str id)

  **
  ** Create a new element with the given tag name.  If the
  ** attrib map is specified, set the new elements attributes
  ** to the given values.
  **
  native Elem createElem(Str tagName, [Str:Str]? attrib := null)

  ** Create a document fragment.
  @NoDoc native Elem createFrag()

  **
  ** Returns the first element within the document (using depth-first
  ** pre-order traversal of the document's nodes) that matches the
  ** specified group of selectors, or null if none found.
  **
  native Elem? querySelector(Str selectors)

  **
  ** Returns a list of the elements within the document (using
  ** depth-first pre-order traversal of the document's nodes) that
  ** match the specified group of selectors.
  **
  native Elem[] querySelectorAll(Str selectors)

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  ** Attach an event handler for the given event on this document.
  ** Returns callback function instance.
  native Func onEvent(Str type, Bool useCapture, |Event e| handler)

  ** Remove the given event handler from this document.  If this
  ** handler was not registered, this method does nothing.
  native Void removeEvent(Str type, Bool useCapture, Func handler)

//////////////////////////////////////////////////////////////////////////
// Writing
//////////////////////////////////////////////////////////////////////////

  **
  ** Return a WebOutStream for writing content into this
  ** document. You should call 'close' on the stream when
  ** done writing to notify browser load is complete.
  **
  native WebOutStream out()

//////////////////////////////////////////////////////////////////////////
// Cookies
//////////////////////////////////////////////////////////////////////////

  **
  ** Map of cookie values keyed by cookie name.  The
  ** cookies map is readonly and case insensitive.
  **
  Str:Str cookies()
  {
    try
      return MimeType.parseParams(getCookiesStr).ro
    catch (Err e)
      e.trace
    return Str:Str[:].ro
  }

  **
  ** Add a cookie to this session.
  **
  Void addCookie(Cookie c)
  {
    addCookieStr(c.toStr)
  }

  private native Str getCookiesStr()
  private native Str addCookieStr(Str c)

}
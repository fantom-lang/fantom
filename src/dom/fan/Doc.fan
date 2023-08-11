//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

using graphics
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

  ** Get the head element.
  native Elem head()

  ** Get the body element.
  native Elem body()

  ** Get the currently focused element, or 'null' for none.
  native Elem? activeElem()

  **
  ** Get the element with this 'id', or 'null' if no
  ** element is found with this 'id'.
  **
  native Elem? elemById(Str id)

  **
  ** Get the topmost element at the specified coordinates
  ** (relative to the viewport), or 'null' if none found.
  **
  native Elem? elemFromPos(Point p)

  **
  ** Get a list of all elements at the specified coordinates
  ** (relative to the viewport). The elements are ordered from
  ** the topmost to the bottommost box of the viewport.
  **
  native Elem[] elemsFromPos(Point p)

  **
  ** Create a new element with the given tag name.  If the
  ** attrib map is specified, set the new elements attributes
  ** to the given values. Optionally a namespace for the
  ** element can be specified with 'ns'.
  **
  native Elem createElem(Str tagName, [Str:Str]? attrib := null, Uri? ns := null)

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

  **
  ** Invoke `querySelectorAll` but use given 'type' when wrapping
  ** native DOM nodes. See `Elem.fromNative` for more details.
  **
  @NoDoc native Elem[] querySelectorAllType(Str selectors, Type type)

  **
  ** Render the given image to an offscreen <canvas> element and
  ** export the contents to a data URI of type 'image/png'.
  **
  @NoDoc native Str exportPng(Elem img)

  **
  ** Render the given image to an offscreen <canvas> element and
  ** export the contents to a data URI of type 'image/jpeg'. The
  ** image quality can be configured by specifying a number
  ** between '0f' and '1f' for 'quality'.  If 'quality' is null
  ** the default value will be used.
  **
  @NoDoc native Str exportJpg(Elem img, Float? quality)

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  ** Attach an event handler for the given event on this document.
  ** Returns callback function instance.
  native Func onEvent(Str type, Bool useCapture, |Event e| handler)

  ** Remove the given event handler from this document.  If this
  ** handler was not registered, this method does nothing.
  native Void removeEvent(Str type, Bool useCapture, Func handler)

  ** When a HTML document has been switched to 'designMode', the document
  ** object exposes the 'exec' method which allows one to run commands to
  ** manipulate the contents of the editable region.
  **   - 'name': the command name to execute
  **   - 'defUi': flag to indicate if default user interface is shown
  **   - 'val': optional value for commands that take an argument
  native Bool exec(Str name, Bool defUi := false, Obj? val := null)

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
  native Void addCookie(Cookie c)

  private native Str getCookiesStr()

}
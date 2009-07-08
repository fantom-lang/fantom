//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

**
** Doc models the DOM document object.
**
@javascript
class Doc
{

  **
  ** Private ctor.
  **
  private new make() {}

  **
  ** Get the body element.
  **
  static native Elem body()

  **
  ** Get the element with this 'id', or 'null' if no
  ** element is found with this 'id'.
  **
  static native Elem? elem(Str id)

  **
  ** Create a new element with the given tag name.  If the
  ** attrib map is specified, set the new elements attributes
  ** to the given values.
  **
  static native Elem createElem(Str tagName, [Str:Str]? attrib := null)

}
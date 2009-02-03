//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
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
  static Elem body() { return Elem("") }

  **
  ** Get the element with this 'id', or 'null' if no
  ** element is found with this 'id'.
  **
  static Elem? elemById(Str id) { return null }

  **
  ** Create a new element with the given tag name.
  **
  static Elem createElem(Str tagName) { return Elem("") }

}
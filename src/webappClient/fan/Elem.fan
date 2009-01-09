//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

**
** Elem models a DOM element object.
**
@javascript
class Elem
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  internal new make() {}

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  **
  ** Get an attribute by name.  If not found return
  ** the specificed default value.
  **
  Obj? get(Str name, Obj? def := null) { return null }

  **
  ** Set an attribute to the given value.
  **
  Void set(Str name, Obj? val) {}

  **
  ** Get the tag name for this element.
  **
  Str tagName() { return "" }

  **
  ** The HTML markup contained in this element.
  **
  Str html

  **
  ** The value attribute for this element, or null if one
  ** does not exist.
  **
  Obj? value

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the parent Elem of this element, or null if
  ** this element has no parent.
  **
  Elem? parent() { return null }

  **
  ** Get the child nodes of this element.
  **
  Elem[] children() { return Elem[,] }

  **
  ** Get the previous sibling to this element, or null
  ** if this is the first element under its parent.
  **
  Elem? prev() { return null }

  **
  ** Get the next sibling to this element, or null if
  ** this is the last element under its parent.
  **
  Elem? next() { return null }

}
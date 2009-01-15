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

  new make(Obj obj) {}

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
// Size
//////////////////////////////////////////////////////////////////////////

  **
  ** The x position relative to the parent element in pixels.
  **
  Int x() { return 0 }

  **
  ** The y position relative to the parent element in pixels.
  **
  Int y() { return 0 }

  **
  ** The width of this element in pixels.
  **
  Int w() { return 0 }

  **
  ** The height of this element in pixels.
  **
  Int h() { return 0 }

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

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  **
  ** Return a list of all descendants for which c returns
  ** true.  Return an empty list if no element returns true.
  **
  Elem[] findAll(|Elem e->Bool| c) { return Elem[,] }

}
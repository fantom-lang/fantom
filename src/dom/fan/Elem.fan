//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

using gfx

**
** Elem models a DOM element object.
**
** See [pod doc]`pod-doc#elem` for details.
**
@Js
class Elem
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  private new make() {}

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the tag name for this element.
  **
  native Str tagName()

  **
  ** The id for this element.
  **
  native Str id

  **
  ** The name attribute for this element.
  **
  native Str name

  **
  ** The CSS class name(s) for this element.
  **
  native Str className

  **
  ** Return true if this element has the given CSS class name,
  ** or false if it does not.
  **
  native Bool hasClassName(Str className)

  **
  ** Add the given CSS class name to this element.  If this
  ** element already contains the given class name, then this
  ** method does nothing. Returns this.
  **
  native This addClassName(Str className)

  **
  ** Remove the given CSS class name to this element. If this
  ** element does not have the given class name, this method
  ** does nothing. Returns this.
  **
  native This removeClassName(Str className)

  **
  ** The HTML markup contained in this element.
  **
  native Str html

  **
  ** The value attribute for this element, or null if one
  ** does not exist.  This is typically only valid for form
  ** elements.
  **
  native Obj? val

  **
  ** The checked attribute for this element, or null if one
  ** does not exist.  This is typically only valid for some
  ** form elements.
  **
  native Bool? checked

  **
  ** The enabled attribute for this element, or null if one
  ** not applicable.  This is typically only valid for form
  ** elements.
  **
  native Bool? enabled

  **
  ** Get an attribute by name.  If not found return
  ** the specificed default value.
  **
  @Operator native Obj? get(Str name, Obj? def := null)

  **
  ** Set an attribute to the given value.
  **
  @Operator native Void set(Str name, Obj? val)

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  **
  ** Position of element relative to its parent in pixels.
  **
  native Point pos

  **
  ** Size of element in pixels.
  **
  native Size size

  **
  ** Position and size of this widget relative to its parent, both
  ** measured in pixels.
  **
  Rect bounds
  {
    get { return Rect.makePosSize(pos, size) }
    set { pos = it.pos; size = it.size }
  }

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the parent Elem of this element, or null if
  ** this element has no parent.
  **
  native Elem? parent()

  **
  ** Get the child nodes of this element.
  **
  native Elem[] children()

  **
  ** Get the first child node of this element, or null
  ** if this element has no children.
  **
  native Elem? first()

  **
  ** Get the previous sibling to this element, or null
  ** if this is the first element under its parent.
  **
  native Elem? prev()

  **
  ** Get the next sibling to this element, or null if
  ** this is the last element under its parent.
  **
  native Elem? next()

  **
  ** Add a new element as a child to this element. Return this.
  **
  native This add(Elem child)

  **
  ** Remove a child element from this element. Return this.
  **
  native This remove(Elem child)

//////////////////////////////////////////////////////////////////////////
// Focus
//////////////////////////////////////////////////////////////////////////

  **
  ** Request keyboard focus on this elem.
  **
  native Void focus()

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the first descendant for which c returns true.
  ** Return null if no element returns true.
  **
  native Elem? find(|Elem e->Bool| c)

  **
  ** Return a list of all descendants for which c returns
  ** true.  Return an empty list if no element returns true.
  **
  native Elem[] findAll(|Elem e->Bool| c)

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  **
  ** Attach an event handler to the given event on this element.
  **
  native Void onEvent(Str type, Bool useCapture, |Event e| handler)

}
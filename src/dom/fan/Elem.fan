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

  ** Create a new Elem in the current Doc.
  new make(Str tagName := "div") { _make(tagName) }

  private native Void _make(Str tagName)

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  ** Get the tag name for this element.
  native Str tagName()

  ** The id for this element.
  native Str id

  ** The name attribute for this element.
  native Str name

  ** The CSS class name(s) for this element.
  native Str className

  ** Return true if this element has the given CSS class name,
  ** or false if it does not.
  native Bool hasClass(Str name)

  ** Add the given CSS class name to this element.  If this
  ** element already contains the given class name, then this
  ** method does nothing. Returns this.
  native This addClass(Str name)

  ** Remove the given CSS class name to this element. If this
  ** element does not have the given class name, this method
  ** does nothing. Returns this.
  native This removeClass(Str name)

  ** Toggle the presence of the given CSS class name by adding
  ** or removing from this element.  Returns this.
  This toggleClass(Str name)
  {
    if (hasClass(name)) removeClass(name)
    else addClass(name)
    return this
  }

  // TODO FIXIT: remove
  @NoDoc @Deprecated { msg = "Use hasClass" } Bool hasClassName(Str n) { hasClass(n) }
  @NoDoc @Deprecated { msg = "Use addClass" } This addClassName(Str n) { addClass(n) }
  @NoDoc @Deprecated { msg = "Use removeClass" } This removeClassName(Str n) { removeClass(n) }

  ** Get the Style instance for this element.
  @NoDoc native Style style()

  ** Text content contained in this element.
  native Str text

  ** The HTML markup contained in this element.
  native Str html

  ** The value attribute for this element, or null if one
  ** does not exist.  This is typically only valid for form
  ** elements.
  native Obj? val

  ** The checked attribute for this element, or null if one
  ** does not exist.  This is typically only valid for some
  ** form elements.
  native Bool? checked

  ** The enabled attribute for this element, or null if one
  ** not applicable.  This is typically only valid for form
  ** elements.
  virtual native Bool? enabled

  ** Get an attribute by name.  If not found return
  ** the specificed default value.
  @Operator native Obj? get(Str name, Obj? def := null)

  ** Set an attribute to the given value.
  @Operator native Void set(Str name, Obj? val)

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  ** Position of element relative to its parent in pixels.
  native Point pos

  ** Position of element on the current doc.
  @NoDoc native Point posDoc()

  ** Size of element in pixels.
  native Size size

  ** Position and size of this widget relative to its parent, both
  ** measured in pixels.
  Rect bounds
  {
    get { return Rect.makePosSize(pos, size) }
    set { pos = it.pos; size = it.size }
  }

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  ** Get the parent Elem of this element, or null if
  ** this element has no parent.
  native Elem? parent()

  ** Get the child nodes of this element.
  native Elem[] children()

  ** Get the first child node of this element, or null
  ** if this element has no children.
  native Elem? first()

  ** Get the last child node of this element, or null
  ** if this element has no children.
  native Elem? last()

  ** Get the previous sibling to this element, or null
  ** if this is the first element under its parent.
  native Elem? prev()

  ** Get the next sibling to this element, or null if
  ** this is the last element under its parent.
  native Elem? next()

  ** Add a new element as a child to this element. Return this.
  @Operator virtual This add(Elem child)
  {
    addChild(child)
    onAdd(child)
    child.onParent(this)
    return this
  }

  ** Replace existing child node with a new child.  Returns this.
  virtual This replace(Elem oldChild, Elem newChild)
  {
    replaceChild(oldChild, newChild)
    oldChild.onUnparent(this)
    onRemove(oldChild)
    onAdd(newChild)
    newChild.onParent(this)
    return this
  }

  ** Remove a child element from this element. Return this.
  virtual This remove(Elem child)
  {
    removeChild(child)
    child.onUnparent(this)
    onRemove(child)
    return this
  }

  ** Add all elements to this element.  Returns this.
  This addAll(Elem[] elems)
  {
    elems.each |e| { add(e) }
    return this
  }

  ** Remove all children from this element. Returns this.
  This removeAll()
  {
    children.each |kid| { remove(kid) }
    return this
  }

  ** Add a new element as a child to this element.
  @NoDoc protected native Void addChild(Elem child)

  ** Replace an existing child element with new element.
  @NoDoc protected native Void replaceChild(Elem oldChild, Elem newChild)

  ** Remove a child element from this element.
  @NoDoc protected native Void removeChild(Elem child)

  ** Callback when this element is added to a parent.
  @NoDoc protected virtual Void onParent(Elem parent) {}

  ** Callback when this element is removed from a parent.
  @NoDoc protected virtual Void onUnparent(Elem parent) {}

  ** Callback when a child element is added.
  @NoDoc protected virtual Void onAdd(Elem child) {}

  ** Callback when a child element is removed.
  @NoDoc protected virtual Void onRemove(Elem child) {}

//////////////////////////////////////////////////////////////////////////
// Focus
//////////////////////////////////////////////////////////////////////////

  ** Request keyboard focus on this elem.
  native Void focus()

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  ** Return the first descendant for which c returns true.
  ** Return null if no element returns true.
  native Elem? find(|Elem e->Bool| c)

  ** Return a list of all descendants for which c returns
  ** true.  Return an empty list if no element returns true.
  native Elem[] findAll(|Elem e->Bool| c)

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  ** Attach an event handler to the given event on this element.
  native Void onEvent(Str type, Bool useCapture, |DomEvent e| handler)

//////////////////////////////////////////////////////////////////////////
// Animation
//////////////////////////////////////////////////////////////////////////

  ** Animate a set of CSS properties.
  @NoDoc Void animate(Str:Obj props, Duration dur, |Elem|? onComplete := null)
  {
    // force layout
    x := this.size

    // set transition
    style := this.style
    trans := props.keys.join(", ") |p| { "$p ${dur.toMillis}ms" }
    style["transition"] = trans

    // set props
    props.each |val,prop|
    {
      style[prop] = val
    }

    // invoke complete callback func
    if (onComplete != null)
      Win.cur.callLater(dur) |->| { onComplete(this) }
  }
}
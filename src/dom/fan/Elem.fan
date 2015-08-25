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

  ** Get the Style instance for this element.
  native Style style()

  ** Text content contained in this element.
  native Str text

  ** The HTML markup contained in this element.
  native Str html

  ** The enabled attribute for this element, or null if one
  ** not applicable.  This is typically only valid for form
  ** elements.
  virtual native Bool? enabled

  ** The draggable attribute for this element.
  native Bool draggable

  ** Get an attribute by name.  If not found return
  ** the specificed default value.
  @Operator native Obj? get(Str name, Obj? def := null)

  ** Set an attribute to the given value.
  @Operator native Void set(Str name, Obj? val)

  ** Get or set an attribute.
  override Obj? trap(Str name, Obj?[]? args := null)
  {
    if (args == null || args.isEmpty) return get(name)
    set(name, args.first)
    return null
  }

  // TODO FIXIT: remove
  @NoDoc @Deprecated { msg = "Use style.hasClass" } Bool hasClassName(Str n) { style.hasClass(n) }
  @NoDoc @Deprecated { msg = "Use style.addClass" } This addClassName(Str n) { style.addClass(n); return this }
  @NoDoc @Deprecated { msg = "Use style.removeClass" } This removeClassName(Str n) { style.removeClass(n); return this }
  @NoDoc @Deprecated { msg = "Use elem->name"    } Str name      { get { this->name  } set { this->name = it }}
  @NoDoc @Deprecated { msg = "Use elem->value"   } Obj? val      { get { this->value } set { this->value = it }}
  @NoDoc @Deprecated { msg = "Use elem->checked" } Bool? checked { get { this->checked } set { this->checked = it }}

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

  ** Top left scroll position of element.
  native Point scrollPos

  ** Scrollable size of element.
  native Size scrollSize()

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
  native Elem? firstChild()

  ** Get the last child node of this element, or null
  ** if this element has no children.
  native Elem? lastChild()

  ** Get the previous sibling to this element, or null
  ** if this is the first element under its parent.
  native Elem? prevSibling()

  ** Get the next sibling to this element, or null if
  ** this is the last element under its parent.
  native Elem? nextSibling()

  ** Returns the first element that is a descendant of this
  ** element on which it is invoked that matches the specified
  ** group of selectors.
  native Elem? querySelector(Str selectors)

  ** Returns a list of all elements descended from this element
  ** on which it is invoked that match the specified group of
  ** CSS selectors.
  native Elem[] querySelectorAll(Str selectors)

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

  // TODO FIXIT: remove
  @NoDoc @Deprecated { msg = "Use firstChild"  } Elem? first() { firstChild }
  @NoDoc @Deprecated { msg = "Use lastChild"   } Elem? last()  { lastChild }
  @NoDoc @Deprecated { msg = "Use prevSibling" } Elem? prev()  { prevSibling }
  @NoDoc @Deprecated { msg = "Use nextSibling" } Elem? next()  { nextSibling }
  @NoDoc @Deprecated { msg = "Use query" } native Elem? find(|Elem e->Bool| c)
  @NoDoc @Deprecated { msg = "Use queryAll" } native Elem[] findAll(|Elem e->Bool| c)

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  ** Request keyboard focus on this elem.
  virtual native Void focus()

  ** Attach an event handler to the given event on this element.
  native Void onEvent(Str type, Bool useCapture, |DomEvent e| handler)

//////////////////////////////////////////////////////////////////////////
// Animation
//////////////////////////////////////////////////////////////////////////

  ** Animate a set of CSS properties.
  Void animate(Str:Obj props, Duration dur, |Elem|? onComplete := null)
  {
    // force layout
    x := this.size

    // set transition
    style := this.style
    trans := props.keys.join(", ") |p|
    {
      style.toVendor(p).join(", ") |n| { "$n ${dur.toMillis}ms" }
    }
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
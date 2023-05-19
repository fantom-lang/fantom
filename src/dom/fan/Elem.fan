//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

using graphics

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

  ** Create a new Elem in the current Doc. Optionally
  ** a namespace can be specified with 'ns'.
  new make(Str tagName := "div", Uri? ns := null) { _make(tagName, ns) }

  private native Void _make(Str tagName, Uri? ns)

  **
  ** Create an `Elem` instance from a native JavaScript DOM object.
  ** The 'type' may be specified to create a subclass instance of
  ** Elem.  Note if the native instance has already been mapped
  ** to Fantom, the existing instance is returned and 'type' will
  ** have no effect.
  **
  static native Elem fromNative(Obj elem, Type type := Elem#)

  ** Create an `Elem` instance from a HTML string.
  ** This is equivlaent
  **   elem := Elem { it.html=html }.firstChild
  static Elem fromHtml(Str html)
  {
    Elem { it.html=html }.firstChild
  }

//////////////////////////////////////////////////////////////////////////
// Accessors
//////////////////////////////////////////////////////////////////////////

  ** The namespace URI of this element.
  native Uri ns()

  ** Get the tag name for this element.
  native Str tagName()

  ** The id for this element. Returns 'null' if id is not defined.
  Str? id
  {
    // use attr so we get 'null' if not defined
    get { attr("id") }
    set { setAttr("id", it) }
  }

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

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  ** Get 'name:value' map of all attributes.
  native Str:Str attrs()

  ** Get the given HTML attribute value for this element.
  ** Returns 'null' if attribute not defined.
  native Str? attr(Str name)

  ** Set the given HTML attribute value for this element. If 'val'
  ** is 'null' the attribute is removed (see `removeAttr`).
  ** Optionally a namespace can be specified with 'ns'.
  native This setAttr(Str name, Str? val, Uri? ns := null)

  ** Remove the given HTML attribute from this element.
  native This removeAttr(Str name)

  ** Convenience for `attr`.
  @Operator Obj? get(Str name) { attr(name) }

  ** Conveneince for `setAttr`.
  @Operator Void set(Str name, Str? val) { setAttr(name, val) }

//////////////////////////////////////////////////////////////////////////
// Properties
//////////////////////////////////////////////////////////////////////////

  ** Get the given DOM property value for this element.
  ** Returns 'null' if property does not exist.
  native Obj? prop(Str name)

  ** Set the given DOM properity value for this element.
  native This setProp(Str name, Obj? val)

//////////////////////////////////////////////////////////////////////////
// FFI
//////////////////////////////////////////////////////////////////////////

  **
  ** The 'trap' operator will behave slightly differently based
  ** on the namespace of the element.
  **
  ** For HTML elements, 'trap' works as a convenience for `prop`
  ** and `setProp`:
  **
  **   div := Elem("div")
  **   div->tabIndex = 0   // equivalent to div.setProp("tabIndex", 0)
  **
  ** For SVG elements (where `ns` is '`http://www.w3.org/2000/svg`'),
  ** 'trap' routes to `attr` and `setAttr`:
  **
  **   svg := Svg.line(0, 0, 10, 10)
  **   svg->x1 = 5      // equivalent to svg.setAttr("x1", "5")
  **   svg->y1 = 5      // equivalent to svg.setAttr("y1", "5")
  **   svg->x2 == "10"  // equivalent to svg.attr("x2")
  **
  native override Obj? trap(Str name, Obj?[]? args := null)

  ** Invoke the given native DOM function with optional arguments.
  native Obj? invoke(Str name, Obj?[]? args := null)

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  ** Position of element relative to its parent in pixels.
  native Point pos

  ** Position of element relative to the whole document.
  native Point pagePos()

  ** Given a page position, return 'p' relative to this element.
  Point relPos(Point p)
  {
    pp := this.pagePos
    return Point(p.x - pp.x, p.y - pp.y)
  }

  ** Size of element in pixels.
  native Size size

  // ** Position and size of this widget relative to its parent, both
  // ** measured in pixels.
  // Rect bounds
  // {
  //   // TODO
  //   get { return Rect(pos.x, pos.y, size.w, size.h) } //.makePosSize(pos, size) }
  //   set { pos = Pos(it.pos.x, it.pos.y) /*it.pos*/; size = it.size }
  // }

  ** Top left scroll position of element.
  native Point scrollPos

  ** Scrollable size of element.
  native Size scrollSize()

  ** Scroll parent container so this Elem is visible to user. If
  ** 'alignToTop' is 'true' (the default value), the top of Elem
  ** is aligned to top of the visible area.  If 'false', the bottom
  ** of Elem is aligned to bottom of the visible area.
  native This scrollIntoView(Bool alignToTop := true)

  ** Paint a '<canvas>' element.  The given callback is invoked
  ** with a graphics context to perform the rendering operation.
  Void renderCanvas(|Graphics| f) { CanvasGraphics.render(this, f) }

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  ** Get the parent Elem of this element, or null if
  ** this element has no parent.
  native Elem? parent()

  ** Return 'true' if `children` is non-zero, 'false' otherwise.
  native Bool hasChildren()

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

  ** Return 'true' if given element is a descendant of this
  ** node, or 'false' if not.
  native Bool containsChild(Elem elem)

  ** Returns the first element that is a descendant of this
  ** element on which it is invoked that matches the specified
  ** group of selectors.
  native Elem? querySelector(Str selectors)

  ** Returns a list of all elements descended from this element
  ** on which it is invoked that match the specified group of
  ** CSS selectors.
  native Elem[] querySelectorAll(Str selectors)

  ** Traverses this element and its parents (heading toward the
  ** document root) until it finds a node that matches the
  ** specified CSS selector.  Returns 'null' if none found.
  native Elem? closest(Str selectors)

  ** Return a duplicate of this node.
  native Elem clone(Bool deep := true)

  ** Add a new element as a child to this element. Return this.
  @Operator virtual This add(Elem child)
  {
    addChild(child)
    onAdd(child)
    child.onParent(this)
    return this
  }

  ** Insert a new element as a child to this element before the
  ** specified reference element.  The reference element must
  ** be a child of this element. Returns this.
  virtual This insertBefore(Elem child, Elem ref)
  {
    insertChildBefore(child, ref)
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

  ** Insert a new element as a child to this element before given node.
  @NoDoc protected native Void insertChildBefore(Elem child, Elem ref)

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
// Events
//////////////////////////////////////////////////////////////////////////

  ** Return true if this elem has focus.
  virtual native Bool hasFocus()

  ** Request keyboard focus on this elem.
  virtual native Void focus()

  ** Remove focus from this elem.
  virtual native Void blur()

  ** Attach an event handler for the given event on this element.
  ** Returns callback function instance.
  native Func onEvent(Str type, Bool useCapture, |Event e| handler)

  ** Remove the given event handler from this element.  If this
  ** handler was not registered, this method does nothing.
  native Void removeEvent(Str type, Bool useCapture, Func handler)

//////////////////////////////////////////////////////////////////////////
// Animation
//////////////////////////////////////////////////////////////////////////

  **
  ** Transition a set of CSS properties.
  **
  **   transition(["opacity": "0.5"], null, 1sec) { echo("done!") }
  **   transition(["opacity": "0.5"], ["transition-delay": 500ms], 1sec) { echo("done!") }
  **
  Void transition(Str:Obj props, [Str:Obj]? opts, Duration dur, |Elem|? onComplete := null)
  {
    // force layout
    x := this.size

    // set options
    style := this.style
    if (opts != null) style.setAll(opts)

    // set props and duration
    style->transitionDuration = dur
    style->transitionProperty = Style.toVendors(props.keys).join(", ")

    // set propery targets
    props.each |val,prop| { style[prop] = val }

    // invoke complete callback func
    if (onComplete != null)
      Win.cur.setTimeout(dur) { onComplete(this) }
  }

  **
  ** Start an animation on this element using the given key frames.
  **
  **   frames := KeyFrames([
  **     KeyFrame("0%",   ["transform": "scale(1)"]),
  **     KeyFrame("50%",  ["transform": "scale(1.1)"]),
  **     KeyFrame("100%", ["transform": "scale(1)"]),
  **   ])
  **
  **   animate(frames, null, 5sec)
  **   animate(frames, ["animation-iteration-count":"infinite"], 1sec)
  **
  Void animateStart(KeyFrames frames, [Str:Obj]? opts, Duration dur)
  {
    if (opts != null) style.setAll(opts)
    style->animationName = frames.name
    style->animationDuration = dur
  }

  ** Stop the current animation on this element, or do nothing
  ** if no animation in progress.
  Void animateStop()
  {
    style->animation = null
  }
}
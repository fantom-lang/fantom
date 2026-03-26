//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    8 Jan 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//    8 Jul 2009  Andy Frank  Split webappClient into sys/dom
//   19 May 2017  Andy Frank  Formalize attr vs prop
//   10 Jun 2023  Kiera O'Flynn  Refactor to ES
//

class ElemPeer extends sys.Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(self)
  {
    super();
    this.#pos  = graphics.Point.defVal();
    this.#size = graphics.Size.defVal();
  }

  #pos;
  #size;
  #svg;
  #style;
  #scrollPos;
  #scrollSize;

  _make(self, tagName, ns)
  {
    // short-circut for wrap()
    if (tagName === undefined) return;

    const doc  = Win.cur().doc().peer.doc;
    const elem = ns
      ? doc.createElementNS(ns.toStr(), tagName)
      : doc.createElement(tagName);
    this.elem = elem;
    this.elem._fanElem = self;

    // optimziation hooks for non-html namespaces
    if (ns)
    {
      if (ns.toStr() == "http://www.w3.org/2000/svg") this.#svg = true;
    }
  }

  static fromNative = function(obj, type)
  {
    if (obj instanceof Elem) return obj;
    return ElemPeer.wrap(obj, type.make());
  }

  /*
   * Native only method to wrap an existing DOM node.  If this node
   * has already been wrapped by an Elem instance, return the
   * existing instance.
   */
  static wrap = function(elem, fanElem)
  {
    if (!elem) throw sys.ArgErr.make("elem is null")

    if (elem._fanElem != undefined)
      return elem._fanElem;

    if (fanElem && !(fanElem instanceof Elem))
      throw sys.ArgErr.make("Type does not subclass Elem: " + fanElem);

    const x = fanElem || Elem.make();
    x.peer.elem = elem;
    elem._fanElem = x;
    return x;
  }

//////////////////////////////////////////////////////////////////////////
// Accessors
//////////////////////////////////////////////////////////////////////////

  ns(self)
  {
    const ns = this.elem.namespaceURI;
    return sys.Uri.fromStr(ns);
  }

  tagName(self) { return sys.Str.lower(this.elem.nodeName); }

  style(self)
  {
    if (!this.#style)
    {
      this.#style = Style.make();
      this.#style.peer.elem  = this.elem;
      this.#style.peer.style = this.elem.style;

      // polyfill for IE11/Edge with SVG nodes
      if (this.#svg && !this.elem.classList)
        this.elem.classList = new StylePeer.polyfillClassList(this.elem);
    }

    return this.#style;
  }

  text(self, it)
  {
    if (it === undefined) return this.elem.textContent;
    else this.elem.textContent = it;
  }

  html(self, it)
  {
    if (it === undefined) return this.elem.innerHTML;
    this.elem.innerHTML = it;
  }

  enabled(self, it)
  {
    if (this.elem.disabled === undefined) return null;
    else if (it === undefined) return !this.elem.disabled;
    else this.elem.disabled = !it;
  }

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  attrs(self)
  {
    const map = sys.Map.make(sys.Str.type$, sys.Str.type$);
    map.caseInsensitive(true);
    const attrs = this.elem.attributes;
    for(let i=0; i<attrs.length; i++)
    {
      map.set(attrs[i].name, attrs[i].value);
    }
    return map;
  }

  attr(self, name)
  {
    return this.elem.getAttribute(name);
  }

  setAttr(self, name, val, ns)
  {
    if (val == null)
      this.elem.removeAttribute(name);
    else
    {
      if (ns == null)
        this.elem.setAttribute(name, val);
      else
        this.elem.setAttributeNS(ns.toStr(), name, val);
    }
    return self;
  }

  removeAttr(self, name)
  {
    this.elem.removeAttribute(name);
    return self;
  }

//////////////////////////////////////////////////////////////////////////
// Properties
//////////////////////////////////////////////////////////////////////////

  prop(self, name)
  {
    if (ElemPeer.propHooks[name])
      return ElemPeer.propHooks[name](this);

    return this.elem[name];
  }

  setProp(self, name, val)
  {
    this.elem[name] = val;
    return self;
  }

  static propHooks = {
    contentWindow: function(peer)
    {
      const v = peer.elem.contentWindow;
      if (v == null) return null;
      const w = Win.make();
      w.peer.win = v;
      return w
    },
    files: function(peer)
    {
      const f = peer.elem.files;
      if (f == null) return null;
      const list = sys.List.make(DomFile.type$);
      for (let i=0; i<f.length; i++) list.add(DomFilePeer.wrap(f[i]));
      return list;
    }
  }

//////////////////////////////////////////////////////////////////////////
// FFI
//////////////////////////////////////////////////////////////////////////

  trap(self, name, args)
  {
    if (this.#svg) return Svg.doTrap(self, name, args);

    if (args == null || args.isEmpty()) return this.prop(self, name);
    this.setProp(self, name, args.first());
    return null;
  }

  invoke(self, name, args)
  {
    const f = this.elem[name];

    // verify propery is actually a function
    if (typeof f != 'function')
      throw sys.ArgErr.make(name + " is not a function");

    // map fantom objects to js natives
    let arglist = null;
    if (args != null)
    {
      // TODO :)
      arglist = [];
      for (let i=0; i<args.size(); i++)
        arglist.push(args.get(i));
    }

    return f.apply(this.elem, arglist);
  }

  //////////////////////////////////////////////////////////////////////////
  // Layout
  //////////////////////////////////////////////////////////////////////////

  pos(self, it)
  {
    if (it === undefined)
    {
      const x = this.elem.offsetLeft;
      const y = this.elem.offsetTop;
      if (this.#pos.x() != x || this.#pos.y() != y)
        this.#pos = graphics.Point.makeInt(x, y);
      return this.#pos;
    }

    this.#pos = graphics.Point.makeInt(it.x(), it.y());
    this.elem.style.left = it.x() + "px";
    this.elem.style.top  = it.y() + "px";
  }

  pagePos(self)
  {
    const r = this.elem.getBoundingClientRect();
    const x = Math.round(r.left);
    const y = Math.round(r.top);
    return graphics.Point.makeInt(x, y);
  }

  size(self, it)
  {
    if (it === undefined)
    {
      const w = this.elem.offsetWidth  || 0;
      const h = this.elem.offsetHeight || 0;
      if (this.#size.w() != w || this.#size.h() != h)
        this.#size = graphics.Size.makeInt(w, h);
      return this.#size;
    }

    this.#size = graphics.Size.makeInt(it.w(), it.h());
    this.elem.style.width  = it.w() + "px";
    this.elem.style.height = it.h() + "px";
  }

  scrollPos(self, it)
  {
    if (it === undefined)
    {
      const x = this.elem.scrollLeft;
      const y = this.elem.scrollTop;
      if (!this.#scrollPos || this.#scrollPos.x() != x || this.#scrollPos.y() != y)
        this.#scrollPos = graphics.Point.makeInt(x, y);
      return this.#scrollPos;
    }

    this.#scrollPos = graphics.Point.makeInt(it.x(), it.y());
    this.elem.scrollLeft = it.x();
    this.elem.scrollTop  = it.y();
  }

  scrollSize(self)
  {
    const w = this.elem.scrollWidth;
    const h = this.elem.scrollHeight;
    if (!this.#scrollSize || this.#scrollSize.w() != w || this.#size.h() != h)
      this.#scrollSize = graphics.Size.makeInt(w, h);
    return this.#scrollSize;
  }

  scrollIntoView(self, alignToTop)
  {
    this.elem.scrollIntoView(alignToTop);
  }

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  parent(self)
  {
    if (this.elem.nodeName == "BODY") return null;
    const parent = this.elem.parentNode;
    if (parent == null) return null;
    return ElemPeer.wrap(parent);
  }

  hasChildren(self)
  {
    return this.elem.childElementCount > 0;
  }

  children(self)
  {
    const list = new Array();
    const kids = this.elem.childNodes;
    for (let i=0; i<kids.length; i++)
      if (kids[i].nodeType == 1)
        list.push(ElemPeer.wrap(kids[i]));
    return sys.List.make(Elem.type$, list);
  }

  firstChild(self)
  {
    const kids = this.elem.childNodes;
    for (let i=0; i<kids.length; i++)
      if (kids[i].nodeType == 1)
        return ElemPeer.wrap(kids[i]);
    return null;
  }

  lastChild(self)
  {
    const kids = this.elem.childNodes;
    for (let i=kids.length-1; i>=0; i--)
      if (kids[i].nodeType == 1)
        return ElemPeer.wrap(kids[i]);
    return null;
  }

  prevSibling(self)
  {
    let sib = this.elem.previousSibling;
    while (sib != null && sib.nodeType != 1)
      sib = sib.previousSibling;
    if (sib == null) return null;
    return ElemPeer.wrap(sib);
  }

  nextSibling(self)
  {
    let sib = this.elem.nextSibling;
    while (sib != null && sib.nodeType != 1)
      sib = sib.nextSibling;
    if (sib == null) return null;
    return ElemPeer.wrap(sib);
  }

  containsChild(self, test)
  {
    return this.elem.contains(test.peer.elem);
  }

  querySelector(self, selectors)
  {
    const elem = this.elem.querySelector(selectors);
    if (elem == null) return null;
    return ElemPeer.wrap(elem);
  }

  querySelectorAll(self, selectors)
  {
    const list  = sys.List.make(Elem.type$);
    const elems = this.elem.querySelectorAll(selectors);
    for (let i=0; i<elems.length; i++)
      list.add(ElemPeer.wrap(elems[i]));
    return list;
  }

  closest(self, selectors)
  {
    const elem = this.elem.closest(selectors);
    if (elem == null) return null;
    return ElemPeer.wrap(elem);
  }

  clone(self, deep)
  {
    const clone = this.elem.cloneNode(deep);
    return ElemPeer.wrap(clone);
  }

  addChild(self, child)
  {
    this.elem.appendChild(child.peer.elem);
  }

  insertChildBefore(self, child, ref)
  {
    this.elem.insertBefore(child.peer.elem, ref.peer.elem);
  }

  replaceChild(self, oldChild, newChild)
  {
    this.elem.replaceChild(newChild.peer.elem, oldChild.peer.elem);
  }

  removeChild(self, child)
  {
    this.elem.removeChild(child.peer.elem);
  }

  hasFocus(self)
  {
    return this.elem === document.activeElement;
  }

  focus(self)
  {
    // IE throws err if element is not visible, so we need
    // to wrap in a try block
    try { this.elem.focus(); }
    catch (err) {} // ignore
  }

  blur(self)
  {
    this.elem.blur();
  }

  find(self, f)
  {
    const kids = this.children(self);
    for (let i=0; i<kids.size(); i++)
    {
      let kid = kids[i];
      if (f(kid)) return kid;
      kid = kid.find(f);
      if (kid != null) return kid;
    }
    return null;
  }

  findAll(self, f, acc)
  {
    if (acc == null) acc = new Array();
    const kids = this.children(self);
    for (let i=0; i<kids.size(); i++)
    {
      const kid = kids[i];
      if (f(kid)) acc.push(kid);
      kid.findAll(f, acc);
    }
    return acc;
  }

  onEvent(self, type, useCapture, handler)
  {
    handler.$func = function(e) { handler(EventPeer.make(e)); }
    this.elem.addEventListener(type, handler.$func, useCapture);
    return handler;
  }

  removeEvent(self, type, useCapture, handler)
  {
    if (handler.$func)
      this.elem.removeEventListener(type, handler.$func, useCapture);
  }

  toStr(self)
  {
    const name = this.elem.nodeName;
    const type = this.elem.type;
    const id   = this.elem.id;
    let str    = "<" + sys.Str.lower(name);
    if (type != null && type.length > 0) str += " type='" + type + "'";
    if (id != null && id.length > 0) str += " id='" + id + "'"
    str += ">";
    return str;
  }
}
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

fan.dom.ElemPeer = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.dom.ElemPeer.prototype.$ctor = function(self)
{
  this.m_pos  = fan.dom.Pos.m_defVal;
  this.m_size = fan.gfx.Size.m_defVal;
}

fan.dom.ElemPeer.prototype._make = function(self, tagName)
{
  // short-circut for wrap()
  if (tagName === undefined) return;

  var doc  = fan.dom.Win.cur().doc().peer.doc;
  var elem = doc.createElement(tagName);
  this.elem = elem;
  this.elem._fanElem = self;
}

/*
 * Native only method to wrap an existing DOM node.  If this node
 * has already been wrapped by an Elem instance, return the
 * existing instance.
 */
fan.dom.ElemPeer.wrap = function(elem)
{
  if (elem == null) throw fan.sys.ArgErr.make("elem is null")

  if (elem._fanElem != undefined)
    return elem._fanElem;

  var x = fan.dom.Elem.make();
  x.peer.elem = elem;
  elem._fanElem = x;
  return x;
}

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

fan.dom.ElemPeer.prototype.tagName = function(self) { return fan.sys.Str.lower(this.elem.nodeName); }

fan.dom.ElemPeer.prototype.id  = function(self) { return this.elem.id; }
fan.dom.ElemPeer.prototype.id$ = function(self, val) { return this.elem.id = val; }

fan.dom.ElemPeer.prototype.style = function(self)
{
  if (this.$style == null)
  {
    this.$style = fan.dom.Style.make();
    this.$style.peer.elem  = this.elem;
    this.$style.peer.style = this.elem.style;
  }
  return this.$style;
}

fan.dom.ElemPeer.prototype.text  = function(self) { return this.elem.textContent; }
fan.dom.ElemPeer.prototype.text$ = function(self, val) { this.elem.textContent = val; }

fan.dom.ElemPeer.prototype.html  = function(self) { return this.elem.innerHTML; }
fan.dom.ElemPeer.prototype.html$ = function(self, val) { this.elem.innerHTML = val; }

fan.dom.ElemPeer.prototype.enabled  = function(self)
{
  if (this.elem.disabled === undefined) return null;
  return !this.elem.disabled;
}

fan.dom.ElemPeer.prototype.enabled$ = function(self, val)
{
  if (this.elem.disabled === undefined) return;
  this.elem.disabled = !val;
}

fan.dom.ElemPeer.prototype.draggable  = function(self) { return this.elem.draggable; }
fan.dom.ElemPeer.prototype.draggable$ = function(self, val) { this.elem.draggable = val; }

fan.dom.ElemPeer.prototype.get = function(self, name, def)
{
  if (name == "id")      return this.id(self);
  if (name == "name")    return this.elem.name;
  if (name == "class")   return this.elem.className; // TODO: route to Style?
  if (name == "style")   return this.style(self);
  if (name == "value")   return this.elem.value;
  if (name == "checked") return this.elem.checked;

  var val = this.elem[name];
  if (val == null) val = this.elem.getAttribute(name);

  if (val != null) return val;
  if (def != null) return def;
  return null;
}

fan.dom.ElemPeer.prototype.set = function(self, name, val)
{
  if (name == "id")           this.id$(self, val);
  else if (name == "name")    this.elem.name = val;
  else if (name == "class")   this.elem.className = val;  // TODO: route to Style?
  else if (name == "value")   this.elem.value = val;
  else if (name == "checked") this.elem.checked = val;
  else if (this.elem[name])   this.elem[name] = val;
  else this.elem.setAttribute(name, val);
}

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

fan.dom.ElemPeer.prototype.pos = function(self)
{
  var x = this.elem.offsetLeft;
  var y = this.elem.offsetTop;
  if (this.m_pos.m_x != x || this.m_pos.m_y != y)
    this.m_pos = fan.dom.Pos.make(x, y);
  return this.m_pos;
}

fan.dom.ElemPeer.prototype.pos$ = function(self, val)
{
  this.m_pos = fan.dom.Pos.make(val.m_x, val.m_y);
  this.elem.style.left = val.m_x + "px";
  this.elem.style.top  = val.m_y + "px";
}

fan.dom.ElemPeer.prototype.pagePos = function(self)
{
  var r = this.elem.getBoundingClientRect();
  var x = Math.round(r.left);
  var y = Math.round(r.top);
  return fan.dom.Pos.make(x, y);
}

fan.dom.ElemPeer.prototype.size = function(self)
{
  var w = this.elem.offsetWidth;
  var h = this.elem.offsetHeight;
  if (this.m_size.m_w != w || this.m_size.m_h != h)
    this.m_size = fan.gfx.Size.make(w, h);
  return this.m_size;
}

fan.dom.ElemPeer.prototype.size$ = function(self, val)
{
  this.m_size = fan.gfx.Size.make(val.m_w, val.m_h);
  this.elem.style.width  = val.m_w + "px";
  this.elem.style.height = val.m_h + "px";
}

fan.dom.ElemPeer.prototype.scrollPos = function(self)
{
  var x = this.elem.scrollLeft;
  var y = this.elem.scrollTop;
  if (!this.m_scrollPos || this.m_scrollPos.m_x != x || this.m_scrollPos.m_y != y)
    this.m_scrollPos = fan.dom.Pos.make(x, y);
  return this.m_scrollPos;
}

fan.dom.ElemPeer.prototype.scrollPos$ = function(self, val)
{
  this.m_scrollPos = fan.dom.Pos.make(val.m_x, val.m_y);
  this.elem.scrollLeft = val.m_x;
  this.elem.scrollTop  = val.m_y;
}

fan.dom.ElemPeer.prototype.scrollSize = function(self)
{
  var w = this.elem.scrollWidth;
  var h = this.elem.scrollHeight;
  if (!this.m_scrollSize || this.m_scrollSize.m_w != w || this.m_size.m_h != h)
    this.m_scrollSize = fan.gfx.Size.make(w, h);
  return this.m_scrollSize;
}

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

fan.dom.ElemPeer.prototype.parent = function(self)
{
  if (this.elem.nodeName == "BODY") return null;
  var parent = this.elem.parentNode;
  if (parent == null) return null;
  return fan.dom.ElemPeer.wrap(parent);
}

fan.dom.ElemPeer.prototype.children = function(self)
{
  var list = new Array();
  var kids = this.elem.childNodes;
  for (var i=0; i<kids.length; i++)
    if (kids[i].nodeType == 1)
      list.push(fan.dom.ElemPeer.wrap(kids[i]));
  return fan.sys.List.make(fan.dom.Elem.$type, list);
}

fan.dom.ElemPeer.prototype.firstChild = function(self)
{
  var kids = this.elem.childNodes;
  for (var i=0; i<kids.length; i++)
    if (kids[i].nodeType == 1)
      return fan.dom.ElemPeer.wrap(kids[i]);
  return null;
}

fan.dom.ElemPeer.prototype.lastChild = function(self)
{
  var kids = this.elem.childNodes;
  for (var i=kids.length-1; i>=0; i--)
    if (kids[i].nodeType == 1)
      return fan.dom.ElemPeer.wrap(kids[i]);
  return null;
}

fan.dom.ElemPeer.prototype.prevSibling = function(self)
{
  var sib = this.elem.previousSibling;
  while (sib != null && sib.nodeType != 1)
    sib = sib.previousSibling;
  if (sib == null) return null;
  return fan.dom.ElemPeer.wrap(sib);
}

fan.dom.ElemPeer.prototype.nextSibling = function(self)
{
  var sib = this.elem.nextSibling;
  while (sib != null && sib.nodeType != 1)
    sib = sib.nextSibling;
  if (sib == null) return null;
  return fan.dom.ElemPeer.wrap(sib);
}

fan.dom.ElemPeer.prototype.containsChild = function(self, test)
{
  return this.elem.contains(test.peer.elem);
}

fan.dom.ElemPeer.prototype.querySelector = function(self, selectors)
{
  var elem = this.elem.querySelector(selectors);
  if (elem == null) return null;
  return fan.dom.ElemPeer.wrap(elem);
}

fan.dom.ElemPeer.prototype.querySelectorAll = function(self, selectors)
{
  var list  = fan.sys.List.make(fan.dom.Elem.$type);
  var elems = this.elem.querySelectorAll(selectors);
  for (var i=0; i<elems.length; i++)
    list.add(fan.dom.ElemPeer.wrap(elems[i]));
  return list;
}

fan.dom.ElemPeer.prototype.addChild = function(self, child)
{
  this.elem.appendChild(child.peer.elem);
}

fan.dom.ElemPeer.prototype.insertChildBefore = function(self, child, ref)
{
  this.elem.insertBefore(child.peer.elem, ref.peer.elem);
}

fan.dom.ElemPeer.prototype.replaceChild = function(self, oldChild, newChild)
{
  this.elem.replaceChild(newChild.peer.elem, oldChild.peer.elem);
}

fan.dom.ElemPeer.prototype.removeChild = function(self, child)
{
  this.elem.removeChild(child.peer.elem);
}

fan.dom.ElemPeer.prototype.hasFocus = function(self)
{
  return this.elem === document.activeElement;
}

fan.dom.ElemPeer.prototype.focus = function(self)
{
  // IE throws err if element is not visible, so we need
  // to wrap in a try block
  try { this.elem.focus(); }
  catch (err) {} // ignore
}

fan.dom.ElemPeer.prototype.blur = function(self)
{
  this.elem.blur();
}

fan.dom.ElemPeer.prototype.find = function(self, f)
{
  var kids = this.children(self);
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    if (f.call(kid)) return kid;
    kid = kid.find(f);
    if (kid != null) return kid;
  }
  return null;
}

fan.dom.ElemPeer.prototype.findAll = function(self, f, acc)
{
  if (acc == null) acc = new Array();
  var kids = this.children(self);
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    if (f.call(kid)) acc.push(kid);
    kid.findAll(f, acc);
  }
  return acc;
}

fan.dom.ElemPeer.prototype.onEvent = function(self, type, useCapture, handler)
{
  handler.$func = function(e) { handler.call(fan.dom.EventPeer.make(e)); }
  this.elem.addEventListener(type, handler.$func, useCapture);
  return handler;
}

fan.dom.ElemPeer.prototype.removeEvent = function(self, type, useCapture, handler)
{
  if (handler.$func)
    this.elem.removeEventListener(type, handler, useCapture);
}

fan.dom.ElemPeer.prototype.toStr = function(self)
{
  var name = this.elem.nodeName;
  var type = this.elem.type;
  var id   = this.elem.id;
  var str  = "<" + fan.sys.Str.lower(name);
  if (type != null && type.length > 0) str += " type='" + type + "'";
  if (id != null && id.length > 0) str += " id='" + id + "'"
  str += ">";
  return str;
}

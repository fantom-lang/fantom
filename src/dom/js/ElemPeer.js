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
  this.m_pos  = fan.gfx.Point.m_defVal;
  this.m_size = fan.gfx.Size.m_defVal;
}

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

fan.dom.ElemPeer.prototype.tagName = function(self) { return fan.sys.Str.lower(this.elem.nodeName); }

fan.dom.ElemPeer.prototype.id  = function(self) { return this.elem.id; }
fan.dom.ElemPeer.prototype.id$ = function(self, val) { return this.elem.id = val; }

fan.dom.ElemPeer.prototype.name  = function(self) { return this.elem.name; }
fan.dom.ElemPeer.prototype.name$ = function(self, val) { return this.elem.name = val; }

fan.dom.ElemPeer.prototype.className  = function(self) { return this.elem.className; }
fan.dom.ElemPeer.prototype.className$ = function(self, val) { return this.elem.className = val; }

fan.dom.ElemPeer.prototype.hasClassName = function(self, className)
{
  var arr = this.elem.className.split(" ");
  for (var i=0; i<arr.length; i++)
    if (arr[i] == className)
      return true;
  return false;
}

fan.dom.ElemPeer.prototype.addClassName = function(self, className)
{
  if (!this.hasClassName(self, className))
    this.elem.className += " " + className;
  return this;
}

fan.dom.ElemPeer.prototype.removeClassName = function(self, className)
{
  var arr = this.elem.className.split(" ");
  for (var i=0; i<arr.length; i++)
    if (arr[i] == className)
    {
      arr.splice(i, 1);
      break;
    }
  this.elem.className = arr.join(" ");
  return this;
}

fan.dom.ElemPeer.prototype.html  = function(self) { return this.elem.innerHTML; }
fan.dom.ElemPeer.prototype.html$ = function(self, val) { this.elem.innerHTML = val; }

fan.dom.ElemPeer.prototype.val  = function(self) { return this.elem.value; }
fan.dom.ElemPeer.prototype.val$ = function(self, val) { this.elem.value = val; }

fan.dom.ElemPeer.prototype.checked  = function(self) { return this.elem.checked; }
fan.dom.ElemPeer.prototype.checked$ = function(self, val) { this.elem.checked = val; }

fan.dom.ElemPeer.prototype.enabled  = function(self) { return !this.elem.disabled; }
fan.dom.ElemPeer.prototype.enabled$ = function(self, val) { this.elem.disabled = !val; }

fan.dom.ElemPeer.prototype.get = function(self, name, def)
{
  if (name == "id")      return this.id(self);
  if (name == "name")    return this.name(self);
  if (name == "class")   return this.className(self);
  if (name == "style")   return this.style(self);
  if (name == "value")   return this.val(self);
  if (name == "checked") return this.checked(self);

  var val = this.elem[name];
  if (val != null) return val;
  if (def != null) return def;
  return null;
}

fan.dom.ElemPeer.prototype.set = function(self, name, val)
{
  if (name == "id")           this.id$(self, val);
  else if (name == "name")    this.name$(self, val);
  else if (name == "class")   this.className$(self, val);
  else if (name == "value")   this.val$(self, val);
  else if (name == "checked") this.checked$(self, val);
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
    this.m_pos = fan.gfx.Point.make(x, y);
  return this.m_pos;
}

fan.dom.ElemPeer.prototype.pos$ = function(self, val)
{
  this.m_pos = fan.gfx.Point.make(val.m_x, val.m_y);
  this.elem.style.left = val.m_x + "px";
  this.elem.style.top  = val.m_y + "px";
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

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

fan.dom.ElemPeer.prototype.parent = function(self)
{
  var parent = this.elem.parentNode;
  if (parent == null) return null;
  return fan.dom.ElemPeer.make(parent);
}

fan.dom.ElemPeer.prototype.children = function(self)
{
  var list = new Array();
  var kids = this.elem.childNodes;
  for (var i=0; i<kids.length; i++)
    if (kids[i].nodeType == 1)
      list.push(fan.dom.ElemPeer.make(kids[i]));
  return fan.sys.List.make(fan.dom.Elem.$type, list);
}

fan.dom.ElemPeer.prototype.first = function(self)
{
  var kids = this.elem.childNodes;
  for (var i=0; i<kids.length; i++)
    if (kids[i].nodeType == 1)
      return fan.dom.ElemPeer.make(kids[i]);
  return null;
}

fan.dom.ElemPeer.prototype.prev = function(self)
{
  var sib = this.elem.previousSibling;
  while (sib != null && sib.nodeType != 1)
    sib = sib.previousSibling;
  if (sib == null) return null;
  return fan.dom.ElemPeer.make(sib);
}

fan.dom.ElemPeer.prototype.next = function(self)
{
  var sib = this.elem.nextSibling;
  while (sib != null && sib.nodeType != 1)
    sib = sib.nextSibling;
  if (sib == null) return null;
  return fan.dom.ElemPeer.make(sib);
}

fan.dom.ElemPeer.prototype.add = function(self, child)
{
  this.elem.appendChild(child.elem);
  return this;
}

fan.dom.ElemPeer.prototype.remove = function(self, child)
{
  this.elem.removeChild(child.elem);
  return this;
}

fan.dom.ElemPeer.prototype.focus = function(self)
{
  // IE throws err if element is not visible, so we need
  // to wrap in a try block
  try { this.elem.focus(); }
  catch (err) {} // ignore
}

fan.dom.ElemPeer.prototype.find = function(self, f)
{
  var kids = this.children(self);
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    if (f.call(kid)) return kid;
    kid = kid.find(func);
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
    kid.findAll(func, acc);
  }
  return acc;
}

fan.dom.ElemPeer.prototype.onEvent = function(self, type, useCapture, handler)
{
  if (this.elem.addEventListener)
  {
    this.elem.addEventListener(type, function(e) {
      handler.call(fan.dom.EventPeer.make(e));
    }, useCapture);
  }
  else
  {
    this.elem.attachEvent('on'+type, function(e) {
      handler.call(fan.dom.EventPeer.make(e));
    });
  }
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

fan.dom.ElemPeer.make = function(elem)
{
  if (elem == null) throw fan.sys.ArgErr.make("elem is null")

  if (elem._fanElem != undefined)
    return elem._fanElem;

  var x = fan.dom.Elem.make();
  x.peer.elem = elem;
  elem._fanElem = x;
  return x;
}
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

var dom_ElemPeer = sys_Obj.$extend(sys_Obj);

dom_ElemPeer.prototype.$ctor = function(self) {}

dom_ElemPeer.prototype.tagName = function(self) { return sys_Str.lower(this.elem.nodeName); }

dom_ElemPeer.prototype.id$get = function(self)
{
  console.log("elem: " + this.elem);
  return this.elem.id;
}
dom_ElemPeer.prototype.id$set = function(self, val) { return this.elem.id = val; }

dom_ElemPeer.prototype.name$get = function(self) { return this.elem.name; }
dom_ElemPeer.prototype.name$set = function(self, val) { return this.elem.name = val; }

dom_ElemPeer.prototype.className$get = function(self) { return this.elem.className; }
dom_ElemPeer.prototype.className$set = function(self, val) { return this.elem.className = val; }

dom_ElemPeer.prototype.hasClassName = function(self, className)
{
  var arr = this.elem.className.split(" ");
  for (var i=0; i<arr.length; i++)
    if (arr[i] == className)
      return true;
  return false;
}

dom_ElemPeer.prototype.addClassName = function(self, className)
{
  if (!this.hasClassName(self, className))
    this.elem.className += " " + className;
  return this;
}

dom_ElemPeer.prototype.removeClassName = function(self, className)
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

dom_ElemPeer.prototype.style = function(self) { return this.elem.style; }
dom_ElemPeer.prototype.computedStyle = function(self)
{
  return (this.elem.currentStyle)
    ? this.elem.currentStyle
    : document.defaultView.getComputedStyle(this.elem, null);
}

dom_ElemPeer.prototype.html$get = function(self) { return this.elem.innerHTML }
dom_ElemPeer.prototype.html$set = function(self, val) { this.elem.innerHTML = val; }

dom_ElemPeer.prototype.value$get = function(self) { return this.elem.value }
dom_ElemPeer.prototype.value$set = function(self, val) { this.elem.value = val; }

dom_ElemPeer.prototype.checked$get = function(self) { return this.elem.checked }
dom_ElemPeer.prototype.checked$set = function(self, val) { this.elem.checked = val; }

dom_ElemPeer.prototype.get = function(self, name, def)
{
  if (name == "id")      return this.id$get(self);
  if (name == "name")    return this.name$get(self);
  if (name == "class")   return this.className$get(self);
  if (name == "style")   return this.style(self);
  if (name == "value")   return this.value$get(self);
  if (name == "checked") return this.checked$get(self);

  var val = this.elem[name];
  if (val != null) return val;
  if (def != null) return def;
  return null;
}

dom_ElemPeer.prototype.set = function(self, name, val)
{
  if (name == "id")           this.id$set(self, val);
  else if (name == "name")    this.name$set(self, val);
  else if (name == "class")   this.className$set(self, val);
  else if (name == "value")   this.value$set(self, val);
  else if (name == "checked") this.checked$set(self, val);
  else this.elem.setAttribute(name, val);
}

dom_ElemPeer.prototype.x = function(self) { return this.elem.offsetLeft; }
dom_ElemPeer.prototype.y = function(self) { return this.elem.offsetTop; }
dom_ElemPeer.prototype.w = function(self) { return this.elem.offsetWidth; }
dom_ElemPeer.prototype.h = function(self) { return this.elem.offsetHeight; }

dom_ElemPeer.prototype.parent = function(self)
{
  var parent = this.elem.parentNode;
  if (parent == null) return null;
  return dom_ElemPeer.make(parent);
}

dom_ElemPeer.prototype.children = function(self)
{
  var list = new Array();
  var kids = this.elem.childNodes;
  for (var i=0; i<kids.length; i++)
    if (kids[i].nodeType == 1)
      list.push(dom_ElemPeer.make(kids[i]));
  return list;
}

dom_ElemPeer.prototype.first = function(self)
{
  var kids = this.elem.childNodes;
  for (var i=0; i<kids.length; i++)
    if (kids[i].nodeType == 1)
      return dom_ElemPeer.make(kids[i]);
  return null;
}

dom_ElemPeer.prototype.prev = function(self)
{
  var sib = this.elem.previousSibling;
  while (sib != null && sib.nodeType != 1)
    sib = sib.previousSibling;
  if (sib == null) return null;
  return dom_ElemPeer.make(sib);
}

dom_ElemPeer.prototype.next = function(self)
{
  var sib = this.elem.nextSibling;
  while (sib != null && sib.nodeType != 1)
    sib = sib.nextSibling;
  if (sib == null) return null;
  return dom_ElemPeer.make(sib);
}

dom_ElemPeer.prototype.add = function(self, child)
{
  this.elem.appendChild(child.elem);
  return this;
}

dom_ElemPeer.prototype.remove = function(self, child)
{
  this.elem.removeChild(child.elem);
  return this;
}

dom_ElemPeer.prototype.focus = function(self)
{
  // IE throws err if element is not visible, so we need
  // to wrap in a try block
  try { this.elem.focus(); }
  catch (err) {} // ignore
}

dom_ElemPeer.prototype.find = function(self, func)
{
  var kids = this.children(self);
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    if (func(kid)) return kid;
    kid = kid.find(func);
    if (kid != null) return kid;
  }
  return null;
}

dom_ElemPeer.prototype.findAll = function(self, func, acc)
{
  if (acc == null) acc = new Array();
  var kids = this.children(self);
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    if (func(kid)) acc.push(kid);
    kid.findAll(func, acc);
  }
  return acc;
}

dom_ElemPeer.prototype.onEvent = function(self, type, useCapture, handler)
{
  if (this.elem.addEventListener)
  {
    this.elem.addEventListener(type, function(e) {
      handler(dom_Event.make(e));
    }, useCapture);
  }
  else
  {
    this.elem.attachEvent('on'+type, function(e) {
      handler(dom_Event.make(e));
    });
  }
}

dom_ElemPeer.prototype.effect = function(self)
{
  if (this.fx == null)
  {
    this.fx = dom_Effect.make(self);
    this.fx.peer.sync(self);
  }
  return this.fx;
}
dom_ElemPeer.prototype.fx = null;

dom_ElemPeer.prototype.toStr = function(self)
{
  var name = this.elem.nodeName;
  var type = this.elem.type;
  var id   = this.elem.id;
  var str  = "<" + sys_Str.lower(name);
  if (type != null && type.length > 0) str += " type='" + type + "'";
  if (id != null && id.length > 0) str += " id='" + id + "'"
  str += ">";
  return str;
}

dom_ElemPeer.make = function(elem)
{
  if (elem == null) throw sys_ArgErr.make("elem is null")

  if (elem._fanElem != undefined)
    return elem._fanElem;

  var fan = dom_Elem.make();
  fan.peer.elem = elem;
  elem._fanElem = fan;
  return fan;
}
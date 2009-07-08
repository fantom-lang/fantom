//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

var webappClient_Elem = sys_Obj.$extend(sys_Obj);

webappClient_Elem.prototype.$ctor = function() {}
webappClient_Elem.prototype.type = function() { return sys_Type.find("webappClient::Elem"); }

webappClient_Elem.prototype.tagName = function() { return sys_Str.lower(this.elem.nodeName); }

webappClient_Elem.prototype.id$get = function() { return this.elem.id; }
webappClient_Elem.prototype.id$set = function(val) { return this.elem.id = val; }

webappClient_Elem.prototype.name$get = function() { return this.elem.name; }
webappClient_Elem.prototype.name$set = function(val) { return this.elem.name = val; }

webappClient_Elem.prototype.className$get = function() { return this.elem.className; }
webappClient_Elem.prototype.className$set = function(val) { return this.elem.className = val; }

webappClient_Elem.prototype.hasClassName = function(className)
{
  var arr = this.elem.className.split(" ");
  for (var i=0; i<arr.length; i++)
    if (arr[i] == className)
      return true;
  return false;
}

webappClient_Elem.prototype.addClassName = function(className)
{
  if (!this.hasClassName(className))
    this.elem.className += " " + className;
  return this;
}

webappClient_Elem.prototype.removeClassName = function(className)
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

webappClient_Elem.prototype.style = function() { return this.elem.style; }
webappClient_Elem.prototype.computedStyle = function()
{
  return (this.elem.currentStyle)
    ? this.elem.currentStyle
    : document.defaultView.getComputedStyle(this.elem, null);
}

webappClient_Elem.prototype.html$get = function() { return this.elem.innerHTML }
webappClient_Elem.prototype.html$set = function(val) { this.elem.innerHTML = val; }

webappClient_Elem.prototype.value$get = function() { return this.elem.value }
webappClient_Elem.prototype.value$set = function(val) { this.elem.value = val; }

webappClient_Elem.prototype.checked$get = function() { return this.elem.checked }
webappClient_Elem.prototype.checked$set = function(val) { this.elem.checked = val; }

webappClient_Elem.prototype.get = function(name, def)
{
  if (name == "id")      return this.id$get();
  if (name == "name")    return this.name$get();
  if (name == "class")   return this.className$get();
  if (name == "style")   return this.style();
  if (name == "value")   return this.value$get();
  if (name == "checked") return this.checked$get();

  var val = this.elem[name];
  if (val != null) return val;
  if (def != null) return def;
  return null;
}

webappClient_Elem.prototype.set = function(name, val)
{
  if (name == "id")           this.id$set(val);
  else if (name == "name")    this.name$set(val);
  else if (name == "class")   this.className$set(val);
  else if (name == "value")   this.value$set(val);
  else if (name == "checked") this.checked$set(val);
  else this.elem.setAttribute(name, val);
}

webappClient_Elem.prototype.x = function() { return this.elem.offsetLeft; }
webappClient_Elem.prototype.y = function() { return this.elem.offsetTop; }
webappClient_Elem.prototype.w = function() { return this.elem.offsetWidth; }
webappClient_Elem.prototype.h = function() { return this.elem.offsetHeight; }

webappClient_Elem.prototype.parent = function()
{
  var parent = this.elem.parentNode;
  if (parent == null) return null;
  return webappClient_Elem.make(parent);
}

webappClient_Elem.prototype.children = function()
{
  var list = new Array();
  var kids = this.elem.childNodes;
  for (var i=0; i<kids.length; i++)
    if (kids[i].nodeType == 1)
      list.push(webappClient_Elem.make(kids[i]));
  return list;
}

webappClient_Elem.prototype.first = function()
{
  var kids = this.elem.childNodes;
  for (var i=0; i<kids.length; i++)
    if (kids[i].nodeType == 1)
      return webappClient_Elem.make(kids[i]);
  return null;
}

webappClient_Elem.prototype.prev = function()
{
  var sib = this.elem.previousSibling;
  while (sib != null && sib.nodeType != 1)
    sib = sib.previousSibling;
  if (sib == null) return null;
  return webappClient_Elem.make(sib);
}

webappClient_Elem.prototype.next = function()
{
  var sib = this.elem.nextSibling;
  while (sib != null && sib.nodeType != 1)
    sib = sib.nextSibling;
  if (sib == null) return null;
  return webappClient_Elem.make(sib);
}

webappClient_Elem.prototype.add = function(child)
{
  this.elem.appendChild(child.elem);
  return this;
}

webappClient_Elem.prototype.remove = function(child)
{
  this.elem.removeChild(child.elem);
  return this;
}

webappClient_Elem.prototype.focus = function()
{
  // IE throws err if element is not visible, so we need
  // to wrap in a try block
  try { this.elem.focus(); }
  catch (err) {} // ignore
}

webappClient_Elem.prototype.find = function(func)
{
  var kids = this.children();
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    if (func(kid)) return kid;
    kid = kid.find(func);
    if (kid != null) return kid;
  }
  return null;
}

webappClient_Elem.prototype.findAll = function(func, acc)
{
  if (acc == null) acc = new Array();
  var kids = this.children();
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    if (func(kid)) acc.push(kid);
    kid.findAll(func, acc);
  }
  return acc;
}

webappClient_Elem.prototype.onEvent = function(type, useCapture, handler)
{
  if (this.elem.addEventListener)
  {
    this.elem.addEventListener(type, function(e) {
      handler(webappClient_Event.make(e));
    }, useCapture);
  }
  else
  {
    this.elem.attachEvent('on'+type, function(e) {
      handler(webappClient_Event.make(e));
    });
  }
}

webappClient_Elem.prototype.effect = function()
{
  if (this.fx == null)
    this.fx = webappClient_Effect.make(this);
  return this.fx;
}
webappClient_Elem.prototype.fx = null;

webappClient_Elem.prototype.toStr = function()
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

webappClient_Elem.make = function(elem)
{
  if (elem == null) throw sys_ArgErr.make("elem is null")

  if (elem._webappClientElem != undefined)
    return elem._webappClientElem;

  var wrap = new webappClient_Elem();
  wrap.elem = elem;
  elem._webappClientElem = wrap;
  return wrap;
}


//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

sys_Type.addType("webappClient::Elem");
var webappClient_Elem = sys_Obj.extend(
{
  $ctor: function() {},
  type: function() { return sys_Type.find("webappClient::Elem"); },

  tagName: function() { return sys_Str.lower(this.elem.nodeName); },

  id$get: function() { return this.elem.id; },
  id$set: function(val) { return this.elem.id = val; },

  name$get: function() { return this.elem.name; },
  name$set: function(val) { return this.elem.name = val; },

  className$get: function() { return this.elem.className; },
  className$set: function(val) { return this.elem.className = val; },

  hasClassName: function(className)
  {
    var arr = this.elem.className.split(" ");
    for (var i=0; i<arr.length; i++)
      if (arr[i] == className)
        return true;
    return false;
  },

  addClassName: function(className)
  {
    if (!this.hasClassName(className))
      this.elem.className += " " + className;
    return this;
  },

  removeClassName: function(className)
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
  },

  style: function() { return this.elem.style; },
  computedStyle: function()
  {
    return (this.elem.currentStyle)
      ? this.elem.currentStyle
      : document.defaultView.getComputedStyle(this.elem, null);
  },

  html$get: function() { return this.elem.innerHTML },
  html$set: function(val) { this.elem.innerHTML = val; },

  value$get: function() { return this.elem.value },
  value$set: function(val) { this.elem.value = val; },

  checked$get: function() { return this.elem.checked },
  checked$set: function(val) { this.elem.checked = val; },

  get: function(name, def)
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
  },

  set: function(name, val)
  {
    if (name == "id")           this.id$set(val);
    else if (name == "name")    this.name$set(val);
    else if (name == "class")   this.className$set(val);
    else if (name == "value")   this.value$set(val);
    else if (name == "checked") this.checked$set(val);
    else this.elem.setAttribute(name, val);
  },

  x: function() { return this.elem.offsetLeft; },
  y: function() { return this.elem.offsetTop; },
  w: function() { return this.elem.offsetWidth; },
  h: function() { return this.elem.offsetHeight; },

  parent: function()
  {
    var parent = this.elem.parentNode;
    if (parent == null) return null;
    return webappClient_Elem.make(parent);
  },

  children: function()
  {
    var list = new Array();
    var kids = this.elem.childNodes;
    for (var i=0; i<kids.length; i++)
      if (kids[i].nodeType == 1)
        list.push(webappClient_Elem.make(kids[i]));
    return list;
  },

  first: function()
  {
    var kids = this.elem.childNodes;
    for (var i=0; i<kids.length; i++)
      if (kids[i].nodeType == 1)
        return webappClient_Elem.make(kids[i]);
    return null;
  },

  prev: function()
  {
    var sib = this.elem.previousSibling;
    while (sib != null && sib.nodeType != 1)
      sib = sib.previousSibling;
    if (sib == null) return null;
    return webappClient_Elem.make(sib);
  },

  next: function()
  {
    var sib = this.elem.nextSibling;
    while (sib != null && sib.nodeType != 1)
      sib = sib.nextSibling;
    if (sib == null) return null;
    return webappClient_Elem.make(sib);
  },

  add: function(child)
  {
    this.elem.appendChild(child.elem);
    return this;
  },

  remove: function(child)
  {
    this.elem.removeChild(child.elem);
    return this;
  },

  focus: function()
  {
    this.elem.focus();
  },

  find: function(func)
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
  },

  findAll: function(func, acc)
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
  },

  onEvent: function(type, useCapture, handler)
  {
    this.elem.addEventListener(type, function(e) {
      handler(webappClient_Event.make(e));
    }, useCapture);
  },

  effect: function()
  {
    if (this.fx == null)
      this.fx = webappClient_Effect.make(this);
    return this.fx;
  },
  fx: null,

  toStr: function()
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

});

webappClient_Elem.make = function(elem)
{
  var wrap = new webappClient_Elem();
  if (elem != null) wrap.elem = elem;
  return wrap;
}
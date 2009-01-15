//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

var webappClient_Elem = sys_Obj.extend(
{
  $ctor: function() { sys_Type.addType("webappClient::Elem"); },
  type: function() { return sys_Type.find("webappClient::Elem"); },

  get: function(name, def)
  {
    var val = this.elem[name];
    if (val != null) return val;
    if (def != null) return def;
    return null;
  },

  set: function(name, val)
  {
    this.elem.setAttribute(name, val);
  },

  tagName: function()
  {
    return sys_Str.lower(this.elem.nodeName);
  },

  html$get: function() { return this.elem.innerHTML },
  html$set: function(val) { this.elem.innerHTML = val; },

  value$get: function() { return this.elem.value },
  value$set: function(val) { this.elem.value = val; },

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

  prev: function()
  {
    var sib = this.elem.previousSibling;
    if (sib == null) return null;
    return webappClient_Elem.make(sib);
  },

  next: function()
  {
    var sib = this.elem.nextSibling;
    if (sib == null) return null;
    return webappClient_Elem.make(sib);
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
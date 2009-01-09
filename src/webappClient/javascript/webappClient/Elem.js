//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

var webappClient_Elem = sys_Obj.extend(
{
  $ctor: function()
  {
    sys_Type.addType("webappClient::Elem");
    this.html.parent = this;
    this.value.parent = this;
  },

  type: function()
  {
    return sys_Type.find("webappClient::Elem");
  },

  tagName: function()
  {
    return sys_Str.lower(this.elem.nodeName);
  },

  html:
  {
    get: function() { return this.parent.elem.innerHTML },
    set: function(val) { this.parent.elem.innerHTML = val; }
  },

  value:
  {
    get: function() { return this.parent.elem.value },
    set: function(val) { this.parent.elem.value = val; }
  },

  parent: function()
  {
    var parent = this.elem.parent;
    if (parent == null) return null;
    return webappClient_Elem.make(parent);
  },

  children: function()
  {
    var list = new Array();
    var kids = this.elem.childNodes;
    for (var i=0; i<kids.length; i++)
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
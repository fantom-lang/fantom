//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

var dom_DocPeer = sys_Obj.$extend(sys_Obj);
dom_DocPeer.prototype.$ctor = function(self) {}

dom_DocPeer.body = function(self)
{
  return dom_ElemPeer.make(document.body);
}

dom_DocPeer.elem = function(self, id)
{
  var elem = document.getElementById(id);
  if (elem == null) return null;
  return dom_ElemPeer.make(elem);
}

dom_DocPeer.createElem = function(self, tagName, attribs)
{
  var elem = document.createElement(tagName);
  var wrap = dom_ElemPeer.make(elem);
  if (attribs != null)
  {
    var k = attribs.keys();
    for (var i=0; i<k.length; i++)
      wrap.set(k[i], attribs.get(k[i]));
  }
  return wrap;
}
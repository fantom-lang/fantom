//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

fan.dom.DocPeer = fan.sys.Obj.$extend(fan.sys.Obj);
fan.dom.DocPeer.prototype.$ctor = function(self) {}

fan.dom.DocPeer.body = function()
{
  return fan.dom.ElemPeer.make(document.body);
}

fan.dom.DocPeer.elem = function(id)
{
  var elem = document.getElementById(id);
  if (elem == null) return null;
  return fan.dom.ElemPeer.make(elem);
}

fan.dom.DocPeer.createElem = function(tagName, attribs)
{
  var elem = document.createElement(tagName);
  var wrap = fan.dom.ElemPeer.make(elem);
  if (attribs != null)
  {
    var k = attribs.keys();
    for (var i=0; i<k.length; i++)
      wrap.set(k[i], attribs.get(k[i]));
  }
  return wrap;
}

fan.dom.DocPeer.getCookiesStr = function() { return document.cookie; }
fan.dom.DocPeer.addCookieStr = function(c) { document.cookie = c; }


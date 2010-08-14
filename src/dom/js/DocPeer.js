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

fan.dom.DocPeer.prototype.title  = function(self) { return document.title; }
fan.dom.DocPeer.prototype.title$ = function(self, val) { document.title = val; }

fan.dom.DocPeer.prototype.body = function(self)
{
  return fan.dom.ElemPeer.make(document.body);
}

fan.dom.DocPeer.prototype.elem = function(self, id)
{
  var elem = document.getElementById(id);
  if (elem == null) return null;
  return fan.dom.ElemPeer.make(elem);
}

fan.dom.DocPeer.prototype.createElem = function(self, tagName, attribs)
{
  var elem = document.createElement(tagName);
  var wrap = fan.dom.ElemPeer.make(elem);
  if (attribs != null)
  {
    var k = attribs.keys();
    for (var i=0; i<k.size(); i++)
      wrap.set(k.get(i), attribs.get(k.get(i)));
  }
  return wrap;
}

fan.dom.DocPeer.prototype.getCookiesStr = function(self) { return document.cookie; }
fan.dom.DocPeer.prototype.addCookieStr = function(self,c) { document.cookie = c; }


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
fan.dom.DocPeer.prototype.$ctor = function(self)
{
  this.doc = null;
}

fan.dom.DocPeer.prototype.title  = function(self) { return this.doc.title; }
fan.dom.DocPeer.prototype.title$ = function(self, val) { this.doc.title = val; }

fan.dom.DocPeer.prototype.head = function(self)
{
  return fan.dom.ElemPeer.wrap(this.doc.head);
}

fan.dom.DocPeer.prototype.body = function(self)
{
  return fan.dom.ElemPeer.wrap(this.doc.body);
}

fan.dom.DocPeer.prototype.activeElem = function(self)
{
  var elem = this.doc.activeElement;
  if (elem == null) return null;
  return fan.dom.ElemPeer.wrap(elem);
}

fan.dom.DocPeer.prototype.elemById = function(self, id)
{
  var elem = this.doc.getElementById(id);
  if (elem == null) return null;
  return fan.dom.ElemPeer.wrap(elem);
}

fan.dom.DocPeer.prototype.elemFromPos = function(self, p)
{
  var elem = this.doc.elementFromPoint(p.m_x, p.m_y);
  if (elem == null) return null;
  return fan.dom.ElemPeer.wrap(elem);
}

fan.dom.DocPeer.prototype.elemsFromPos = function(self, p)
{
  var list  = fan.sys.List.make(fan.dom.Elem.$type);
  var elems = this.doc.elementsFromPoint(p.m_x, p.m_y);
  for (var i=0; i<elems.length; i++)
    list.add(fan.dom.ElemPeer.wrap(elems[i]));
  return list;
}

fan.dom.DocPeer.prototype.createElem = function(self, tagName, attribs, ns)
{
  var elem = ns
    ? this.doc.createElementNS(ns.toStr, tagName)
    : this.doc.createElement(tagName);
  var wrap = fan.dom.ElemPeer.wrap(elem);
  if (ns) wrap.m_ns = ns;
  if (attribs != null)
  {
    var k = attribs.keys();
    for (var i=0; i<k.size(); i++)
      wrap.set(k.get(i), attribs.get(k.get(i)));
  }
  return wrap;
}

fan.dom.DocPeer.prototype.createFrag = function(self)
{
  var frag = this.doc.createDocumentFragment();
  return fan.dom.ElemPeer.wrap(frag);
}

fan.dom.DocPeer.prototype.querySelector = function(self, selectors)
{
  var elem = this.doc.querySelector(selectors);
  if (elem == null) return null;
  return fan.dom.ElemPeer.wrap(elem);
}

fan.dom.DocPeer.prototype.querySelectorAll = function(self, selectors)
{
  var list  = fan.sys.List.make(fan.dom.Elem.$type);
  var elems = this.doc.querySelectorAll(selectors);
  for (var i=0; i<elems.length; i++)
    list.add(fan.dom.ElemPeer.wrap(elems[i]));
  return list;
}

fan.dom.DocPeer.prototype.querySelectorAllType = function(self, selectors, type)
{
  var list  = fan.sys.List.make(fan.dom.Elem.$type);
  var elems = this.doc.querySelectorAll(selectors);
  for (var i=0; i<elems.length; i++)
    list.add(fan.dom.ElemPeer.wrap(elems[i], type.make()));
  return list;
}

fan.dom.DocPeer.prototype.exportPng = function(self, img)
{
  return this.__export(img, "image/png");
}

fan.dom.DocPeer.prototype.exportJpg = function(self, img, quality)
{
  return this.__export(img, "image/jpeg", quality);
}

fan.dom.DocPeer.prototype.__export = function(img, mimeType, quality)
{
  var elem = img.peer.elem;

  // set phy canvas size to img
  var canvas = this.doc.createElement("canvas");
  canvas.style.width  = elem.width  + "px";
  canvas.style.height = elem.height + "px";

  // scale up working space if retina
  var ratio     = window.devicePixelRatio || 1;
  canvas.width  = ratio * elem.width;
  canvas.height = ratio * elem.height;

  // render with scale factor
  var cx = canvas.getContext("2d");
  cx.scale(ratio, ratio);
  cx.drawImage(elem, 0, 0);
  return canvas.toDataURL(mimeType, quality);
}

fan.dom.DocPeer.prototype.onEvent = function(self, type, useCapture, handler)
{
  handler.$func = function(e) { handler.call(fan.dom.EventPeer.make(e)); }
  this.doc.addEventListener(type, handler.$func, useCapture);
  return handler;
}

fan.dom.DocPeer.prototype.removeEvent = function(self, type, useCapture, handler)
{
  if (handler.$func)
    this.doc.removeEventListener(type, handler.$func, useCapture);
}

fan.dom.DocPeer.prototype.exec = function(self, name, defUi, val)
{
  return this.doc.execCommand(name, defUi, val);
}

fan.dom.DocPeer.prototype.out = function(self)
{
  return fan.web.WebOutStream.make(new fan.dom.DocOutStream(this.doc));
}

fan.dom.DocPeer.prototype.getCookiesStr = function(self) { return this.doc.cookie; }

fan.dom.DocPeer.prototype.addCookie = function(self,c)
{
  // always force HttpOnly otherwise this is a no-op for browsers
  c.m_httpOnly = false;
  this.doc.cookie = c.toStr();
}

/*************************************************************************
 * DocOutStream
 ************************************************************************/

fan.dom.DocOutStream = fan.sys.Obj.$extend(fan.sys.OutStream);
fan.dom.DocOutStream.prototype.$ctor = function(doc) { this.doc = doc; }

fan.dom.DocOutStream.prototype.w = function(v)
{
  throw fan.sys.UnsupportedErr.make("binary write on Doc output");
}

fan.dom.DocOutStream.prototype.write = function(x)
{
  throw fan.sys.UnsupportedErr.make("binary write on Doc output");
}

fan.dom.DocOutStream.prototype.writeBuf = function(buf, n)
{
  throw fan.sys.UnsupportedErr.make("binary write on Doc output");
}

fan.dom.DocOutStream.prototype.writeI2 = function(x)
{
  throw fan.sys.UnsupportedErr.make("binary write on Doc output");
}

fan.dom.DocOutStream.prototype.writeI4 = function(x)
{
  throw fan.sys.UnsupportedErr.make("binary write on Doc output");
}

fan.dom.DocOutStream.prototype.writeI8 = function(x)
{
  throw fan.sys.UnsupportedErr.make("binary write on Doc output");
}

fan.dom.DocOutStream.prototype.writeF4 = function(x)
{
  throw fan.sys.UnsupportedErr.make("binary write on Doc output");
}

fan.dom.DocOutStream.prototype.writeF8 = function(x)
{
  throw fan.sys.UnsupportedErr.make("binary write on Doc output");
}

fan.dom.DocOutStream.prototype.writeUtf = function(x)
{
  throw fan.sys.UnsupportedErr.make("modified UTF-8 format write on StrBuf output");
}

fan.dom.DocOutStream.prototype.writeChar = function(c)
{
  this.doc.write(String.fromCharCode(c));
}

fan.dom.DocOutStream.prototype.writeChars = function(s, off, len)
{
  if (off === undefined) off = 0;
  if (len === undefined) len = s.length-off;
  this.doc.write(s.substr(off, len));
  return this;
}

fan.dom.DocOutStream.prototype.flush = function() { return this; }

fan.dom.DocOutStream.prototype.close = function()
{
  this.doc.close();
  return true;
}
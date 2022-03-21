//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Mar 2022  Brian Frank  Creation
//

fan.dom.DomImagePeer = fan.sys.Obj.$extend(fan.sys.Obj);
fan.dom.DomImagePeer.prototype.$ctor = function(self) {}

fan.dom.DomImagePeer.prototype.init = function(self, elem)
{
  // map dom::Elem("img") to its HTMLImageElement
  this.elem = elem.peer.elem
}

fan.dom.DomImagePeer.prototype.isLoaded = function(self)
{
  return this.elem.complete;
}

fan.dom.DomImagePeer.prototype.size = function(self)
{
  return fan.graphics.Size.make(this.w(), this.h());
}

fan.dom.DomImagePeer.prototype.w = function(self)
{
  return fan.sys.Float.make(this.elem.naturalWidth);
}

fan.dom.DomImagePeer.prototype.h = function(self)
{
  return fan.sys.Float.make(this.elem.naturalHeight);
}





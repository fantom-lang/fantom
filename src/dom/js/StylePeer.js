//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Dec 2014  Andy Frank  Creation
//

fan.dom.StylePeer = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.dom.StylePeer.prototype.$ctor = function(self)
{
  // set in ElemPeer.style
  this.elem  = null;
  this.style = null;
}

fan.dom.StylePeer.prototype.clear = function(self)
{
  this.style.cssText = "";
  return self;
}

fan.dom.StylePeer.prototype.computed = function(self, name)
{
  if (!this.elem) return null;
  return window.getComputedStyle(this.elem).getPropertyValue(name);
}

fan.dom.StylePeer.prototype.get = function(self, name)
{
  return this.style.getPropertyValue(name);
}

fan.dom.StylePeer.prototype.setProp = function(self, name, val)
{
  if (val == null) this.style.removeProperty(name);
  else this.style.setProperty(name, val);
}

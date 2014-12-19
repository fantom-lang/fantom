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
  this.style = null;
}

fan.dom.StylePeer.prototype.get = function(self, name)
{
  return this.style.getPropertyValue(name);
}

fan.dom.StylePeer.prototype.set = function(self, name, val)
{
  this.style.setProperty(name, val);
}

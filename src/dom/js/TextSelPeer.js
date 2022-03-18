//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 2022  Andy Frank  Creation
//

fan.dom.TextSelPeer = fan.sys.Obj.$extend(fan.sys.Obj);
fan.dom.TextSelPeer.prototype.$ctor = function(self)
{
  this.sel = null;
}

fan.dom.TextSelPeer.prototype.clear = function(self)
{
  return this.sel.removeAllRanges();
}
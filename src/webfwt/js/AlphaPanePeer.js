//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Aug 10  Andy Frank  Creation
//

/**
 * AlphaPanePeer.
 */
fan.webfwt.AlphaPanePeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.AlphaPanePeer.prototype.$ctor = function(self) {}

fan.webfwt.AlphaPanePeer.prototype.create = function(parentElem, self)
{
  var div = this.emptyDiv();
  div.style.opacity = self.m_opacity;
  parentElem.appendChild(div);
  return div;
}


//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Oct 10  Andy Frank  Creation
//

/**
 * WebBorderPanePeer.
 */
fan.webfwt.WebBorderPanePeer = fan.sys.Obj.$extend(fan.fwt.BorderPanePeer);
fan.webfwt.WebBorderPanePeer.prototype.$ctor = function(self)
{
  fan.fwt.LabelPeer.prototype.$ctor.call(this, self);
}

fan.webfwt.WebBorderPanePeer.prototype.m_style = null;
fan.webfwt.WebBorderPanePeer.prototype.style = function(self) { return this.m_style; }
fan.webfwt.WebBorderPanePeer.prototype.style$ = function(self, val)
{
  this.m_rebuild = true;
  this.m_style = val;
}

// backdoor hook to override style
fan.webfwt.WebBorderPanePeer.prototype.$style = function(self)
{
  return this.m_style;
}


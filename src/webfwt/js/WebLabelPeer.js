//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Apr 2010  Andy Frank  Creation
//   17 Mar 2011  Andy Frank  Rename from FLabel to WebLabel
//

/**
 * WebLabelPeer.
 */
fan.webfwt.WebLabelPeer = fan.sys.Obj.$extend(fan.fwt.LabelPeer);
fan.webfwt.WebLabelPeer.prototype.$ctor = function(self)
{
  fan.fwt.LabelPeer.prototype.$ctor.call(this, self);
}

fan.webfwt.WebLabelPeer.prototype.m_hgap = null;
fan.webfwt.WebLabelPeer.prototype.hgap = function(self) { return this.m_hgap; }
fan.webfwt.WebLabelPeer.prototype.hgap$ = function(self, val)
{
  this.m_rebuild = true;
  this.m_hgap = val;
}

fan.webfwt.WebLabelPeer.prototype.m_softClip = false;
fan.webfwt.WebLabelPeer.prototype.softClip = function(self) { return this.m_softClip; }
fan.webfwt.WebLabelPeer.prototype.softClip$ = function(self, val)
{
  this.m_rebuild = true;
  this.m_softClip = val;
}

fan.webfwt.WebLabelPeer.prototype.m_imageSize = null;
fan.webfwt.WebLabelPeer.prototype.imageSize = function(self) { return this.m_imageSize; }
fan.webfwt.WebLabelPeer.prototype.imageSize$ = function(self, val)
{
  this.m_rebuild = true;
  this.m_imageSize = val;
}

fan.webfwt.WebLabelPeer.prototype.m_style = null;
fan.webfwt.WebLabelPeer.prototype.style = function(self) { return this.m_style; }
fan.webfwt.WebLabelPeer.prototype.style$ = function(self, val)
{
  this.m_rebuild = true;
  this.m_style = val;
}

// backdoor hook to override hgap
fan.webfwt.WebLabelPeer.prototype.$hgap = function(self)
{
  return this.m_hgap;
}

// backdoor hook to override softClip
fan.webfwt.WebLabelPeer.prototype.$softClip = function(self)
{
  return this.m_softClip;
}

// backdoor hook to override imageSize
fan.webfwt.WebLabelPeer.prototype.$imageSize = function(self)
{
  return this.m_imageSize;
}

// backdoor hook to override style
fan.webfwt.WebLabelPeer.prototype.$style = function(self)
{
  return this.m_style;
}



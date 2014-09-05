//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Sep 2015  Andy Frank  Creation
//

/**
 * WebBrowserPeer.
 */
fan.fwt.WebBrowserPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.WebBrowserPeer.prototype.$ctor = function(self) {}

fan.fwt.WebBrowserPeer.prototype.create = function(parentElem)
{
  this.iframe = document.createElement("iframe");
  this.iframe.style.width  = "100%";
  this.iframe.style.height = "100%";
  this.iframe.style.border = "none";

  var div = this.emptyDiv();
  div.appendChild(this.iframe);
  parentElem.appendChild(div);
  return div;
}

fan.fwt.WebBrowserPeer.prototype.load = function(self, uri)
{
  this.iframe.src = uri.toStr();
  return self;
}

fan.fwt.WebBrowserPeer.prototype.loadStr = function(self, html)
{
  this.iframe.srcdoc = html;
  return self;
}

fan.fwt.WebBrowserPeer.prototype.refresh = function(self)
{
  this.iframe.src = this.iframe.src;
  return self;
}

fan.fwt.WebBrowserPeer.prototype.stop = function(self)
{
  // no-op
  return self;
}

fan.fwt.WebBrowserPeer.prototype.back = function(self)
{
  this.iframe.contentWindow.history.back();
  return self;
}

fan.fwt.WebBrowserPeer.prototype.forward = function(self)
{
  this.iframe.contentWindow.history.forward();
  return self;
}


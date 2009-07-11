//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

fan.dom.WindowPeer = fan.sys.Obj.$extend(fan.sys.Obj);

fan.dom.WindowPeer.prototype.$ctor = function(self) {}

fan.dom.WindowPeer.alert = function(obj)
{
  alert(obj);
}

fan.dom.WindowPeer.uri = function()
{
  return fan.sys.Uri.make(window.location.toString());
}

fan.dom.WindowPeer.hyperlink = function(uri)
{
  window.location = uri.m_uri;
}
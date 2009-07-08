//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

var dom_WindowPeer = sys_Obj.$extend(sys_Obj);

dom_WindowPeer.prototype.$ctor = function(self) {}

dom_WindowPeer.alert = function(self, obj)
{
  alert(obj);
}

dom_WindowPeer.uri = function(self)
{
  return sys_Uri.make(window.location.toString());
}

dom_WindowPeer.hyperlink = function(self, uri)
{
  window.location = uri.m_uri;
}
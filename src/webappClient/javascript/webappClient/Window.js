//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

var webappClient_Window = sys_Obj.$extend(sys_Obj);

webappClient_Window.prototype.$ctor = function() {}
webappClient_Window.prototype.type = function() { return sys_Type.find("webappClient::Window"); }

webappClient_Window.alert = function(obj)
{
  alert(obj);
}

webappClient_Window.uri = function()
{
  return sys_Uri.make(window.location.toString());
}

webappClient_Window.hyperlink = function(uri)
{
  window.location = uri.m_uri;
}
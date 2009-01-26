//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

sys_Type.addType("webappClient::Window");
var webappClient_Window = sys_Obj.extend(
{
  $ctor: function() {},
  type: function() { return sys_Type.find("webappClient::Window"); },
});

webappClient_Window.alert = function(obj)
{
  alert(obj);
}

webappClient_Window.uri = function()
{
  return window.location.toString();
}

webappClient_Window.hyperlink = function(uri)
{
  window.location = uri;
}
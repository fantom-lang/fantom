//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

sys_Type.addType("webappClient::Doc");
var webappClient_Doc = sys_Obj.extend(
{
  $ctor: function() {},
  type: function() { return sys_Type.find("webappClient::Doc"); },
});

webappClient_Doc.body = function()
{
  return webappClient_Elem.make(document.body);
}

webappClient_Doc.elem = function(id)
{
  var elem = document.getElementById(id);
  if (elem == null) return null;
  return webappClient_Elem.make(elem);
}

webappClient_Doc.createElem = function(tagName)
{
  var elem = document.createElement(tagName);
  return webappClient_Elem.make(elem);
}
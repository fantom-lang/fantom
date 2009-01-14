//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

var webappClient_Doc = sys_Obj.extend(
{
  $ctor: function() { sys_Type.addType("webappClient::Doc"); },
  type: function() { return sys_Type.find("webappClient::Doc"); },
});

webappClient_Doc.body = function()
{
  return webappClient_Elem.makeFrom(document.body);
}

webappClient_Doc.getById = function(id)
{
  var elem = document.getElementById(id);
  if (elem == null) return null;
  return webappClient_Elem.make(elem);
}
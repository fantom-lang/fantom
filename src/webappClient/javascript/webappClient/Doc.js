//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

var webappClient_Doc = sys_Obj.extend(
{
  $ctor: function() {},
  type: function() { return sys_Type.find("webappClient::Doc"); }
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

webappClient_Doc.createElem = function(tagName, attribs)
{
  var elem = document.createElement(tagName);
  var wrap = webappClient_Elem.make(elem);
  if (attribs != null)
  {
    var k = attribs.keys();
    for (var i=0; i<k.length; i++)
      wrap.set(k[i], attribs.get(k[i]));
  }
  return wrap;
}
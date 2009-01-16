//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

var webappClient_HttpRes = sys_Obj.extend(
{
  $ctor: function() { sys_Type.addType("webappClient::HttpRes"); },
  type: function() { return sys_Type.find("webappClient::HttpRes"); },

  status$get: function() { return this.status },
  status$set: function(val) { this.status = val; },
  status: null,

  content$get: function() { return this.content },
  content$set: function(val) { this.content = val; },
  content: null,
});

webappClient_HttpRes.make = function(req)
{
  var res = new webappClient_HttpRes();
  if (req != null)
  {
    res.status = req.status;
    res.content = req.responseText;
  }
  return res;
}
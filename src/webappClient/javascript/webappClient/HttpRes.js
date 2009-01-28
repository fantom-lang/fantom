//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

sys_Type.addType("webappClient::HttpRes");
var webappClient_HttpRes = sys_Obj.extend(
{
  $ctor: function() {},
  type: function() { return sys_Type.find("webappClient::HttpRes"); },

  status$get: function() { return this.status },
  status$set: function(val) { this.status = val; },
  status: null,

  headers$get: function() { return this.headers },
  headers: new sys_Map(),

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

    var all = req.getAllResponseHeaders().split("\n");
    for (var i=0; i<all.length; i++)
    {
      if (all[i].length == 0) continue;
      var j = all[i].indexOf(":");
      var k = sys_Str.trim(all[i].substr(0, j));
      var v = sys_Str.trim(all[i].substr(j+1));
      res.headers.set(k, v);
    }
  }
  return res;
}
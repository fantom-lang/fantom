//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

var webappClient_HttpRes = sys_Obj.$extend(sys_Obj);

webappClient_HttpRes.prototype.$ctor = function()
{
  var strType = sys_Type.find("sys::Str");
  this.headers = new sys_Map(strType, strType);
},

webappClient_HttpRes.prototype.type = function()
{
  return sys_Type.find("webappClient::HttpRes");
}

webappClient_HttpRes.prototype.status$get = function() { return this.status }
webappClient_HttpRes.prototype.status$set = function(val) { this.status = val; }
webappClient_HttpRes.prototype.status = null;

webappClient_HttpRes.prototype.headers$get = function() { return this.headers }
webappClient_HttpRes.prototype.headers = null;

webappClient_HttpRes.prototype.content$get = function() { return this.content }
webappClient_HttpRes.prototype.content$set = function(val) { this.content = val; }
webappClient_HttpRes.prototype.content = null;

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
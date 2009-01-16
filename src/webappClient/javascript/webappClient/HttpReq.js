//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

var webappClient_HttpReq = sys_Obj.extend(
{
  $ctor: function() { sys_Type.addType("webappClient::HttpReq"); },
  type: function() { return sys_Type.find("webappClient::HttpReq"); },

  uri$get: function() { return this.uri },
  uri$set: function(val) { this.uri = val; },
  uri: "",

  method$get: function() { return this.method },
  method$set: function(val) { this.method = val; },
  method: "POST",

  async$get: function() { return this.async },
  async$set: function(val) { this.async = val; },
  async: true,

  send: function(content, func)
  {
    var req = new XMLHttpRequest();
    req.open(this.method, this.uri, this.async);
    if (this.async)
    {
      req.onreadystatechange = function () {
        if (req.readyState == 4)
          func(webappClient_HttpRes.make(req));
      }
    }
    req.send(content);
    if (!this.async) func(webappClient_HttpRes.make(req));
  }
});

webappClient_HttpReq.make = function(uri)
{
  var req = new webappClient_HttpReq();
  if (uri != null) req.uri = uri;
  return req;
}
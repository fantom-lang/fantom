//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

var webappClient_HttpReq = sys_Obj.extend(
{
  $ctor: function()
  {
    sys_Type.addType("webappClient::HttpReq");
    this.uri.parent = this;
    this.method.parent = this;
    this.async.parent = this;
  },

  type: function()
  {
    return sys_Type.find("webappClient::HttpReq");
  },

  uri:
  {
    get: function() { return val },
    set: function(val) { this.val = val; },
    val: ""
  },

  method:
  {
    get: function() { return val },
    set: function(val) { this.val = val; },
    val: "POST"
  },

  async:
  {
    get: function() { return val },
    set: function(val) { this.val = val; },
    val: true
  },

  send: function(content, func)
  {
    var req = new XMLHttpRequest();
    req.open(this.method.val, this.uri.val, this.async.val);
    req.onreadystatechange = function ()
    {
      if (req.readyState == 4)
      {
        var res = webappClient_HttpRes.make();
        res.status.val = req.status;
        res.content.val = req.responseText;
        func(res);
      }
    }
    req.send(content);
  }
});

webappClient_HttpReq.make = function(uri)
{
  var req = new webappClient_HttpReq();
  if (uri != null) req.uri.val = uri;
  return req;
}
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

var webappClient_HttpReq = sys_Obj.$extend(sys_Obj);

webappClient_HttpReq.prototype.$ctor = function()
{
  var strType = sys_Type.find("sys::Str");
  this.headers = new sys_Map(strType, strType);
}

webappClient_HttpReq.prototype.type = function() { return sys_Type.find("webappClient::HttpReq"); }

webappClient_HttpReq.prototype.uri$get = function() { return this.uri }
webappClient_HttpReq.prototype.uri$set = function(val) { this.uri = val; }
webappClient_HttpReq.prototype.uri = sys_Uri.make("");

webappClient_HttpReq.prototype.method$get = function() { return this.method }
webappClient_HttpReq.prototype.method$set = function(val) { this.method = val; }
webappClient_HttpReq.prototype.method = "POST";

webappClient_HttpReq.prototype.headers$get = function() { return this.headers }
webappClient_HttpReq.prototype.headers = null;

webappClient_HttpReq.prototype.async$get = function() { return this.async }
webappClient_HttpReq.prototype.async$set = function(val) { this.async = val; }
webappClient_HttpReq.prototype.async = true;

webappClient_HttpReq.prototype.send = function(content, func)
{
  var req = new XMLHttpRequest();
  req.open(this.method, this.uri.m_uri, this.async);
  if (this.async)
  {
    req.onreadystatechange = function () {
      if (req.readyState == 4)
        func(webappClient_HttpRes.make(req));
    }
  }
  var ct = false;
  var k = this.headers.keys();
  for (var i=0; i<k.length; i++)
  {
    if (sys_Str.lower(k[i]) == "content-type") ct = true;
    req.setRequestHeader(k[i], this.headers.get(k[i]));
  }
  if (!ct) req.setRequestHeader("Content-Type", "text/plain");
  req.send(content);
  if (!this.async) func(webappClient_HttpRes.make(req));
}

webappClient_HttpReq.prototype.sendForm = function(form, func)
{
  this.headers.set("Content-Type", "application/x-www-form-urlencoded");
  var content = ""
  var k = form.keys();
  for (var i=0; i<k.length; i++)
  {
    if (i > 0) content += "&";
    content += escape(k[i]) + "=" + escape(form.get(k[i]));
  }
  this.send(content, func)
}

webappClient_HttpReq.make = function(uri, method)
{
  var req = new webappClient_HttpReq();
  if (uri != null) req.uri = uri;
  if (method != null) req.method = method;
  return req;
}


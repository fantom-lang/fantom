//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

fan.dom.HttpReqPeer = fan.sys.Obj.$extend(fan.sys.Obj);

fan.dom.HttpReqPeer.prototype.$ctor = function(self) {}

fan.dom.HttpReqPeer.prototype.send = function(self, content, func)
{
  var xhr = new XMLHttpRequest();
  xhr.open(self.m_method, self.m_uri.m_str, self.m_async);
  if (self.m_async)
  {
    xhr.onreadystatechange = function ()
    {
      if (xhr.readyState == 4)
        func(fan.dom.HttpReqPeer.makeRes(xhr));
    }
  }
  var ct = false;
  var k = self.m_headers.keys();
  for (var i=0; i<k.length; i++)
  {
    if (fan.sys.Str.lower(k[i]) == "content-type") ct = true;
    xhr.setRequestHeader(k[i], self.m_headers.get(k[i]));
  }
  if (!ct) xhr.setRequestHeader("Content-Type", "text/plain");
  xhr.send(content);
  if (!self.m_async) func(fan.dom.HttpReqPeer.makeRes(xhr));
}

fan.dom.HttpReqPeer.makeRes = function(xhr)
{
  var res = fan.dom.HttpRes.make();
  res.m_status  = xhr.status;
  res.m_content = xhr.responseText;

  var all = xhr.getAllResponseHeaders().split("\n");
  for (var i=0; i<all.length; i++)
  {
    if (all[i].length == 0) continue;
    var j = all[i].indexOf(":");
    var k = fan.sys.Str.trim(all[i].substr(0, j));
    var v = fan.sys.Str.trim(all[i].substr(j+1));
    res.m_headers.set(k, v);
  }

  return res;
}

fan.dom.HttpReqPeer.prototype.sendForm = function(self, form, func)
{
  self.m_headers.set("Content-Type", "application/x-www-form-urlencoded");
  var content = ""
  var k = form.keys();
  for (var i=0; i<k.length; i++)
  {
    if (i > 0) content += "&";
    content += this.encode(k[i]) + "=" + this.encode(form.get(k[i]));
  }
  this.send(self, content, func)
}

fan.dom.HttpReqPeer.prototype.encode = function(orig)
{
  return escape(orig).replace(/\+/g, "%2B");
}
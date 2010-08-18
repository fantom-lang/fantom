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

fan.dom.HttpReqPeer.prototype.send = function(self, method, content, f)
{
  var xhr = new XMLHttpRequest();
  xhr.open(method.toUpperCase(), self.m_uri.m_str, self.m_async);
  if (self.m_async)
  {
    xhr.onreadystatechange = function ()
    {
      if (xhr.readyState == 4)
        f.call(fan.dom.HttpReqPeer.makeRes(xhr));
    }
  }
  var ct = false;
  var k = self.m_headers.keys();
  for (var i=0; i<k.size(); i++)
  {
    var key = k.get(i);
    if (fan.sys.Str.lower(key) == "content-type") ct = true;
    xhr.setRequestHeader(key, self.m_headers.get(key));
  }
  if (!ct) xhr.setRequestHeader("Content-Type", "text/plain");
  xhr.send(content);
  if (!self.m_async) f.call(fan.dom.HttpReqPeer.makeRes(xhr));
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

fan.dom.HttpReqPeer.prototype.encodeForm = function(self, form)
{
  var content = ""
  var k = form.keys();
  for (var i=0; i<k.size(); i++)
  {
    if (i > 0) content += "&";
    content += encodeURIComponent(k.get(i)) + "=" +
               encodeURIComponent(form.get(k.get(i)));
  }
  return content;
}


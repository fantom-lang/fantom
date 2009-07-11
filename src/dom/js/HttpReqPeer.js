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
  var req = new XMLHttpRequest();
  req.open(self.method, self.uri.m_uri, self.async);
  if (self.async)
  {
    req.onreadystatechange = function () {
      if (req.readyState == 4)
      {
        var res = fan.dom.HttpRes.make();
        res.status  = req.status;
        res.content = req.responseText;

        var all = req.getAllResponseHeaders().split("\n");
        for (var i=0; i<all.length; i++)
        {
          if (all[i].length == 0) continue;
          var j = all[i].indexOf(":");
          var k = fan.sys.Str.trim(all[i].substr(0, j));
          var v = fan.sys.Str.trim(all[i].substr(j+1));
          res.headers.set(k, v);
        }

        func(res);
      }
    }
  }
  var ct = false;
  var k = self.headers.keys();
  for (var i=0; i<k.length; i++)
  {
    if (fan.sys.Str.lower(k[i]) == "content-type") ct = true;
    req.setRequestHeader(k[i], self.headers.get(k[i]));
  }
  if (!ct) req.setRequestHeader("Content-Type", "text/plain");
  req.send(content);
  if (!self.async) func(fan.dom.HttpRes.make(req));
}

fan.dom.HttpReqPeer.prototype.sendForm = function(self, form, func)
{
  self.headers.set("Content-Type", "application/x-www-form-urlencoded");
  var content = ""
  var k = form.keys();
  for (var i=0; i<k.length; i++)
  {
    if (i > 0) content += "&";
    content += escape(k[i]) + "=" + escape(form.get(k[i]));
  }
  this.send(self, content, func)
}


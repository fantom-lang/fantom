//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

fan.dom.WinPeer = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.prototype.$ctor = function(self)
{
  this.win = null;
}

fan.dom.WinPeer.cur = function()
{
  if (fan.dom.WinPeer.$cur == null)
  {
    fan.dom.WinPeer.$cur = fan.dom.Win.make();
    fan.dom.WinPeer.$cur.peer.win = window;
  }
  return fan.dom.WinPeer.$cur;
}

fan.dom.WinPeer.prototype.userAgent = function(self)
{
  return navigator.userAgent;
}

//////////////////////////////////////////////////////////////////////////
// Secondary Windows
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.open = function(uri, name, opts)
{
  if (name === undefined) name = null;
  if (opts === undefined) opts = null;

  var optStr = "";
  if (opts != null)
  {
    var keys = opts.keys();
    for (var i=0; i<keys.size(); i++)
    {
      var key = keys.get(i);
      var val = opts.get(key);
      if (optStr != null) optStr += ",";
      optStr += key + "=" + val;
    }
  }

  var w = fan.dom.Win.make();
  if (opts != null) w.peer.win = window.open(uri.encode(), name, optStr);
  if (name != null) w.peer.win = window.open(uri.encode(), name);
  else              w.peer.win = window.open(uri.encode());
  return w;
}

fan.dom.WinPeer.prototype.close = function(self)
{
  this.win.close();
}

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.prototype.doc = function(self)
{
  if (this.$doc == null)
  {
    this.$doc = fan.dom.Doc.make();
    this.$doc.peer.doc = this.win.document;
  }
  return this.$doc;
}

fan.dom.WinPeer.prototype.addStyleRules = function(self, rules)
{
  var doc = this.win.document;
  var style = doc.createElement("style");
  style.type = "text/css";
  if (style.styleSheet) style.styleSheet.cssText = rules;
  else style.appendChild(doc.createTextNode(rules));
  doc.getElementsByTagName("head")[0].appendChild(style);
}

fan.dom.WinPeer.prototype.alert = function(self, obj)
{
  this.win.alert(obj);
}

fan.dom.WinPeer.prototype.viewport = function(self)
{
  return (typeof this.win.innerWidth != "undefined")
    ? fan.gfx.Size.make(this.win.innerWidth, this.win.innerHeight)
    : fan.gfx.Size.make(
        this.win.document.documentElement.clientWidth,
        this.win.document.documentElement.clientHeight);
}

fan.dom.WinPeer.prototype.screenSize = function(self)
{
  if (this.$screenSize == null)
    this.$screenSize = fan.gfx.Size.make(this.win.screen.width, this.win.screen.height);
  return this.$screenSize;
}

fan.dom.WinPeer.prototype.parent = function(self)
{
  if (this.win == this.win.parent) return null;
  if (this.$parent == null)
  {
    this.$parent = fan.dom.Win.make();
    this.$parent.peer.win = this.win.parent;
  }
  return this.$parent;
}

fan.dom.WinPeer.prototype.top = function(self)
{
  if (this.win == this.win.top) return self;
  if (this.$top == null)
  {
    this.$top = fan.dom.Win.make();
    this.$top.peer.win = this.win.top;
  }
  return this.$top;
}

//////////////////////////////////////////////////////////////////////////
// Uri
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.prototype.uri = function(self)
{
  return fan.sys.Uri.decode(this.win.location.toString());
}

fan.dom.WinPeer.prototype.hyperlink = function(self, uri)
{
  this.win.location = uri.encode();
}

fan.dom.WinPeer.prototype.reload  = function(self, force)
{
  this.win.location.reload(force);
}

//////////////////////////////////////////////////////////////////////////
// History
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.prototype.hisBack      = function(self) { this.win.history.back(); }
fan.dom.WinPeer.prototype.hisForward   = function(self) { this.win.history.forward(); }

fan.dom.WinPeer.prototype.hisPushState = function(self, title, uri, map)
{
  var state = fan.dom.WinPeer.mapToState(map);
  this.win.history.pushState(state, title, uri.encode());
}

fan.dom.WinPeer.prototype.hisReplaceState = function(self, title, uri, map)
{
  var state = fan.dom.WinPeer.mapToState(map);
  this.win.history.replaceState(state, title, uri.encode());
}

fan.dom.WinPeer.mapToState = function(map)
{
  // TODO FIXIT: serializtaion
  var array = [];
  map.each(fan.sys.Func.make(
    fan.sys.List.make(fan.sys.Param.$type, [
      new fan.sys.Param("val","sys::Obj",false),
      new fan.sys.Param("key","sys::Str",false)
    ]),
    fan.sys.Void.$type,
    function(val,key) { array[key] = val })
  );
  return array;
}

//////////////////////////////////////////////////////////////////////////
// EventTarget
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.prototype.onEvent = function(self, type, useCapture, handler)
{
  var f = function(e)
  {
    var evt = fan.dom.EventPeer.make(e);
    if (type == "popstate")
    {
      // copy state object into Event.stash
      // TODO FIXIT: deserializtaion
      var array = e.state;
      for (var key in array) evt.m_stash.set(key, array[key]);
    }
    handler.call(evt);

    if (type == "beforeunload")
    {
      var msg = evt.m_stash.get("beforeunloadMsg");
      if (msg != null)
      {
        e.returnValue = msg;
        return msg;
      }
    }
  }

  if (window.addEventListener)
  {
    // trap hashchange for non-supporting browsers
    if (type == "hashchange" && !("onhashchange" in window))
    {
      this.fakeHashChange(self, handler);
      return;
    }

    this.win.addEventListener(type, f, useCapture);
  }
  else
  {
    this.win.attachEvent('on'+type, f);
  }
}

fan.dom.WinPeer.prototype.fakeHashChange = function(self, handler)
{
  var $this = this;
  var getHash = function()
  {
    var href  = $this.win.location.href;
    var index = href.indexOf('#');
    return index == -1 ? '' : href.substr(index+1);
  }
  var oldHash = getHash();
  var checkHash = function()
  {
    var newHash = getHash();
    if (oldHash != newHash)
    {
      oldHash = newHash;
      handler.call(fan.dom.EventPeer.make(null));
    }
  }
  setInterval(checkHash, 100);
}

fan.dom.WinPeer.prototype.callLater = function(self, delay, f)
{
  var func = function() { f.call() }
  this.win.setTimeout(func, delay.toMillis());
}

fan.dom.WinPeer.prototype.reqAnimationFrame = function(self, f)
{
  var func = function() { f.call(self) };
  this.win.requestAnimationFrame(func);
}

//////////////////////////////////////////////////////////////////////////
// Storage
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.prototype.setTimeout = function(self, delay, f)
{
  var func = function() { f.call(self) }
  return this.win.setTimeout(func, delay.toMillis());
}

fan.dom.WinPeer.prototype.clearTimeout = function(self, id)
{
  this.win.clearTimeout(id);
}

fan.dom.WinPeer.prototype.setInterval = function(self, delay, f)
{
  var func = function() { f.call(self) }
  return this.win.setInterval(func, delay.toMillis());
}

fan.dom.WinPeer.prototype.clearInterval = function(self, id)
{
  this.win.clearInterval(id);
}

//////////////////////////////////////////////////////////////////////////
// Storage
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.prototype.sessionStorage = function(self)
{
  if (this.$sessionStorage == null)
  {
    this.$sessionStorage = fan.dom.Storage.make();
    this.$sessionStorage.peer.$instance = this.win.sessionStorage;
  }
  return this.$sessionStorage;
}

fan.dom.WinPeer.prototype.localStorage = function(self)
{
  if (this.$localStorage == null)
  {
    this.$localStorage = fan.dom.Storage.make();
    this.$localStorage.peer.$instance = this.win.localStorage;
  }
  return this.$localStorage;
}

//////////////////////////////////////////////////////////////////////////
// Diagnostics
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.prototype.diagnostics = function(self)
{
  var map = fan.sys.Map.make(fan.sys.Str.$type, fan.sys.Obj.$type);
  map.ordered$(true);

  var dur = function(s, e) {
    return s && e ? fan.sys.Duration.makeMillis(e-s) : null;
  }

  // user-agent
  map.set("ua", window.navigator.userAgent);

  // performance.timing
  var t = window.performance.timing;
  map.set("perf.timing.unload",         dur(t.unloadEventStart,      t.unloadEventEnd));
  map.set("perf.timing.redirect",       dur(t.redirectStart,         t.redirectEnd));
  map.set("perf.timing.domainLookup",   dur(t.domainLookupStart,     t.domainLookupEnd));
  map.set("perf.timing.connect",        dur(t.connectStart,          t.connectEnd));
  map.set("perf.timing.secureConnect",  dur(t.secureConnectionStart, t.connectEnd));
  map.set("perf.timing.request",        dur(t.requestStart,          t.responseStart));
  map.set("perf.timing.response",       dur(t.responseStart,         t.responseEnd));
  map.set("perf.timing.domInteractive", dur(t.domLoading,            t.domInteractive));
  map.set("perf.timing.domLoaded",      dur(t.domLoading,            t.domComplete));
  map.set("perf.timing.load",           dur(t.loadEventStart,        t.loadEventEnd));

  return map;
}
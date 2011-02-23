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
// EventTarget
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.prototype.onEvent = function(self, type, useCapture, handler)
{
  var f = function(e)
  {
    var evt = fan.dom.EventPeer.make(e);
    handler.call(evt);

    if (type == "beforeunload")
    {
      var msg = evt.m_meta.get("beforeunloadMsg");
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


//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//   10 Jun 2023  Kiera O'Flynn  Refactor to ES
//

class WinPeer extends sys.Obj {

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor(self)
  {
    super();
    this.win = null;
  }

  win;

  static #cur;
  static cur()
  {
    if (!WinPeer.#cur)
    {
      WinPeer.#cur = Win.make();
      WinPeer.#cur.peer.win = window;
    }
    return WinPeer.#cur;
  }

  userAgent(self)
  {
    return navigator.userAgent;
  }

//////////////////////////////////////////////////////////////////////////
// Secondary Windows
//////////////////////////////////////////////////////////////////////////

  open(self, uri, name, opts)
  {
    if (name === undefined) name = null;
    if (opts === undefined) opts = null;

    let optStr = "";
    if (opts != null)
    {
      const keys = opts.keys();
      for (let i=0; i<keys.size(); i++)
      {
        const key = keys.get(i);
        const val = opts.get(key);
        if (optStr != null) optStr += ",";
        optStr += key + "=" + val;
      }
    }

    const w = Win.make();
    if (opts != null) w.peer.win = this.win.open(uri.encode(), name, optStr);
    if (name != null) w.peer.win = this.win.open(uri.encode(), name);
    else              w.peer.win = this.win.open(uri.encode());
    return w;
  }

  close(self)
  {
    this.win.close();
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  #doc;
  doc(self)
  {
    if (!this.#doc)
    {
      this.#doc = Doc.make();
      this.#doc.peer.doc = this.win.document;
    }
    return this.#doc;
  }

  #textSel;
  textSel(self)
  {
    if (!this.#textSel)
    {
      this.#textSel = TextSel.make();
      this.#textSel.peer.sel = this.win.getSelection();
    }
    return this.#textSel;
  }

  addStyleRules(self, rules)
  {
    const doc = this.win.document;
    const style = doc.createElement("style");
    style.type = "text/css";
    if (style.styleSheet) style.styleSheet.cssText = rules;
    else style.appendChild(doc.createTextNode(rules));
    doc.getElementsByTagName("head")[0].appendChild(style);
  }

  alert(self, obj)
  {
    this.win.alert(obj);
  }

  confirm(self, obj)
  {
    return this.win.confirm(obj);
  }

  viewport(self)
  {
    return (typeof this.win.innerWidth != "undefined")
      ? graphics.Size.makeInt(this.win.innerWidth, this.win.innerHeight)
      : graphics.Size.makeInt(
          this.win.document.documentElement.clientWidth,
          this.win.document.documentElement.clientHeight);
  }

  #screenSize;
  screenSize(self)
  {
    if (!this.#screenSize)
      this.#screenSize = graphics.Size.makeInt(this.win.screen.width, this.win.screen.height);
    return this.#screenSize;
  }

  #parent;
  parent(self)
  {
    if (this.win == this.win.parent) return null;
    if (!this.#parent)
    {
      this.#parent = Win.make();
      this.#parent.peer.win = this.win.parent;
    }
    return this.#parent;
  }

  #top;
  top(self)
  {
    if (this.win == this.win.top) return self;
    if (!this.#top)
    {
      this.#top = Win.make();
      this.#top.peer.win = this.win.top;
    }
    return this.#top;
  }

  static eval(js)
  {
    return eval(js);
  }

  log(self, obj)
  {
    console.log(obj);
  }

//////////////////////////////////////////////////////////////////////////
// Scrolling
//////////////////////////////////////////////////////////////////////////

  #scrollPos;
  scrollPos(self)
  {
    const x = this.win.scrollX;
    const y = this.win.scrollY;
    if (!this.#scrollPos || this.#scrollPos.x() != x || this.#scrollPos.y() != y)
      this.#scrollPos = graphics.Point.makeInt(x, y);
    return this.#scrollPos;
  }

  scrollTo(self, x, y)
  {
    this.win.scrollTo(x, y)
  }

  scrollBy(self, x, y)
  {
    this.win.scrollBy(x, y)
  }

//////////////////////////////////////////////////////////////////////////
// Uri
//////////////////////////////////////////////////////////////////////////

  uri(self)
  {
    return sys.Uri.decode(this.win.location.toString());
  }

  hyperlink(self, uri)
  {
    let href = uri.encode();
    if (uri.scheme() == "mailto")
    {
      // TODO: mailto links are not decoding + as spaces properly, so
      // not showing up correctly in email clients when subj/body are
      // specified; for now just manually convert back
      href = href.replaceAll("+", " ");
    }
    this.win.location = href;
  }

  reload(self, force)
  {
    this.win.location.reload(force);
  }

//////////////////////////////////////////////////////////////////////////
// Clipboard
//////////////////////////////////////////////////////////////////////////

  clipboardReadText(self, func)
  {
    this.win.navigator.clipboard.readText().then((text) => func(text));
  }

  clipboardWriteText(self, text)
  {
    this.win.navigator.clipboard.writeText(text);
  }

//////////////////////////////////////////////////////////////////////////
// History
//////////////////////////////////////////////////////////////////////////

  hisBack(self)    { this.win.history.back(); }
  hisForward(self) { this.win.history.forward(); }

  hisPushState(self, title, uri, map)
  {
    const state = WinPeer.mapToState(map);
    this.win.history.pushState(state, title, uri.encode());
  }

  hisReplaceState(self, title, uri, map)
  {
    const state = WinPeer.mapToState(map);
    this.win.history.replaceState(state, title, uri.encode());
  }

  static mapToState(map)
  {
    // TODO FIXIT: serializtaion
    const array = [];
    map.each((val,key) => { array[key] = val });
    return array;
  }

//////////////////////////////////////////////////////////////////////////
// EventTarget
//////////////////////////////////////////////////////////////////////////

  onEvent(self, type, useCapture, handler)
  {
    handler.$func = function(e)
    {
      const evt = EventPeer.make(e);
      if (type == "popstate")
      {
        // copy state object into Event.stash
        // TODO FIXIT: deserializtaion
        const array = e.state;
        for (const key in array) evt.stash().set(key, array[key]);
      }
      handler(evt);

      if (type == "beforeunload")
      {
        const msg = evt.stash().get("beforeunloadMsg");
        if (msg != null)
        {
          e.returnValue = msg;
          return msg;
        }
      }
    }

    this.win.addEventListener(type, handler.$func, useCapture);
    return handler;
  }

  removeEvent(self, type, useCapture, handler)
  {
    if (handler.$func)
      this.win.removeEventListener(type, handler.$func, useCapture);
  }

  fakeHashChange(self, handler)
  {
    const $this = this;
    const getHash = function()
    {
      const href  = $this.win.location.href;
      const index = href.indexOf('#');
      return index == -1 ? '' : href.substr(index+1);
    }
    let oldHash = getHash();
    const checkHash = function()
    {
      const newHash = getHash();
      if (oldHash != newHash)
      {
        oldHash = newHash;
        handler(EventPeer.make(null));
      }
    }
    setInterval(checkHash, 100);
  }

  callLater(self, delay, f)
  {
    this.win.setTimeout(f, delay.toMillis());
  }

  reqAnimationFrame(self, f)
  {
    const func = function() { f(self) };
    this.win.requestAnimationFrame(func);
  }

//////////////////////////////////////////////////////////////////////////
// Timers
//////////////////////////////////////////////////////////////////////////

  setTimeout(self, delay, f)
  {
    const func = function() { f(self) }
    return this.win.setTimeout(func, delay.toMillis());
  }

  clearTimeout(self, id)
  {
    this.win.clearTimeout(id);
  }

  setInterval(self, delay, f)
  {
    const func = function() { f(self) }
    return this.win.setInterval(func, delay.toMillis());
  }

  clearInterval(self, id)
  {
    this.win.clearInterval(id);
  }

//////////////////////////////////////////////////////////////////////////
// Geolocation
//////////////////////////////////////////////////////////////////////////

  geoCurPosition(self, onSuccess, onErr, opts)
  {
    this.win.navigator.geolocation.getCurrentPosition(
      function(p) { onSuccess(DomCoordPeer.wrap(p)); },
      function(err)  { if (onErr) onErr(sys.Err.make(err.code + ": " + err.message)); },
      this.$geoOpts(opts));
  }

  geoWatchPosition(self, onSuccess, onErr, opts)
  {
    return this.win.navigator.geolocation.watchPosition(
      function(p) { onSuccess(DomCoordPeer.wrap(p)); },
      function(err)  { if (onErr) onErr(sys.Err.make(err.code + ": " + err.message)); },
      this.$geoOpts(opts));
  }

  geoClearWatch(self, id)
  {
    this.win.navigator.geolocation.clearWatch(id);
  }

  $geoOpts(fanMap)
  {
    if (!fanMap) return null;

    var opts = {};
    var keys = fanMap.keys();
    for (var i=0; i<keys.size(); i++)
    {
      var key = keys.get(i);
      var val = fanMap.get(key);
      opts[key] = val;
    }

    return opts;
  }

//////////////////////////////////////////////////////////////////////////
// Storage
//////////////////////////////////////////////////////////////////////////

  sessionStorage(self)
  {
    if (this.$sessionStorage == null)
    {
      this.$sessionStorage = Storage.make();
      this.$sessionStorage.peer.$instance = this.win.sessionStorage;
    }
    return this.$sessionStorage;
  }

  localStorage(self)
  {
    if (this.$localStorage == null)
    {
      this.$localStorage = Storage.make();
      this.$localStorage.peer.$instance = this.win.localStorage;
    }
    return this.$localStorage;
  }

//////////////////////////////////////////////////////////////////////////
// Diagnostics
//////////////////////////////////////////////////////////////////////////

  diagnostics(self)
  {
    var map = sys.Map.make(sys.Str.type$, sys.Obj.type$);
    map.ordered(true);

    var dur = function(s, e) {
      return s && e ? sys.Duration.makeMillis(e-s) : null;
    }

    // user-agent
    map.set("ua", this.win.navigator.userAgent);

    // performance.timing
    var t = this.win.performance.timing;
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
}
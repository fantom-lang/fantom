//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 09  Andy Frank  Creation
//

/**
 * WindowPeer.
 */
fan.fwt.WindowPeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.fwt.WindowPeer.prototype.$ctor = function(self) {}

fan.fwt.WindowPeer.prototype.open = function(self)
{
  // check for alt root
  var rootId = fan.sys.Env.cur().vars().get("fwt.window.root")
  if (rootId == null) this.root = document.body;
  else
  {
    this.root = document.getElementById(rootId);
    if (this.root == null) throw fan.sys.ArgErr.make("No root found");
  }

  // mount shell we use to attach widgets to
  var shell = document.createElement("div")
  with (shell.style)
  {
    position   = this.root === document.body ? "fixed" : "absolute";
    top        = "0";
    left       = "0";
    width      = "100%";
    height     = "100%";
    background = "#fff";
  }

  // mount window
  var elem = this.emptyDiv();
  shell.appendChild(elem);
  this.attachTo(self, elem);
  this.root.appendChild(shell);
  self.relayout();

  // attach resize listener
  window.addEventListener("resize", function() { self.relayout(); }, false);

  // fire onOpen event
  var event      = fan.fwt.Event.make();
  event.m_id     = fan.fwt.EventId.m_open;
  event.m_widget = self;
  self.onOpen().fire(event);
}

fan.fwt.WindowPeer.prototype.close = function(self, result)
{
  var event      = fan.fwt.Event.make();
  event.m_id     = fan.fwt.EventId.m_close;
  event.m_widget = self;
  event.m_data   = result;

  var list = self.onClose().list();
  for (var i=0; i<list.size(); i++) list.get(i).call(event);
}

fan.fwt.WindowPeer.prototype.sync = function(self)
{
  var shell = this.elem.parentNode;
  this.size$(this, fan.gfx.Size.make(shell.offsetWidth, shell.offsetHeight));
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

fan.fwt.WindowPeer.prototype.icon = function(self) { return this.m_icon; }
fan.fwt.WindowPeer.prototype.icon$ = function(self, val) { this.m_icon = val; }
fan.fwt.WindowPeer.prototype.m_icon = null;

fan.fwt.WindowPeer.prototype.title = function(self) { return document.title; }
fan.fwt.WindowPeer.prototype.title$ = function(self, val) { document.title = val; }


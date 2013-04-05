//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Aug 09  Andy Frank  Creation
//

/**
 * PopupPeer.
 */
fan.webfwt.PopupPeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.PopupPeer.prototype.$ctor = function(self)
{
  this.hasKeyBinding = false;
}

// we want to get img.onload notifications
fan.webfwt.PopupPeer.prototype.notifyImgLoad = true;

fan.webfwt.PopupPeer.prototype.move = function(self, point)
{
  this.$point = point;
  this.sync(self);
}

fan.webfwt.PopupPeer.prototype.open = function(self, parent, point)
{
  // fire onBeforeOpen event listener
  var be = fan.fwt.Event.make();
  be.m_widget = self;
  be.m_id  = fan.fwt.EventId.m_open;
  var list = self.onBeforeOpen().list();
  for (var i=0; i<list.size(); i++) list.get(i).call(be);

  this.$parent = parent;
  this.$point = point;
  this.$animate = self.m_animate;

  // mount mask that functions as input blocker for modality
  var mask = document.createElement("div")
  with (mask.style)
  {
    position   = "fixed";
    top        = "0";
    left       = "0";
    width      = "100%";
    height     = "100%";
    background = "#fff";
    opacity    = "0.01";
    filter     = "progid:DXImageTransform.Microsoft.Alpha(opacity=1);"
    zIndex     = 200;
  }

  // mount shell we use to attach widgets to
  var shell = document.createElement("div")
  with (shell.style)
  {
    position   = "fixed";
    top        = "0";
    left       = "0";
    width      = "100%";
    height     = "100%";
    zIndex     = 201;
  }
  var $this = this;
  shell.onclick = function() { $this.close(self); }

  // mount popup
  var popup = this.emptyDiv();
  with (popup.style)
  {
    //background = "#eee";
    MozBorderRadius    = "5px";
    webkitBorderRadius = "5px";
    borderRadius    = "5px";
    MozBoxShadow    = "0 6px 12px rgba(0, 0, 0, 0.5)";
    webkitBoxShadow = "0 6px 12px rgba(0, 0, 0, 0.5)";
    boxShadow       = "0 6px 12px rgba(0, 0, 0, 0.5)";
    if (this.$animate)
    {
      MozTransform    = "scale(0.75)";
      webkitTransform = "scale(0.75)";
      opacity = "0.0";
    }
  }
  popup.onclick = function(e)
  {
    // make sure clicks inside content don't close popup
    if (!e) var e = window.event;
    e.cancelBubble = true;
    if (e.stopPropagation) e.stopPropagation();
  }

  // attach key bindings
  if (!this.hasKeyBinding)
  {
    this.hasKeyBinding = true;
    self.onKeyDown().add(fan.sys.Func.make(
      fan.sys.List.make(fan.sys.Param.$type, [new fan.sys.Param("it","fwt::Event",false)]),
      fan.sys.Void.$type,
      function(it) {
        if (it.m_key === fan.fwt.Key.m_esc) { self.close(); it.consume(); }
    }));
  }

  // attach to DOM
  shell.appendChild(popup);
  this.attachTo(self, popup);
  document.body.appendChild(mask);
  document.body.appendChild(shell);
  self.relayout();

  // cache elements so we can remove when we close
  this.$mask = mask;
  this.$shell = shell;

  // animate open and resizes
  if (this.$animate)
  {
    var tx = "-transform 100ms, ";
    var anim = "opacity 100ms";
    popup.style.MozTransition = "-moz" + tx + anim;
    popup.style.MozTransform  = "scale(1.0)";
    popup.style.webkitTransition = "-webkit" + tx + anim;
    popup.style.webkitTransform = "scale(1.0)";
    popup.style.opacity = "1.0";
  }

  setTimeout(function() {
    // try to focus first form element - give DOM a few ms
    // to layout content before we attempt to focus
    var elem = fan.fwt.DialogPeer.findFormControl(popup);
    if (elem != null) elem.focus();
    else self.focus();

    // fire onOpen event listener
    var evt = fan.fwt.Event.make();
    evt.m_widget = self;
    evt.m_id     = fan.fwt.EventId.m_open;
    var list = self.onOpen().list();
    for (var i=0; i<list.size(); i++) list.get(i).call(evt);
  }, 50);

  // attach resize animations
  if (this.$animate)
  {
    setTimeout(function() {
      tx += "top 250ms, left 250ms, width 250ms, height 250ms";
      popup.style.MozTransition    = "-moz" + tx;
      popup.style.webkitTransition = "-webkit" + tx;
    }, 100);
  }

  // 16 May 2012: Chrome 19 appears to have resolved this issue
  // // 26 Jan 2012: Chrome contains a bug where scrolling is broken
  // // for elements that have webkit-transform applied - so allow
  // // animation to comlete, then remove:
  // //
  // // http://code.google.com/p/chromium/issues/detail?id=106162
  // if (fan.fwt.DesktopPeer.$isChrome)
  // {
  //   setTimeout(function() {
  //     popup.style.webkitTransform = "none";
  //     popup.style.webkitTransition = anim;
  //   }, 150);
  // }
}

fan.webfwt.PopupPeer.prototype.close = function(self)
{
  // short-cirtuit if not already open
  if (this.$shell.parentNode == null) return;

  var evt = fan.fwt.Event.make();
  evt.m_id = fan.fwt.EventId.m_close;
  evt.m_widget = self;
  var list = self.onClose().list();
  for (var i=0; i<list.size(); i++) list.get(i).call(evt);

  // animate close
  if (this.$shell && this.$animate)
  {
    var popup = this.$shell.firstChild;
    popup.style.opacity = "0.0";
    popup.style.MozTransform    = "scale(0.75)";
    popup.style.webkitTransform = "scale(0.75)";
  }

  // allow animation to complete
  var $this = this;
  setTimeout(function() {
    if ($this.$shell) $this.$shell.parentNode.removeChild($this.$shell);
    if ($this.$mask) $this.$mask.parentNode.removeChild($this.$mask);
  }, 100);
}

fan.webfwt.PopupPeer.prototype.sync = function(self)
{
  var content = self.content();
  if (content == null || content.peer.elem == null) return;

  var pref  = self.prefSize();
  var p = this.$parent.posOnDisplay();
  var x = p.m_x + this.$point.m_x + 1;
  var y = p.m_y + this.$point.m_y;
  var w = pref.m_w;
  var h = pref.m_h;

       if (self.m_halign == fan.gfx.Halign.m_center) { x -= Math.floor(w/2) }
  else if (self.m_halign == fan.gfx.Halign.m_left)   { x -= w }

       if (self.m_valign == fan.gfx.Valign.m_center) { y -= Math.floor(h/2) }
  else if (self.m_valign == fan.gfx.Valign.m_top)    { y -= h }

  // restrict size to viewport
  var vp = fan.dom.Win.cur().viewport();
  if (w > vp.m_w-12) { x=6; w=vp.m_w-12; }
  if (h > vp.m_h-12) { y=6; h=vp.m_h-12; }
  if (x+w >= vp.m_w-6) x = vp.m_w-w-6;
  if (y+h >= vp.m_h-6) y = vp.m_h-h-6;
  if (x < 6) x = 6;
  if (y < 6) y = 6;

  this.pos$(self, fan.gfx.Point.make(x, y));
  this.size$(self, fan.gfx.Size.make(w, h));
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}


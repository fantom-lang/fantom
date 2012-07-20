//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Aug 09  Andy Frank  Creation
//

/**
 * SheetPeer.
 */
fan.webfwt.SheetPeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.SheetPeer.prototype.$ctor = function(self)
{
  this.hasKeyBinding = false;
}

// we want to get img.onload notifications
fan.webfwt.SheetPeer.prototype.notifyImgLoad = true;

fan.webfwt.SheetPeer.prototype.open = function(self, win)
{
  this.$window = win;

  // buildContent if not built
  if (self.m_content == null) self.buildContent();

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

  // mount sheet
  var sheet = this.emptyDiv();
  with (sheet.style)
  {
    MozBoxShadow    = "0 5px 12px #555";
    webkitBoxShadow = "0 5px 12px #555";
    boxShadow       = "0 5px 12px #555";
    overflow = "hidden";
  }

  // attach key bindings
  if (!this.hasKeyBinding)
  {
    this.hasKeyBinding = true;
    self.onKeyDown().add(fan.sys.Func.make(
      fan.sys.List.make(fan.sys.Param.$type, [new fan.sys.Param("it","fwt::Event",false)]),
      fan.sys.Void.$type,
      function(it) {
        if (it.m_key === fan.fwt.Key.m_esc) { self.close(null); it.consume(); }
    }));
  }

  // attach to DOM
  shell.appendChild(sheet);
  this.attachTo(self, sheet);
  document.body.appendChild(mask);
  document.body.appendChild(shell);
  self.relayout();

  // cache elements so we can remove when we close
  this.$mask = mask;
  this.$shell = shell;

  // cache height so we can animate
  var height = sheet.offsetHeight;
  sheet.style.height = "0px";
  var dummy = sheet.offsetHeight;  // force reflow

  // animate open
  sheet.style.MozTransition    = "height 250ms";
  sheet.style.webkitTransition = "height 250ms";
  sheet.style.height = height + "px";

  // try to focus first form element - give DOM a few ms
  // to layout content before we attempt to focus
  setTimeout(function() {
    var elem = fan.fwt.DialogPeer.findFormControl(sheet);
    if (elem != null) elem.focus()
    else self.focus()
  }, 50);

  // attach resize animations
  setTimeout(function() {
    sheet.style.MozTransition    = "left 250ms, width 250ms, height 250ms";
    sheet.style.webkitTransition = "left 250ms, width 250ms, height 250ms";
  }, 100);
}

fan.webfwt.SheetPeer.prototype.close = function(self, result)
{
  // short-cirtuit if not already open
  if (this.$shell.parentNode == null) return;

  var evt = fan.fwt.Event.make();
  evt.m_id = fan.fwt.EventId.m_close;
  evt.m_widget = self;
  evt.m_data = result;
  var list = self.onClose().list();
  for (var i=0; i<list.size(); i++) list.get(i).call(evt);

  // animate close
  if (this.$shell)
  {
    var sheet = this.$shell.firstChild;
    sheet.style.MozTransition    = "height 250ms";
    sheet.style.webkitTransition = "height 250ms";
    sheet.style.height = "0px";
  }

  // allow animation to complete
  var $this = this;
  setTimeout(function() {
    if ($this.$shell) $this.$shell.parentNode.removeChild($this.$shell);
    if ($this.$mask) $this.$mask.parentNode.removeChild($this.$mask);
  }, 250);
}

fan.webfwt.SheetPeer.prototype.sync = function(self)
{
  var content = self.content();
  if (content == null || content.peer.elem == null) return;

  var content = this.$window.content();
  var cp = content.posOnDisplay();
  var cs = content.size();

  var pref = self.prefSize();
  var w = pref.m_w;
  var h = pref.m_h;
  var x = cp.m_x + ((cs.m_w - w) / 2);
  var y = cp.m_y + 1;

  // restrict size to viewport
  var vp = fan.dom.Win.cur().viewport();
  if (w > vp.m_w-12) { x=6; w=vp.m_w-12; }
  if (h > vp.m_h-12) { y=6; h=vp.m_h-12; }

  this.pos$(self, fan.gfx.Point.make(x, y));
  this.size$(self, fan.gfx.Size.make(w, h));
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}


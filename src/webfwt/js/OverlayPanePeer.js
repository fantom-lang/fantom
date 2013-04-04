//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Apr 2013  Andy Frank  Creation
//

/**
 * OverlayPanePeer.
 */
fan.webfwt.OverlayPanePeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.OverlayPanePeer.prototype.$ctor = function(self)
{
  this.hasKeyBinding = false;
}

// we want to get img.onload notifications
fan.webfwt.OverlayPanePeer.prototype.notifyImgLoad = true;

fan.webfwt.OverlayPanePeer.prototype.move = function(self, point)
{
  this.$point = point;
  this.sync(self);
}

fan.webfwt.OverlayPanePeer.prototype.open = function(self, parent, point)
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

  // mount overlay
  this.$overlay = this.emptyDiv();
  with (this.$overlay.style)
  {
    position = "absolute";
    borderRadius    = "5px";
    MozBoxShadow    = "0 6px 12px rgba(0, 0, 0, 0.5)";
    webkitBoxShadow = "0 6px 12px rgba(0, 0, 0, 0.5)";
    boxShadow       = "0 6px 12px rgba(0, 0, 0, 0.5)";
    zIndex   = 1001;
    if (this.$animate)
    {
      MozTransform    = "scale(0.75)";
      webkitTransform = "scale(0.75)";
      opacity = "0.0";
    }
  }

  // attach to DOM
  this.attachTo(self, this.$overlay);
  document.body.appendChild(this.$overlay);
  self.relayout();

  // animate open and resizes
  if (this.$animate)
  {
    var tx = "-transform 100ms, ";
    var anim = "opacity 100ms";
    with (this.$overlay.style)
    {
      MozTransition = "-moz" + tx + anim;
      MozTransform  = "scale(1.0)";
      webkitTransition = "-webkit" + tx + anim;
      webkitTransform = "scale(1.0)";
      opacity = "1.0";
    }
  }

  setTimeout(function() {
    // fire onOpen event listener
    var evt = fan.fwt.Event.make();
    evt.m_widget = self;
    evt.m_id     = fan.fwt.EventId.m_open;
    var list = self.onOpen().list();
    for (var i=0; i<list.size(); i++) list.get(i).call(evt);
  }, 50);

  // // attach resize animations
  // if (this.$animate)
  // {
  //   setTimeout(function() {
  //     tx += "top 250ms, left 250ms, width 250ms, height 250ms";
  //     popup.style.MozTransition    = "-moz" + tx;
  //     popup.style.webkitTransition = "-webkit" + tx;
  //   }, 100);
  // }
}

fan.webfwt.OverlayPanePeer.prototype.close = function(self)
{
  // short-cirtuit if not already open
  var overlay = this.$overlay;
  if (!overlay || overlay.parentNode == null) return;

  // fire onClsoe event
  var evt = fan.fwt.Event.make();
  evt.m_id = fan.fwt.EventId.m_close;
  evt.m_widget = self;
  var list = self.onClose().list();
  for (var i=0; i<list.size(); i++) list.get(i).call(evt);

  // animate close
  if (overlay && this.$animate)
  {
    overlay.style.opacity = "0.0";
    overlay.style.MozTransform    = "scale(0.75)";
    overlay.style.webkitTransform = "scale(0.75)";
  }

  // allow animation to complete
  setTimeout(function() {
     if (overlay) overlay.parentNode.removeChild(overlay);
  }, 100);
}

fan.webfwt.OverlayPanePeer.prototype.sync = function(self)
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


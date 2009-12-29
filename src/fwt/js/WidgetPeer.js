//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 09  Andy Frank  Creation
//

/**
 * WidgetPeer.
 */
fan.fwt.WidgetPeer = fan.sys.Obj.$extend(fan.sys.Obj);
fan.fwt.WidgetPeer.prototype.$ctor = function(self) {}

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.prototype.repaint = function(self)
{
  this.sync(self);
}

fan.fwt.WidgetPeer.prototype.relayout = function(self)
{
  // short-circuit if not mounted
  if (this.elem == null) return;

  this.sync(self);
  if (self.onLayout) self.onLayout();

  var kids = self.m_kids;
  for (var i=0; i<kids.size(); i++)
  {
    var kid = kids.get(i);
    kid.peer.relayout(kid);
  }

  return self;
}

fan.fwt.WidgetPeer.prototype.posOnDisplay = function(self)
{
  var x = this.m_pos.m_x;
  var y = this.m_pos.m_y;
  var p = self.parent();
  while (p != null)
  {
    x += p.peer.m_pos.m_x;
    y += p.peer.m_pos.m_y;
    if (p instanceof fan.fwt.Dialog)
    {
      var dlg = p.peer.elem.parentNode;
      x += dlg.offsetLeft;
      y += dlg.offsetTop;
    }
    p = p.parent();
  }
  return fan.gfx.Point.make(x, y);
}

fan.fwt.WidgetPeer.prototype.prefSize = function(self, hints)
{
  // cache size
  var oldw = this.elem.style.width;
  var oldh = this.elem.style.height;

  // sync and measure pref
  this.sync(self);
  this.elem.style.width  = "auto";
  this.elem.style.height = "auto";
  var pw = this.elem.offsetWidth;
  var ph = this.elem.offsetHeight;

  // restore old size
  this.elem.style.width  = oldw;
  this.elem.style.height = oldh;
  return fan.gfx.Size.make(pw, ph);
}

fan.fwt.WidgetPeer.prototype.pack = function(self)
{
  var pref = self.prefSize();
  self.size$(fan.gfx.Size.make(pref.m_w, pref.m_h));
  self.relayout();
  return self;
}

fan.fwt.WidgetPeer.prototype.enabled = function(self) { return this.m_enabled; }
fan.fwt.WidgetPeer.prototype.enabled$ = function(self, val)
{
  this.m_enabled = val;
  if (this.elem != null) this.sync(self);
}
fan.fwt.WidgetPeer.prototype.m_enabled = true;

fan.fwt.WidgetPeer.prototype.visible = function(self) { return this.m_visible; }
fan.fwt.WidgetPeer.prototype.visible$ = function(self, val) { this.m_visible = val; }
fan.fwt.WidgetPeer.prototype.m_visible = true;

fan.fwt.WidgetPeer.prototype.pos = function(self) { return this.m_pos; }
fan.fwt.WidgetPeer.prototype.pos$ = function(self, val) { this.m_pos = val; }
fan.fwt.WidgetPeer.prototype.m_pos = fan.gfx.Point.make(0,0);

fan.fwt.WidgetPeer.prototype.size = function(self) { return this.m_size; }
fan.fwt.WidgetPeer.prototype.size$ = function(self, val) { this.m_size = val; }
fan.fwt.WidgetPeer.prototype.m_size = fan.gfx.Size.make(0,0);

//////////////////////////////////////////////////////////////////////////
// Focus
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.prototype.focus = function(self)
{
}

//////////////////////////////////////////////////////////////////////////
// Attach
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.prototype.attached = function(self)
{
}

fan.fwt.WidgetPeer.prototype.attach = function(self)
{
  // short circuit if I'm already attached
  if (this.elem != null) return;

  // short circuit if my parent isn't attached
  var parent = self.m_parent;
  if (parent == null || parent.peer.elem == null) return;

  // create control and initialize
  var elem = this.create(parent.peer.elem, self);
  this.attachTo(self, elem);

  // callback on parent
  //parent.peer.childAdded(self);
}

fan.fwt.WidgetPeer.prototype.attachTo = function(self, elem)
{
  // sync to elem
  this.elem = elem;
  this.sync(self);
  this.attachEvents(self, fan.fwt.EventId.m_mouseEnter, elem, "mouseover",  self.m_onMouseEnter.list());
  this.attachEvents(self, fan.fwt.EventId.m_mouseExit,  elem, "mouseout",   self.m_onMouseExit.list());
  this.attachEvents(self, fan.fwt.EventId.m_mouseDown,  elem, "mousedown",  self.m_onMouseDown.list());
  this.attachEvents(self, fan.fwt.EventId.m_mouseMove,  elem, "mousemove",  self.m_onMouseMove.list());
  this.attachEvents(self, fan.fwt.EventId.m_mouseUp,    elem, "mouseup",    self.m_onMouseUp.list());
  //this.attachEvents(self, fan.fwt.EventId.m_mouseHover, elem, "mousehover", self.m_onMouseHover.list());
  //this.attachEvents(self, fan.fwt.EventId.m_mouseWheel, elem, "mousewheel", self.m_onMouseWheel.list());

  // recursively attach my children
  var kids = self.m_kids;
  for (var i=0; i<kids.size(); i++)
  {
    var kid = kids.get(i);
    kid.peer.attach(kid);
  }
}

fan.fwt.WidgetPeer.prototype.attachEvents = function(self, evtId, elem, event, list)
{
  var peer = this;
  for (var i=0; i<list.size(); i++)
  {
    var meth = list.get(i);
    var func = function(e)
    {
      // find pos relative to widget
      var dis = peer.posOnDisplay(self);
      var rel = fan.gfx.Point.make(e.clientX-dis.m_x, e.clientY-dis.m_y);

      // TODO - need to fix for IE
      // TODO - only valid for mouseDown - so need to clean up this code
      var evt = fan.fwt.Event.make();
      evt.m_id = evtId;
      evt.m_pos = rel;
      evt.m_widget = self;
      //evt.count =
      //evt.key =
      meth(evt);
    }

    if (elem.addEventListener)
      elem.addEventListener(event, func, false);
    else
      elem.attachEvent("on"+event, func);
  }
}

fan.fwt.WidgetPeer.prototype.checkKeyListeners = function(self) {}

fan.fwt.WidgetPeer.prototype.create = function(parentElem, self)
{
  var div = this.emptyDiv();
  parentElem.appendChild(div);
  return div;
}

fan.fwt.WidgetPeer.prototype.emptyDiv = function()
{
  var div = document.createElement("div");
  with (div.style)
  {
    position = "absolute";
    overflow = "hidden";
    top  = "0";
    left = "0";
  }
  return div;
}

fan.fwt.WidgetPeer.prototype.detach = function(self)
{
  // recursively detach my children
  var kids = self.m_kids;
  for (var i=0; i<kids.size(); i++)
  {
    var kid = kids.get(i);
    kid.peer.detach(kid);
  }

  // detach myself
  var elem = self.peer.elem;
  if (elem != null)
    elem.parentNode.removeChild(elem);
  delete self.peer.elem;
}

//////////////////////////////////////////////////////////////////////////
// Widget/Element synchronization
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.prototype.sync = function(self, w, h)  // w,h override
{
  with (this.elem.style)
  {
    if (w === undefined) w = this.m_size.m_w;
    if (h === undefined) h = this.m_size.m_h;

    // TEMP fix for IE
    if (w < 0) w = 0;
    if (h < 0) h = 0;

    display = this.m_visible ? "block" : "none";
    left    = this.m_pos.m_x  + "px";
    top     = this.m_pos.m_y  + "px";
    width   = w + "px";
    height  = h + "px";
  }
}

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.setBg = function(elem, brush)
{
  with (elem.style)
  {
    if (brush == null) { background = "none"; return; }
    if (brush instanceof fan.gfx.Color) { background = brush.toCss(); return; }
    if (brush instanceof fan.gfx.Gradient)
    {
      var c1 = brush.m_c1.toCss();
      var c2 = brush.m_c2.toCss();

      // set background to first stop for fallback if gradeints not supported
      background = c1;

      // IE throws here, so trap and use filter in catch
      try
      {
        backgroundImage = "-moz-linear-gradient(top, " + c1 + ", " + c2 + ")";
        backgroundImage = "-webkit-gradient(linear, 0% 0%, 0% 100%, from(" + c1 + "), to(" + c2 + "))";
      }
      catch (err)
      {
        filter = "progid:DXImageTransform.Microsoft.Gradient(" +
          "StartColorStr=" + c1 + ", EndColorStr=" + c2 + ")";
      }

      return;
    }
    if (brush instanceof fan.gfx.Pattern)
    {
      var str = "";
      var bg  = brush.m_bg;
      if (bg != null) str += bg.toCss() + ' ';
      str += 'url(' + brush.m_image.m_uri + ') repeat-x';
      background = str;
      return;
    }
  }
}


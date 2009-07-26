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

fan.fwt.WidgetPeer.prototype.relayout = function(self)
{
  // short-circuit if not mounted
  if (this.elem == null) return;

  this.sync(self);
  if (self.onLayout) self.onLayout();

  var kids = self.m_kids;
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
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

fan.fwt.WidgetPeer.prototype.enabled = function(self) { return this.m_enabled; }
fan.fwt.WidgetPeer.prototype.enabled$ = function(self, val) { this.m_enabled = val; }
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
  this.attachEvents(elem, "mousedown", self.m_onMouseDown.list());
  // rest of events...

  // recursively attach my children
  var kids = self.m_kids;
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    kid.peer.attach(kid);
  }
}

fan.fwt.WidgetPeer.prototype.attachEvents = function(elem, event, list)
{
  for (var i=0; i<list.length; i++)
  {
    var meth = list[i];
    var func = function(e)
    {
      // TODO - need to fix for IE
      // TODO - only valid for mouseDown - so need to clean up this code
      var evt = new fan.fwt.Event();
      evt.m_id = fan.fwt.EventId.m_mouseDown;
      evt.m_pos = fan.gfx.Point.make(e.clientX, e.clientY);
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
  var elem = self.peer.elem;
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
    if (w == undefined) w = this.m_size.m_w;
    if (h == undefined) h = this.m_size.m_h;

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


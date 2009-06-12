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
var fwt_WidgetPeer = sys_Obj.$extend(sys_Obj);
fwt_WidgetPeer.prototype.$ctor = function(self) {}

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

fwt_WidgetPeer.prototype.relayout = function(self)
{
  this.sync(self);
  if(self.onLayout) self.onLayout();

  var kids = self.kids;
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    kid.peer.relayout(kid);
  }

  return self;
}

fwt_WidgetPeer.prototype.prefSize = function(self, hints)
{
  // cache size
  var oldw = this.elem.style.width;
  var oldh = this.elem.style.height;

  // sync and measure pref
  this.elem.style.width  = "auto";
  this.elem.style.height = "auto";
  var pw = this.elem.offsetWidth;
  var ph = this.elem.offsetHeight;

  // restore old size
  this.elem.style.width  = oldw;
  this.elem.style.height = oldh;
  return gfx_Size.make(pw, ph);
}

fwt_WidgetPeer.prototype.enabled$get = function(self) { return this.enabled; }
fwt_WidgetPeer.prototype.enabled$set = function(self, val) { this.enabled = val; }
fwt_WidgetPeer.prototype.enabled = true;

fwt_WidgetPeer.prototype.visible$get = function(self) { return this.visible; }
fwt_WidgetPeer.prototype.visible$set = function(self, val) { this.visible = val; }
fwt_WidgetPeer.prototype.visible = true;

fwt_WidgetPeer.prototype.pos$get = function(self) { return this.pos; }
fwt_WidgetPeer.prototype.pos$set = function(self, val) { this.pos = val; }
fwt_WidgetPeer.prototype.pos = gfx_Point.make(0,0);

fwt_WidgetPeer.prototype.size$get = function(self) { return this.size; }
fwt_WidgetPeer.prototype.size$set = function(self, val) { this.size = val; }
fwt_WidgetPeer.prototype.size = gfx_Size.make(0,0);

//////////////////////////////////////////////////////////////////////////
// Attach
//////////////////////////////////////////////////////////////////////////

fwt_WidgetPeer.prototype.attached = function(self)
{
}

fwt_WidgetPeer.prototype.attach = function(self)
{
  // short circuit if I'm already attached
  if (this.elem != null) return;

  // short circuit if my parent isn't attached
  var parent = self.parent;
  if (parent == null || parent.peer.elem == null) return;

  // create control and initialize
  var elem = this.create(parent.peer.elem);
  this.attachTo(self, elem);

  // callback on parent
  //parent.peer.childAdded(self);
}

fwt_WidgetPeer.prototype.attachTo = function(self, elem)
{
  // sync to elem
  this.elem = elem;
  this.sync(self);
  this.attachEvents(elem, "mousedown", self.onMouseDown.list());
  // rest of events...

  // recursively attach my children
  var kids = self.kids;
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    kid.peer.attach(kid);
  }
}

fwt_WidgetPeer.prototype.attachEvents = function(elem, event, list)
{
  for (var i=0; i<list.length; i++)
  {
    if (elem.addEventListener)
      elem.addEventListener(event, list[i], false);
    else
      elem.attachEvent("on"+event, list[i]);
  }
}

fwt_WidgetPeer.prototype.create = function(parentElem)
{
  var div = this.emptyDiv();
  parentElem.appendChild(div);
  return div;
}

fwt_WidgetPeer.prototype.emptyDiv = function()
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

fwt_WidgetPeer.prototype.detach = function(self)
{
  var elem = self.peer.elem;
  elem.parentNode.removeChild(elem);
}

//////////////////////////////////////////////////////////////////////////
// Widget/Element synchronization
//////////////////////////////////////////////////////////////////////////

fwt_WidgetPeer.prototype.sync = function(self, w, h)  // w,h override
{
  with (this.elem.style)
  {
    if (w == undefined) w = this.size.w;
    if (h == undefined) h = this.size.h;

    // TEMP fix for IE
    if (w < 0) w = 0;
    if (h < 0) h = 0;

    display = this.visible ? "block" : "none";
    left    = this.pos.x  + "px";
    top     = this.pos.y  + "px";
    width   = w + "px";
    height  = h + "px";
  }
}


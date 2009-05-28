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

fwt_WidgetPeer.prototype.$ctor = function(self)
{
  //this.self = self;
  this.elem = null;
}

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

fwt_WidgetPeer.prototype.relayout = function(self)
{
  this.sync(self);
  self.onLayout();

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

fwt_WidgetPeer.prototype.visible$get = function() { return this.visible; }
fwt_WidgetPeer.prototype.visible$set = function(val) { this.visible = val; }
fwt_WidgetPeer.prototype.visible = true;

fwt_WidgetPeer.prototype.pos$get = function() { return this.pos; }
fwt_WidgetPeer.prototype.pos$set = function(val) { this.pos = val; }
fwt_WidgetPeer.prototype.pos = gfx_Point.make(0,0);

fwt_WidgetPeer.prototype.size$get = function() { return this.size; }
fwt_WidgetPeer.prototype.size$set = function(val) { this.size = val; }
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

  // recursively attach my children
  var kids = self.kids;
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    kid.peer.attach(kid);
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

fwt_WidgetPeer.prototype.detach = function(self) {}

//////////////////////////////////////////////////////////////////////////
// Widget/Element synchronization
//////////////////////////////////////////////////////////////////////////

fwt_WidgetPeer.prototype.sync = function(self, w, h)  // w,h override
{
  with (this.elem.style)
  {
    if (w == undefined) w = this.size.w;
    if (h == undefined) h = this.size.h;

    display = this.visible ? "block" : "none";
    left    = this.pos.x  + "px";
    top     = this.pos.y  + "px";
    width   = w + "px";
    height  = h + "px";
  }
}


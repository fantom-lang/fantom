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
  self.onLayout();

  var peer = self.peer;
  with (peer.elem.style)
  {
    left    = peer.pos.x  + "px";
    top     = peer.pos.y  + "px";
    width   = peer.size.w + "px";
    height  = peer.size.h + "px";
    display = peer.visible ? "block" : "none";
  }

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
  var elem = self.peer.elem;
  var oldw = elem.style.width;
  var oldh = elem.style.height;
  elem.style.width = null;
  elem.style.height = null;
  var pw = elem.offsetWidth;
  var ph = elem.offsetHeight;
  elem.style.width = oldw;
  elem.style.height = oldh;
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
}

fwt_WidgetPeer.prototype.attachTo = function(self, parent)
{
  //var elem = this.create(self);
  var elem = self.peer.create(self);
  self.peer.elem = elem;

  // recursively attach my children
  var kids = self.kids;
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    kid.peer.attachTo(kid, elem);
  }

  parent.appendChild(elem);
}

fwt_WidgetPeer.prototype.create = function(self)
{
  var div = document.createElement("div");
  with (div.style)
  {
    position = "absolute";
    overflow = "hidden";
    top      = "0";
    left     = "0";
  }
  return div;
}

fwt_WidgetPeer.prototype.detach = function(self) {}


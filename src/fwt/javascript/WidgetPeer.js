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
}

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

fwt_WidgetPeer.prototype.relayout = function(self)
{
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
  // TODO??
  return gfx_Size.make(100, 100);
}

fwt_WidgetPeer.prototype.visible$get = function() { return this.visible; }
fwt_WidgetPeer.prototype.visible$set = function(val)
{
  this.visible = val;
  this.elem.style.display = val ? "block" : "none";
}
fwt_WidgetPeer.prototype.visible = true;

fwt_WidgetPeer.prototype.pos$get = function() { return this.pos; }
fwt_WidgetPeer.prototype.pos$set = function(val)
{
  this.pos = val;
  this.elem.style.left = val.x + "px";
  this.elem.style.top  = val.y + "px";
}
fwt_WidgetPeer.prototype.pos = gfx_Point.make(0,0);

fwt_WidgetPeer.prototype.size$get = function() { return this.size; }
fwt_WidgetPeer.prototype.size$set = function(val)
{
  this.size = val;
  this.elem.style.width  = val.w + "px";
  this.elem.style.height = val.h + "px";
}
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

fwt_WidgetPeer.prototype.attachTo = function(self, elem)
{
  var child = this.create(self);
  self.peer.elem = child;

  // recursively attach my children
  var kids = self.kids;
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    kid.peer.attachTo(kid, child);
  }

  elem.appendChild(child);
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


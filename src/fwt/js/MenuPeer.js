//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jul 09  Andy Frank  Creation
//

/**
 * MenuPeer.
 */
fan.fwt.MenuPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.MenuPeer.prototype.$ctor = function(self) {}

fan.fwt.MenuPeer.prototype.open = function(self, parent, point)
{
  this.$parent = parent;
  this.$point = point;

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
  }
  var $this = this;
  shell.onclick = function() { $this.close(); }

  // mount menu content
  var content = this.emptyDiv();
  with (content.style)
  {
    background = "#fff";
    opacity    = "0.95";
    padding    = "5px 0";
    MozBoxShadow    = "0 5px 12px #555";
    webkitBoxShadow = "0 5px 12px #555";
    MozBorderRadius     = "5px";
    webkitBorderRadius  = "5px";
  }

  // attach to DOM
  shell.appendChild(content);
  this.attachTo(self, content);
  document.body.appendChild(mask);
  document.body.appendChild(shell);
  self.relayout();

  // cache elements so we can remove when we close
  this.$mask = mask;
  this.$shell = shell;
}

fan.fwt.MenuPeer.prototype.close = function()
{
  if (this.$shell) this.$shell.parentNode.removeChild(this.$shell);
  if (this.$mask) this.$mask.parentNode.removeChild(this.$mask);
}

fan.fwt.MenuPeer.prototype.relayout = function(self)
{
  fan.fwt.WidgetPeer.prototype.relayout.call(this, self);

  var dx = 0; // account for padding
  var dy = 5; // account for padding
  var pw = 0;
  var ph = 0;

  var kids = self.m_kids;
  for (var i=0; i<kids.size(); i++)
    pw = Math.max(pw, kids.get(i).prefSize().m_w);

  pw += 8; // account for padding

  for (var i=0; i<kids.size(); i++)
  {
    var kid  = kids.get(i);
    var pref = kid.prefSize();
    var mh = pref.m_h + 2;  // account for padding

    kid.pos$(fan.gfx.Point.make(dx, dy));
    kid.size$(fan.gfx.Size.make(pw, mh));
    kid.peer.sync(kid);
    dy += mh;
    ph += mh;
  }

  var pp = this.$parent.posOnWindow();
  var ps = this.$parent.size();
  var x = pp.m_x + this.$point.m_x;
  var y = pp.m_y + this.$point.m_y;
  var w = pw;
  var h = ph;

  // adjust for window root
  var win = this.$parent.window();
  if (win != null && win.peer.root != null)
  {
    x += win.peer.root.offsetLeft;
    y += win.peer.root.offsetTop;
  }

  // check if we need to swap dir
  var shell = this.elem.parentNode;
  if (x+w >= shell.offsetWidth-4)  x = pp.m_x + ps.m_w - w -1;
  if (y+h >= shell.offsetHeight-4) y = pp.y - h;

  this.pos$(self, fan.gfx.Point.make(x, y));
  this.size$(self, fan.gfx.Size.make(w, h));
  this.sync(self);
}


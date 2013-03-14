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
fan.fwt.MenuPeer.prototype.$ctor = function(self)
{
  this.hasKeyBinding = false;
  this.selIndex = null;
}

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

  // mount menu content
  var content = this.emptyDiv();
  content.tabIndex = 0;
  with (content.style)
  {
    background = "#fff";
    opacity    = "0.95";
    padding    = "5px 0";
    MozBoxShadow    = "0 5px 12px #555";
    webkitBoxShadow = "0 5px 12px #555";
    boxShadow       = "0 5px 12px #555";
    MozBorderRadius     = "5px";
    webkitBorderRadius  = "5px";
    borderRadius        = "5px";
    overflowY = "auto";
  }

  // attach event handlers
  if (!this.hasKeyBinding)
  {
    this.hasKeyBinding = true;
    self.onKeyDown().add(fan.sys.Func.make(
      fan.sys.List.make(fan.sys.Param.$type, [new fan.sys.Param("it","fwt::Event",false)]),
      fan.sys.Void.$type,
      function(it)
      {
        if (it.m_key == fan.fwt.Key.m_esc)   { $this.close(self);   it.consume(); }
        if (it.m_key == fan.fwt.Key.m_up)    { $this.selPrev(self); it.consume(); }
        if (it.m_key == fan.fwt.Key.m_down)  { $this.selNext(self); it.consume(); }
        if (it.m_key == fan.fwt.Key.m_space) { $this.invoke(self);  it.consume(); }
      }));
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

  // focus menu widget
  setTimeout(function() { content.focus(); }, 50);
}

fan.fwt.MenuPeer.prototype.selPrev = function(self)
{
  var kids  = self.children();
  var size  = kids.size();
  var index = this.selIndex;
  if (index == null) index = size;
  index--;
  if (index < 0) return;
  while (index > 0 && !kids.get(index).enabled()) index--;
  if (!kids.get(index).enabled()) return;
  kids.get(index).focus();
  this.selIndex = index;
}

fan.fwt.MenuPeer.prototype.selNext = function(self)
{
  var kids  = self.children();
  var size  = kids.size();
  var index = this.selIndex;
  if (index == null) index = -1;
  index++;
  if (index > size-1) return;
  while (index < size-1 && !kids.get(index).enabled()) index++;
  if (!kids.get(index).enabled()) return;
  kids.get(index).focus();
  this.selIndex = index;
}

fan.fwt.MenuPeer.prototype.invoke = function(self)
{
  var kids = self.children();
  var index = this.selIndex;
  if (index == null || index < 0 || index > kids.size()-1) return;

  this.close(self);
  var item = kids.get(index);
  item.peer.invoke(item);
}

fan.fwt.MenuPeer.prototype.close = function(self)
{
  // remove DOM node
  if (this.$shell) this.$shell.parentNode.removeChild(this.$shell);
  if (this.$mask) this.$mask.parentNode.removeChild(this.$mask);

  // refocus the parent widget
  this.$parent.focus();

  // fire onClose event
  var evt = fan.fwt.Event.make();
  evt.m_id = fan.fwt.EventId.m_close;
  evt.m_widget = self;
  var list = self.onClose().list();
  for (var i=0; i<list.size(); i++) list.get(i).call(evt);
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

  var pp = this.$parent.posOnDisplay();
  var ps = this.$parent.size();
  var x = pp.m_x + this.$point.m_x;
  var y = pp.m_y + this.$point.m_y;
  var w = pw;
  var h = ph;

  // clip if too big
  var shell = this.elem.parentNode;
  if (h > shell.offsetHeight-24)
  {
    y = 12;
    h = shell.offsetHeight-36;
  }

  // check if we need to swap dir
  if (x+w >= shell.offsetWidth-4)  x = pp.m_x + ps.m_w - w - 1;
  if (y+h >= shell.offsetHeight-4) y = pp.m_y - h;

  this.pos$(self, fan.gfx.Point.make(x, y));
  this.size$(self, fan.gfx.Size.make(w, h));
  this.sync(self);
}


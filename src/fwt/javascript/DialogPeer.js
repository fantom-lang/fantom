//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 09  Andy Frank  Creation
//

/**
 * DialogPeer.
 */
var fwt_DialogPeer = sys_Obj.$extend(fwt_WindowPeer);
fwt_DialogPeer.prototype.$ctor = function(self) {}

fwt_DialogPeer.prototype.open = function(self)
{
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
    opacity    = "0.3";
    filter     = "progid:DXImageTransform.Microsoft.Alpha(opacity=10);"
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

  // mount window
  var elem = this.emptyDiv();
  with (elem.style)
  {
    background = "#eee";
    border     = "1px solid #555";
    MozBoxShadow               = "0 5px 12px #555";
    MozBorderRadiusTopleft     = "5px";
    MozBorderRadiusTopright    = "5px";
    webkitBoxShadow            = "0 5px 12px #555";
    webkitBorderTopLeftRadius  = "5px";
    webkitBorderTopRightRadius = "5px";
  }
  shell.appendChild(elem);
  this.attachTo(self, elem);
  document.body.appendChild(mask);
  document.body.appendChild(shell);
  self.relayout();

  // cache elements so we can remove when we close
  this.$mask = mask;
  this.$shell = shell;
}

fwt_DialogPeer.prototype.close = function(self, result)
{
  if (this.$shell) this.$shell.parentNode.removeChild(this.$shell);
  if (this.$mask) this.$mask.parentNode.removeChild(this.$mask);
  fwt_WindowPeer.prototype.close.call(this, self, result);
}

fwt_DialogPeer.prototype.sync = function(self)
{
  var content = self.content$get();
  if (content == null || content.peer.elem == null) return;

  var shell = this.elem.parentNode;
  var pref  = content.prefSize();
  var w = pref.w;
  var h = pref.h;
  var x = Math.floor((shell.offsetWidth - w) / 2);
  var y = Math.floor((shell.offsetHeight - h) / 2);

  this.pos$set(this, gfx_Point.make(x, y));
  this.size$set(this, gfx_Size.make(w, h));
  fwt_WidgetPeer.prototype.sync.call(this, self);
}

fwt_DialogPeer.prototype.title$get = function(self) { return this.title; }
fwt_DialogPeer.prototype.title$set = function(self, val) { this.title = val; }
fwt_DialogPeer.prototype.title = "";



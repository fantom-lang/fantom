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
fan.fwt.DialogPeer = fan.sys.Obj.$extend(fan.fwt.WindowPeer);
fan.fwt.DialogPeer.prototype.$ctor = function(self) {}

fan.fwt.DialogPeer.prototype.open = function(self)
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
    background = "#000";
    opacity    = "0.3";
    filter     = "progid:DXImageTransform.Microsoft.Alpha(opacity=30);"
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
  var tbar = this.emptyDiv();
  with (tbar.style)
  {
    height     = "16px";
    border     = "1px solid #404040";
    padding    = "3px 6px";
    fontWeight = "bold";
    textAlign  = "center";
    MozBorderRadiusTopleft     = "5px";
    MozBorderRadiusTopright    = "5px";
    webkitBorderTopLeftRadius  = "5px";
    webkitBorderTopRightRadius = "5px";
    backgroundColor = "#c2c2c2";
    // IE workaround
    try { backgroundImage = "-webkit-gradient(linear, 0% 0%, 0% 100%, from(#c2c2c2), to(#989898))"; } catch (err) {} // ignore
  }
  var content = this.emptyDiv();
  with (content.style)
  {
    background = "#eee";
    border     = "1px solid #404040";
    borderTop  = "none";
  }
  var dlg = this.emptyDiv();
  with (dlg.style)
  {
    MozBoxShadow    = "0 5px 12px #404040";
    webkitBoxShadow = "0 5px 12px #404040";
  }
  tbar.appendChild(document.createTextNode(this.title));
  dlg.appendChild(tbar);
  dlg.appendChild(content);
  shell.appendChild(dlg);
  this.attachTo(self, content);
  document.body.appendChild(mask);
  document.body.appendChild(shell);
  self.relayout();

  // cache elements so we can remove when we close
  this.$mask = mask;
  this.$shell = shell;
}

fan.fwt.DialogPeer.prototype.close = function(self, result)
{
  if (this.$shell) this.$shell.parentNode.removeChild(this.$shell);
  if (this.$mask) this.$mask.parentNode.removeChild(this.$mask);
  fan.fwt.WindowPeer.prototype.close.call(this, self, result);
}

fan.fwt.DialogPeer.prototype.sync = function(self)
{
  var content = self.content$get();
  if (content == null || content.peer.elem == null) return;

  var shell = this.elem.parentNode.parentNode;
  var dlg   = this.elem.parentNode;
  var tbar  = dlg.firstChild;
  var pref  = content.prefSize();

  var th = 24;
  var w  = pref.w + 2;       // +2 for border
  var h  = pref.h + th + 1;  // +1 for border
  var x  = Math.floor((shell.offsetWidth - w) / 2);
  var y  = Math.floor((shell.offsetHeight - h) / 2);

  tbar.style.width = (w-14) + "px";  // -padding/border
  with (dlg.style)
  {
    left   = x + "px";
    top    = y + "px";
    width  = w + "px";
    height = h + "px";
  }

  this.pos$set(this, fan.gfx.Point.make(0, th));
  this.size$set(this, fan.gfx.Size.make(pref.w, pref.h));
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

fan.fwt.DialogPeer.prototype.title$get = function(self) { return this.title; }
fan.fwt.DialogPeer.prototype.title$set = function(self, val) { this.title = val; }
fan.fwt.DialogPeer.prototype.title = "";



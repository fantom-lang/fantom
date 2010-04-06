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
    padding    = "3px 6px";
    color      = "#fff";
    font       = "bold " + fan.fwt.WidgetPeer.fontNormal;
    textShadow = "0 1px 1px #1c1c1c";
    textAlign  = "center";
    borderTop    = "1px solid #8d8d8d";
    borderBottom = "1px solid #303030";
    MozBorderRadiusTopleft     = "4px";
    MozBorderRadiusTopright    = "4px";
    webkitBorderTopLeftRadius  = "4px";
    webkitBorderTopRightRadius = "4px";
  }
  fan.fwt.WidgetPeer.setBg(tbar, fan.gfx.Gradient.fromStr("0% 0%, 0% 100%, #6f6f6f, #535353"));
  var content = this.emptyDiv();
  with (content.style)
  {
    background = "#eee";
  }
  var dlg = this.emptyDiv();
  with (dlg.style)
  {
    border     = "1px solid #404040";
    MozBorderRadiusTopleft     = "5px";
    MozBorderRadiusTopright    = "5px";
    webkitBorderTopLeftRadius  = "5px";
    webkitBorderTopRightRadius = "5px";
    MozBoxShadow    = "0 5px 12px #404040";
    webkitBoxShadow = "0 5px 12px #404040";
  }
  tbar.appendChild(document.createTextNode(this.m_title));
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

  // try to focus first form element
  var elem = fan.fwt.DialogPeer.findFormControl(content);
  if (elem != null)
  {
    // NOTE: needed to use a delay here for this to
    // work reliably, assumingly to give the renderer
    // time to layout DOM changes.
    var func = function() { elem.focus(); }
    setTimeout(func, 50);
  }
}

fan.fwt.DialogPeer.findFormControl = function(node)
{
  var tag = node.tagName;
  if (tag != null)
  {
    tag = tag.toLowerCase();
    if (tag == "input" || tag == "select" || tag == "textarea") return node;
  }
  for (var i=0; i<node.childNodes.length; i++)
  {
    var n = fan.fwt.DialogPeer.findFormControl(node.childNodes[i])
    if (n != null) return n;
  }
  return null;
}

fan.fwt.DialogPeer.prototype.close = function(self, result)
{
  if (this.$shell) this.$shell.parentNode.removeChild(this.$shell);
  if (this.$mask) this.$mask.parentNode.removeChild(this.$mask);
  fan.fwt.WindowPeer.prototype.close.call(this, self, result);
}

fan.fwt.DialogPeer.prototype.sync = function(self)
{
  var content = self.content();
  if (content == null || content.peer.elem == null) return;

  var shell = this.elem.parentNode.parentNode;
  var dlg   = this.elem.parentNode;
  var tbar  = dlg.firstChild;
  var pref  = content.prefSize();

  var th = 24;
  var w  = pref.m_w;
  var h  = pref.m_h + th;
  var x  = Math.floor((shell.offsetWidth - w) / 2);
  var y  = Math.floor((shell.offsetHeight - h) / 2);

  tbar.style.width = (w-12) + "px";  // -padding/border
  with (dlg.style)
  {
    left   = x + "px";
    top    = y + "px";
    width  = w + "px";
    height = h + "px";
  }

  this.pos$(this, fan.gfx.Point.make(0, th));
  this.size$(this, fan.gfx.Size.make(pref.m_w, pref.m_h));
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

fan.fwt.DialogPeer.prototype.title   = function(self) { return this.m_title; }
fan.fwt.DialogPeer.prototype.title$  = function(self, val) { this.m_title = val; }
fan.fwt.DialogPeer.prototype.m_title = "";



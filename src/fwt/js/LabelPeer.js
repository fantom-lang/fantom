//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 May 09  Andy Frank  Creation
//

/**
 * LabelPeer.
 */
fan.fwt.LabelPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.LabelPeer.prototype.$ctor = function(self) {}

fan.fwt.LabelPeer.prototype.text   = function(self) { return this.m_text; }
fan.fwt.LabelPeer.prototype.text$  = function(self, val) { this.m_text = val; }
fan.fwt.LabelPeer.prototype.m_text = "";

fan.fwt.LabelPeer.prototype.bg   = function(self) { return this.m_bg; }
fan.fwt.LabelPeer.prototype.bg$  = function(self, val) { this.m_bg = val; }
fan.fwt.LabelPeer.prototype.m_bg = null;

fan.fwt.LabelPeer.prototype.fg   = function(self) { return this.m_fg; }
fan.fwt.LabelPeer.prototype.fg$  = function(self, val) { this.m_fg = val; }
fan.fwt.LabelPeer.prototype.m_fg = null;

fan.fwt.LabelPeer.prototype.font   = function(self) { return this.m_font; }
fan.fwt.LabelPeer.prototype.font$  = function(self, val) { this.m_font = val; }
fan.fwt.LabelPeer.prototype.m_font = null;

fan.fwt.LabelPeer.prototype.halign   = function(self) { return this.m_halign; }
fan.fwt.LabelPeer.prototype.halign$  = function(self, val) { this.m_halign = val; }
fan.fwt.LabelPeer.prototype.m_halign = null;

fan.fwt.LabelPeer.prototype.image  = function(self) { return this.m_image; }
fan.fwt.LabelPeer.prototype.image$ = function(self, val)
{
  this.m_image = val;
  fan.fwt.FwtEnvPeer.loadImage(val, self)
}
fan.fwt.LabelPeer.prototype.m_image = null;

fan.fwt.LabelPeer.prototype.sync = function(self)
{
  var parent = this.elem;

  // remove old subtree
  while (parent.firstChild != null)
  {
    var child = parent.firstChild;
    parent.removeChild(child);
    child = null;
    delete child;
  }

  // hook for "HyperlinkLabel"
  if (self.m_uri != null)
  {
    var a = document.createElement("a");
    a.href = self.m_uri.toStr();
    parent.appendChild(a);
    parent = a;
  }

  if (this.m_image != null)
  {
    var img = document.createElement("img");
    if (this.m_text.length > 0)
    {
      img.style.verticalAlign = "middle";
      img.style.paddingRight  = "3px";
      // TODO: this requires widget to be relayed out cause prefSize has changed
      //img.onload = function() {
      //  img.style.paddingRight = Math.floor(img.height*3/16) + "px";
      //}
    }
    img.border = "0";
    img.src = this.m_image.m_uri;
    parent.appendChild(img);
  }

  // to keep height consisten for empty labels
  var text;
  if (this.m_text == "" && this.m_image == null)
  {
    text = document.createElement("span");
    text.innerHTML = "&nbsp;"
  }
  else text = document.createTextNode(this.m_text);
  parent.appendChild(text);

  // apply fg to parent elem to make <a> color correctly
  if (this.m_fg != null) parent.style.color = this.m_fg.toStr();
  with (this.elem.style)
  {
    if (this.m_bg   != null) background = this.m_bg.toStr();
    if (this.m_font != null) font = this.m_font.toStr();
    switch (this.m_halign)
    {
      case fan.gfx.Halign.m_left:   textAlign = "left"; break;
      case fan.gfx.Halign.m_fill:   textAlign = "left"; break;
      case fan.gfx.Halign.m_center: textAlign = "center"; break;
      case fan.gfx.Halign.m_right:  textAlign = "right"; break;
      default:                      textAlign = "left"; break;
    }
    whiteSpace = "nowrap";
    cursor = "default";
  }

  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}
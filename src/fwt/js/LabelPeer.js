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

fan.fwt.LabelPeer.prototype.text$get = function(self) { return this.text; }
fan.fwt.LabelPeer.prototype.text$set = function(self, val) { this.text = val; }
fan.fwt.LabelPeer.prototype.text = "";

fan.fwt.LabelPeer.prototype.bg$get = function(self) { return this.bg; }
fan.fwt.LabelPeer.prototype.bg$set = function(self, val) { this.bg = val; }
fan.fwt.LabelPeer.prototype.bg = null;

fan.fwt.LabelPeer.prototype.fg$get = function(self) { return this.fg; }
fan.fwt.LabelPeer.prototype.fg$set = function(self, val) { this.fg = val; }
fan.fwt.LabelPeer.prototype.fg = null;

fan.fwt.LabelPeer.prototype.font$get = function(self) { return this.font; }
fan.fwt.LabelPeer.prototype.font$set = function(self, val) { this.font = val; }
fan.fwt.LabelPeer.prototype.font = null;

fan.fwt.LabelPeer.prototype.halign = null;
fan.fwt.LabelPeer.prototype.halign$get = function(self) { return this.halign; }
fan.fwt.LabelPeer.prototype.halign$set = function(self, val) { this.halign = val; }

fan.fwt.LabelPeer.prototype.image$get = function(self) { return this.image; }
fan.fwt.LabelPeer.prototype.image$set = function(self, val)
{
  this.image = val;
  fan.fwt.FwtEnvPeer.loadImage(val, self)
}
fan.fwt.LabelPeer.prototype.image = null;

fan.fwt.LabelPeer.prototype.sync = function(self)
{
  while (this.elem.firstChild != null)
    this.elem.removeChild(this.elem.firstChild);

  // hook for "HyperlinkLabel"
  var parent = this.elem;
  if (self.uri != null)
  {
    var a = document.createElement("a");
    a.href = self.uri.toStr();
    parent.appendChild(a);
    parent = a;
  }

  if (this.image != null)
  {
    var img = document.createElement("img");
    if (this.text.length > 0)
    {
      img.style.verticalAlign = "middle";
      img.style.paddingRight = "3px";
    }
    img.src = this.image.uri;
    parent.appendChild(img);
  }

  var text = document.createTextNode(this.text);
  parent.appendChild(text);

  // apply fg to parent elem to make <a> color correctly
  if (this.fg != null) parent.style.color = this.fg.toStr();
  with (this.elem.style)
  {
    if (this.bg   != null) background = this.bg.toStr();
    if (this.font != null) font = this.font.toStr();
    switch (this.halign)
    {
      case fan.fwt.Halign.left:   textAlign = "left"; break;
      case fan.fwt.Halign.fill:   textAlign = "left"; break;
      case fan.fwt.Halign.center: textAlign = "center"; break;
      case fan.fwt.Halign.right:  textAlign = "right"; break;
      default:                textAlign = "left"; break;
    }
    whiteSpace = "nowrap";
    cursor = "default";
  }
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}
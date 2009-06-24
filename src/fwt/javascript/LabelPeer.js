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
var fwt_LabelPeer = sys_Obj.$extend(fwt_WidgetPeer);
fwt_LabelPeer.prototype.$ctor = function(self) {}

fwt_LabelPeer.prototype.text$get = function(self) { return this.text; }
fwt_LabelPeer.prototype.text$set = function(self, val) { this.text = val; }
fwt_LabelPeer.prototype.text = "";

fwt_LabelPeer.prototype.bg$get = function(self) { return this.bg; }
fwt_LabelPeer.prototype.bg$set = function(self, val) { this.bg = val; }
fwt_LabelPeer.prototype.bg = null;

fwt_LabelPeer.prototype.fg$get = function(self) { return this.fg; }
fwt_LabelPeer.prototype.fg$set = function(self, val) { this.fg = val; }
fwt_LabelPeer.prototype.fg = null;

fwt_LabelPeer.prototype.font$get = function(self) { return this.font; }
fwt_LabelPeer.prototype.font$set = function(self, val) { this.font = val; }
fwt_LabelPeer.prototype.font = null;

fwt_LabelPeer.prototype.halign = null;
fwt_LabelPeer.prototype.halign$get = function(self) { return this.halign; }
fwt_LabelPeer.prototype.halign$set = function(self, val) { this.halign = val; }

fwt_LabelPeer.prototype.image$get = function(self) { return this.image; }
fwt_LabelPeer.prototype.image$set = function(self, val)
{
  this.image = val;
  fwt_FwtEnvPeer.loadImage(val)
}
fwt_LabelPeer.prototype.image = null;

fwt_LabelPeer.prototype.sync = function(self)
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
      case fwt_Halign.left:   textAlign = "left"; break;
      case fwt_Halign.fill:   textAlign = "left"; break;
      case fwt_Halign.center: textAlign = "center"; break;
      case fwt_Halign.right:  textAlign = "right"; break;
      default:                textAlign = "left"; break;
    }
    whiteSpace = "nowrap";
  }
  fwt_WidgetPeer.prototype.sync.call(this, self);
}
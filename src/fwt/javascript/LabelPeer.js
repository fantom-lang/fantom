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

fwt_LabelPeer.prototype.$ctor = function(self)
{
  fwt_WidgetPeer.prototype.$ctor.call(this, self);
}

fwt_LabelPeer.prototype.text$get = function() { return this.text; }
fwt_LabelPeer.prototype.text$set = function(val) { this.text = val; }
fwt_LabelPeer.prototype.text = "";

fwt_LabelPeer.prototype.bg$get = function() { return this.bg; }
fwt_LabelPeer.prototype.bg$set = function(val) { this.bg = val; }
fwt_LabelPeer.prototype.bg = null;

fwt_LabelPeer.prototype.fg$get = function() { return this.fg; }
fwt_LabelPeer.prototype.fg$set = function(val) { this.fg = val; }
fwt_LabelPeer.prototype.fg = null;

fwt_LabelPeer.prototype.font$get = function() { return this.font; }
fwt_LabelPeer.prototype.font$set = function(val) { this.font = val; }
fwt_LabelPeer.prototype.font = null;

fwt_LabelPeer.prototype.halign = null;
fwt_LabelPeer.prototype.halign$get = function() { return this.halign; }
fwt_LabelPeer.prototype.halign$set = function(val) { this.halign = val; }

//fwt_LabelPeer.prototype.image$get = function() { return this.image; }
//fwt_LabelPeer.prototype.image$set = function(val) { this.image = val; }
//fwt_LabelPeer.prototype.image = null;

fwt_LabelPeer.prototype.sync = function(self)
{
  this.elem.innerHTML = this.text;
  with (this.elem.style)
  {
    if (this.fg   != null) color = this.fg.toStr();
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
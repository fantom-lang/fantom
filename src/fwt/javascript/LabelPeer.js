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

fwt_LabelPeer.prototype.text = "";
fwt_LabelPeer.prototype.text$get = function() { return this.text; }
fwt_LabelPeer.prototype.text$set = function(val)
{
  this.text = val;
  if (this.elem) this.elem.innerHTML = val;
}

fwt_LabelPeer.prototype.bg = null;
fwt_LabelPeer.prototype.bg$get = function() { return this.bg; }
fwt_LabelPeer.prototype.bg$set = function(val)
{
  this.bg = val;
  if (this.elem) this.elem.style.background = (val==null) ? null : val.toStr();
}

fwt_LabelPeer.prototype.fg = null;
fwt_LabelPeer.prototype.fg$get = function() { return this.fg; }
fwt_LabelPeer.prototype.fg$set = function(val)
{
  this.fg = val;
  if (this.elem) this.elem.style.color = (val==null) ? null : val.toStr();
}

fwt_LabelPeer.prototype.font = null;
fwt_LabelPeer.prototype.font$get = function() { return this.font; }
fwt_LabelPeer.prototype.font$set = function(val)
{
  this.font = val;
  if (this.elem) this.elem.style.font = (val==null) ? null : val.toStr();
}

fwt_LabelPeer.prototype.halign = null;
fwt_LabelPeer.prototype.halign$get = function() { return this.halign; }
fwt_LabelPeer.prototype.halign$set = function(val)
{
  this.halign = val;
  if (this.elem) this.doHalign(val, this.elem);
}
fwt_LabelPeer.prototype.doHalign = function(val, elem)
{
  switch (val)
  {
    case fwt_Halign.left:   elem.style.textAlign = "left";break;
    case fwt_Halign.fill:   elem.style.textAlign = "left"; break;
    case fwt_Halign.center: elem.style.textAlign = "center"; break;
    case fwt_Halign.right:  elem.style.textAlign = "right"; break;
    default:                elem.style.textAlign = null;
  }
}

//fwt_LabelPeer.prototype.image = null;
//fwt_LabelPeer.prototype.image$get = function() { return this.image; }
//fwt_LabelPeer.prototype.image$set = function(val) { this.image = val; }

fwt_LabelPeer.prototype.create = function(self)
{
  var peer = self.peer;
  var div = fwt_WidgetPeer.prototype.create.call(this, self);
  div.innerHTML = peer.text;
  if (peer.fg   != null) div.style.color = peer.fg.toStr();
  if (peer.bg   != null) div.style.background = peer.bg.toStr();
  if (peer.font != null) div.style.font = peer.font.toStr();
  if (peer.halign != null) peer.doHalign(peer.halign, div);
  return div;
}


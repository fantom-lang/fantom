//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 09  Andy Frank  Creation
//

/**
 * ButtonPeer.
 */
var fwt_ButtonPeer = sys_Obj.$extend(fwt_WidgetPeer);
fwt_ButtonPeer.prototype.$ctor = function(self) {}

fwt_ButtonPeer.prototype.font$get = function(self) { return this.font; }
fwt_ButtonPeer.prototype.font$set = function(self, val) { this.font = val; }
fwt_ButtonPeer.prototype.font = null;

fwt_ButtonPeer.prototype.image$get = function(self) { return this.image; }
fwt_ButtonPeer.prototype.image$set = function(self, val) { this.image = val; }
fwt_ButtonPeer.prototype.image = null;

fwt_ButtonPeer.prototype.selected$get = function(self) { return this.selected; }
fwt_ButtonPeer.prototype.selected$set = function(self, val) { this.selected = val; }
fwt_ButtonPeer.prototype.selected = false;

fwt_ButtonPeer.prototype.text$get = function(self) { return this.text; }
fwt_ButtonPeer.prototype.text$set = function(self, val) { this.text = val; }
fwt_ButtonPeer.prototype.text = "";

fwt_ButtonPeer.prototype.create = function(parentElem)
{
  var div = this.emptyDiv();
  with (div.style)
  {
    //font      = "bold 10pt Arial";
    padding   = "2px 4px";
    textAlign = "center";
    border    = "1px solid #555";
    cursor    = "default";
    backgroundColor = "#eee";
    // IE workaround
    try { backgroundImage = "-webkit-gradient(linear, 0% 0%, 0% 100%, from(#eee), to(#ccc))"; } catch (err) {} // ignore
//    MozBorderRadius    = "10px";
//    webkitBorderRadius = "10px";
  }
  parentElem.appendChild(div);
  return div;
}

fwt_ButtonPeer.prototype.sync = function(self)
{
  var div = this.elem;
  while (div.firstChild != null) div.removeChild(div.firstChild);
  div.appendChild(document.createTextNode(this.text));
  div.onclick = function(event)
  {
    var list = self.onAction.list();
    for (var i=0; i<list.length; i++) list[i](event);
  }
  // account for padding/border
  var w = this.size.w - 10;
  var h = this.size.h - 6;
  fwt_WidgetPeer.prototype.sync.call(this, self, w, h);
}
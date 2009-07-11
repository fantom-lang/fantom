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
fan.fwt.ButtonPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.ButtonPeer.prototype.$ctor = function(self) {}

fan.fwt.ButtonPeer.prototype.font$get = function(self) { return this.font; }
fan.fwt.ButtonPeer.prototype.font$set = function(self, val) { this.font = val; }
fan.fwt.ButtonPeer.prototype.font = null;

fan.fwt.ButtonPeer.prototype.image$get = function(self) { return this.image; }
fan.fwt.ButtonPeer.prototype.image$set = function(self, val) { this.image = val; }
fan.fwt.ButtonPeer.prototype.image = null;

fan.fwt.ButtonPeer.prototype.selected$get = function(self) { return this.selected; }
fan.fwt.ButtonPeer.prototype.selected$set = function(self, val) { this.selected = val; }
fan.fwt.ButtonPeer.prototype.selected = false;

fan.fwt.ButtonPeer.prototype.text$get = function(self) { return this.text; }
fan.fwt.ButtonPeer.prototype.text$set = function(self, val) { this.text = val; }
fan.fwt.ButtonPeer.prototype.text = "";

fan.fwt.ButtonPeer.prototype.create = function(parentElem)
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

fan.fwt.ButtonPeer.prototype.sync = function(self)
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
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}
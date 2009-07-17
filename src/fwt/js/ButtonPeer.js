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
  var outer = this.emptyDiv();
  with (outer.style)
  {
    borderRight  = "1px solid #f6f6f6";
    borderBottom = "1px solid #f6f6f6";
  }

  var middle = document.createElement("div");
  with (middle.style)
  {
    borderTop    = "1px solid #838383";
    borderBottom = "1px solid #838383";
    borderLeft   = "1px solid #a4a4a4";
    borderRight  = "1px solid #a4a4a4";
  }

  var inside = document.createElement("div");
  with (inside.style)
  {
    //font      = "bold 10pt Arial";
    padding      = "2px 4px";
    textAlign    = "center";
    borderTop    = "1px solid #fff";
    borderLeft   = "1px solid #fff";
    cursor       = "default";
    //textShadow = "0 1px 1px #fff";
    backgroundColor = "#eee";
    // IE workaround
    try { backgroundImage = "-webkit-gradient(linear, 0% 0%, 0% 100%, from(#f6f6f6), to(#dadada))"; } catch (err) {} // ignore
  }

  middle.appendChild(inside);
  outer.appendChild(middle);
  parentElem.appendChild(outer);
  return outer;
}

fan.fwt.ButtonPeer.prototype.sync = function(self)
{
  var div = this.elem.firstChild.firstChild;
  while (div.firstChild != null) div.removeChild(div.firstChild);
  div.appendChild(document.createTextNode(this.text));
  div.onclick = function(event)
  {
    var evt = new fan.fwt.Event();
    evt.id = fan.fwt.EventId.action;
    evt.widget = self;

    var list = self.onAction.list();
    for (var i=0; i<list.length; i++) list[i](evt);
  }
  // account for padding/border
  var w = this.size.w - 1;
  var h = this.size.h - 1;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}
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

fan.fwt.ButtonPeer.prototype.font = function(self) { return this.m_font; }
fan.fwt.ButtonPeer.prototype.font$ = function(self, val) { this.m_font = val; }
fan.fwt.ButtonPeer.prototype.m_font = null;

fan.fwt.ButtonPeer.prototype.image = function(self) { return this.m_image; }
fan.fwt.ButtonPeer.prototype.image$ = function(self, val) { this.m_image = val; }
fan.fwt.ButtonPeer.prototype.m_image = null;

fan.fwt.ButtonPeer.prototype.selected = function(self) { return this.m_selected; }
fan.fwt.ButtonPeer.prototype.selected$ = function(self, val) { this.m_selected = val; }
fan.fwt.ButtonPeer.prototype.m_selected = false;

fan.fwt.ButtonPeer.prototype.text = function(self) { return this.m_text; }
fan.fwt.ButtonPeer.prototype.text$ = function(self, val) { this.m_text = val; }
fan.fwt.ButtonPeer.prototype.m_text = "";

fan.fwt.ButtonPeer.prototype.create = function(parentElem, self)
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
    whiteSpace   = "nowrap";
    //textShadow = "0 1px 1px #fff";
    backgroundColor = "#eee";

    // IE workaround
    try { backgroundImage = "-webkit-gradient(linear, 0% 0%, 0% 100%, from(#f6f6f6), to(#dadada))"; } catch (err) {} // ignore
  }

  outer.onclick = function(event)
  {
    var evt = new fan.fwt.Event();
    evt.id = fan.fwt.EventId.m_action;
    evt.widget = self;

    var list = self.m_onAction.list();
    for (var i=0; i<list.length; i++) list[i](evt);
  }

  middle.appendChild(inside);
  outer.appendChild(middle);
  parentElem.appendChild(outer);
  return outer;
}

fan.fwt.ButtonPeer.prototype.sync = function(self)
{
  var div = this.elem.firstChild.firstChild;

  // remove old text node
  while (div.firstChild != null)
  {
    var child = div.firstChild;
    div.removeChild(child);
    child = null;
    delete child;
  }

  // add new text node
  div.appendChild(document.createTextNode(this.m_text));

  // account for padding/border
  var w = this.m_size.m_w - 1;
  var h = this.m_size.m_h - 1;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}
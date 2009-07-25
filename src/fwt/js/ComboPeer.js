//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jun 09  Andy Frank  Creation
//

/**
 * ComboPeer.
 */
fan.fwt.ComboPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.ComboPeer.prototype.$ctor = function(self) {}

fan.fwt.ComboPeer.prototype.font   = function(self) { return this.m_font; }
fan.fwt.ComboPeer.prototype.font$  = function(self, val) { this.m_font = val; }
fan.fwt.ComboPeer.prototype.m_font = null;

fan.fwt.ComboPeer.prototype.items   = function(self) { return this.m_items; }
fan.fwt.ComboPeer.prototype.items$  = function(self, val) { this.m_items = val; }
fan.fwt.ComboPeer.prototype.m_items = null;

fan.fwt.ComboPeer.prototype.selectedIndex   = function(self) { return this.m_selectedIndex; }
fan.fwt.ComboPeer.prototype.selectedIndex$  = function(self, val) { this.m_selectedIndex = val; }
fan.fwt.ComboPeer.prototype.m_selectedIndex = null;

fan.fwt.ComboPeer.prototype.text   = function(self) { return this.m_text; }
fan.fwt.ComboPeer.prototype.text$  = function(self, val) { this.m_text = val; }
fan.fwt.ComboPeer.prototype.m_text = "";

fan.fwt.ComboPeer.prototype.create = function(parentElem)
{
  var select = document.createElement("select");
  var div = this.emptyDiv();
  div.appendChild(select);
  parentElem.appendChild(div);
  return div;
}

fan.fwt.ComboPeer.prototype.sync = function(self)
{
  var select = this.elem.firstChild;

  // clear old items
  while (select.firstChild != null)
    select.removeChild(select.firstChild);

  // add new items
  for (var i=0; i<this.items.length; i++)
  {
    var option = document.createElement("option");
    option.appendChild(document.createTextNode(this.m_items[i]));
    select.appendChild(option);
  }

  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}
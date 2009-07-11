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

fan.fwt.ComboPeer.prototype.font$get = function(self) { return this.font; }
fan.fwt.ComboPeer.prototype.font$set = function(self, val) { this.font = val; }
fan.fwt.ComboPeer.prototype.font = null;

fan.fwt.ComboPeer.prototype.items$get = function(self) { return this.items; }
fan.fwt.ComboPeer.prototype.items$set = function(self, val) { this.items = val; }
fan.fwt.ComboPeer.prototype.items = null;

fan.fwt.ComboPeer.prototype.selectedIndex$get = function(self) { return this.selectedIndex; }
fan.fwt.ComboPeer.prototype.selectedIndex$set = function(self, val) { this.selectedIndex = val; }
fan.fwt.ComboPeer.prototype.selectedIndex = null;

fan.fwt.ComboPeer.prototype.text$get = function(self) { return this.text; }
fan.fwt.ComboPeer.prototype.text$set = function(self, val) { this.text = val; }
fan.fwt.ComboPeer.prototype.text = "";

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
    option.appendChild(document.createTextNode(this.items[i]));
    select.appendChild(option);
  }

  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}
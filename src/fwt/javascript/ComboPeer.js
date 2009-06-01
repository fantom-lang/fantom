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
var fwt_ComboPeer = sys_Obj.$extend(fwt_WidgetPeer);
fwt_ComboPeer.prototype.$ctor = function(self) {}

fwt_ComboPeer.prototype.font$get = function(self) { return this.font; }
fwt_ComboPeer.prototype.font$set = function(self, val) { this.font = val; }
fwt_ComboPeer.prototype.font = null;

fwt_ComboPeer.prototype.items$get = function(self) { return this.items; }
fwt_ComboPeer.prototype.items$set = function(self, val) { this.items = val; }
fwt_ComboPeer.prototype.items = null;

fwt_ComboPeer.prototype.selectedIndex$get = function(self) { return this.selectedIndex; }
fwt_ComboPeer.prototype.selectedIndex$set = function(self, val) { this.selectedIndex = val; }
fwt_ComboPeer.prototype.selectedIndex = null;

fwt_ComboPeer.prototype.text$get = function(self) { return this.text; }
fwt_ComboPeer.prototype.text$set = function(self, val) { this.text = val; }
fwt_ComboPeer.prototype.text = "";

fwt_ComboPeer.prototype.create = function(parentElem)
{
  var select = document.createElement("select");
  var div = this.emptyDiv();
  div.appendChild(select);
  parentElem.appendChild(div);
  return div;
}

fwt_ComboPeer.prototype.sync = function(self)
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

  fwt_WidgetPeer.prototype.sync.call(this, self);
}
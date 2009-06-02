//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jun 09  Andy Frank  Creation
//

/**
 * TextPeer.
 */
var fwt_TextPeer = sys_Obj.$extend(fwt_TextWidgetPeer);
fwt_TextPeer.prototype.$ctor = function(self) {}

fwt_TextPeer.prototype.text$get = function(self) { return this.text; }
fwt_TextPeer.prototype.text$set = function(self, val) { this.text = val; }
fwt_TextPeer.prototype.text = "";

fwt_TextPeer.prototype.create = function(parentElem)
{
  var input = document.createElement("input");
  input.type = "text";
  var div = this.emptyDiv();
  div.appendChild(input);
  parentElem.appendChild(div);
  return div;
}

fwt_TextPeer.prototype.sync = function(self)
{
  var text = this.elem.firstChild;
  text.value = this.text;
  text.size  = self.prefCols;
  fwt_WidgetPeer.prototype.sync.call(this, self);
}
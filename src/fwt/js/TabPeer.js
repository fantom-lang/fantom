//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Jun 09  Andy Frank  Creation
//

/**
 * TabPeer.
 */
fan.fwt.TabPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.TabPeer.prototype.$ctor = function(self) {}

fan.fwt.TabPeer.prototype.text$get = function(self) { return this.text; }
fan.fwt.TabPeer.prototype.text$set = function(self, val) { this.text = val; }
fan.fwt.TabPeer.prototype.text = "";

fan.fwt.TabPeer.prototype.image$get = function(self) { return this.image; }
fan.fwt.TabPeer.prototype.image$set = function(self, val)
{
  this.image = val;
  fan.fwt.FwtEnvPeer.loadImage(val, self)
}
fan.fwt.TabPeer.prototype.image = null;

fan.fwt.TabPeer.prototype.sync = function(self)
{
  var elem = this.elem;
  var selected = this.index == self.parent.peer.selectedIndex;

  while (elem.firstChild != null) elem.removeChild(elem.firstChild);
  var text = document.createTextNode(this.text);
  elem.appendChild(text);

  var $self = self;
  elem.onmousedown = function()
  {
    $self.parent.peer.selectedIndex = $self.peer.index;
    $self.parent.relayout();
  }

  with (elem.style)
  {
    cursor  = "default";
    padding = "6px 12px";
    border  = "1px solid #555";

    if (selected)
    {
      borderBottom = "1px solid #eee";
      backgroundColor = "#eee";
      // IE workaround
      try { backgroundImage = "-webkit-gradient(linear, 0% 0%, 0% 100%, from(#f8f8f8), to(#eee))"; } catch (err) {} // ignore
    }
    else
    {
      backgroundColor = "#ccc";
      // IE workaround
      try { backgroundImage = "-webkit-gradient(linear, 0% 0%, 0% 100%, from(#eee), to(#ccc))"; } catch (err) {} // ignore
    }

    MozBorderRadius = "5px 5px 0 0";
    webkitBorderTopLeftRadius  = "5px";
    webkitBorderTopRightRadius = "5px";
  }

  // account for border/padding
  var w = this.size.w - 26;
  var h = this.size.h - 14;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}

// index of tab in TabPane
fan.fwt.TabPeer.prototype.index = null;
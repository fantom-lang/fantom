//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Aug 09  Andy Frank  Creation
//

/**
 * BorderPanePeer.
 */
fan.fwt.BorderPanePeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.fwt.BorderPanePeer.prototype.$ctor = function(self)
{
  fan.fwt.PanePeer.prototype.$ctor.call(this, self);
}

// TODO FIXIT: bad hack to workaround Win/Chrome's horrific alpha-mask bugs
fan.fwt.BorderPane.$isWinChrome = false;
(function() {
  var ua = window.navigator.userAgent;
  if (ua.indexOf("Windows") != -1 && ua.indexOf(" Chrome/") != -1)
    fan.fwt.BorderPane.$isWinChrome = true;
})();

fan.fwt.BorderPanePeer.prototype.relayout = function(self)
{
  // short-circuit if not mounted
  if (this.elem == null) return;

  this.sync(self);
  if (self.onLayout) self.onLayout();

  var b = self.m_border;
  var c = self.m_content;
  if (c != null)
  {
    var cx = c.peer.m_pos.m_x - b.m_widthLeft;
    var cy = c.peer.m_pos.m_y - b.m_widthTop;
    c.pos$(fan.gfx.Point.make(cx, cy));
    c.peer.relayout(c);
  }

  return self;
}

fan.fwt.BorderPanePeer.prototype.sync = function(self)
{
  fan.fwt.WidgetPeer.setBg(this.elem, self.m_bg);
  fan.fwt.WidgetPeer.setBorder(this.elem, self.m_border);

  // override style
  var override = this.$style(self);
  if (override != null)
  {
    s = this.elem.style;
    for (var k in override.keyMap)
    {
      var key = override.keyMap[k];
      var val = override.valMap[k];

      // skip for Chrome until working properly
      if (fan.fwt.BorderPane.$isWinChrome)
      {
        if (key == "-webkit-box-shadow")
        {
          var temp = "";
          var list = val.split(",")
          for (var i=0; i<list.length; i++)
          {
            if (temp.length > 0) temp += ",";
            if (list[i].indexOf("inset") == -1)
              temp += list[i];
          }
          if (temp.length == 0) continue;
          val = temp;
        }
      }

      s.setProperty(key, val, "");
    }
  }

  // sync size
  var b = self.m_border;
  var w = this.m_size.m_w - b.m_widthLeft - b.m_widthRight;
  var h = this.m_size.m_h - b.m_widthTop - b.m_widthBottom;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}

// Backdoor hook to override style [returns [Str:Str]?]
fan.fwt.BorderPanePeer.prototype.$style = function(self) { return null; }



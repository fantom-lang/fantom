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

fan.fwt.BorderPanePeer.prototype.sync = function(self)
{
  var b = self.m_border;
  with (this.elem.style)
  {
    background  = fan.fwt.WidgetPeer.brushToCss(self.m_bg);
    borderStyle = "solid";

    borderTopWidth    = b.m_widthTop    + "px";
    borderRightWidth  = b.m_widthRight  + "px";
    borderBottomWidth = b.m_widthBottom + "px";
    borderLeftWidth   = b.m_widthLeft   + "px";

    borderTopColor    = b.m_colorTop.toCss();
    borderRightColor  = b.m_colorRight.toCss();
    borderBottomColor = b.m_colorBottom.toCss();
    borderLeftColor   = b.m_colorLeft.toCss();

    if (this.elem.style.MozBorderRadius != undefined)
    {
      MozBorderRadiusTopleft     = b.m_radiusTopLeft + "px";
      MozBorderRadiusTopright    = b.m_radiusTopRight + "px";
      MozBorderRadiusBottomright = b.m_radiusBottomRight + "px";
      MozBorderRadiusBottomleft  = b.m_radiusBottomLeft + "px";
    }
    else if (this.elem.style.webkitBorderRadius != undefined)
    {
      webkitBorderTopLeftRadius     = b.m_radiusTopLeft + "px";
      webkitBorderTopRightRadius    = b.m_radiusTopRight + "px";
      webkitBorderBottomRightRadius = b.m_radiusBottomRight + "px";
      webkitBorderBottomLeftRadius  = b.m_radiusBottomLeft + "px";
    }
  }

  var w = this.m_size.m_w - b.m_widthLeft - b.m_widthRight;
  var h = this.m_size.m_h - b.m_widthTop - b.m_widthBottom;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}


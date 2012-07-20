//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Mar 10  Andy Frank  Creation
//

/**
 * HudButtonPeer.
 */
fan.webfwt.HudButtonPeer = fan.sys.Obj.$extend(fan.webfwt.MiniButtonPeer);
fan.webfwt.HudButtonPeer.prototype.$ctor = function(self)
{
  fan.webfwt.MiniButtonPeer.prototype.$ctor.call(this, self);

  // overrides
  this.m_textColor    = "#fff";
  this.m_border       = "1px solid #131313";
  this.m_shadowBg     = "#555";
  this.m_bgStart      = "#5b5b5b";
  this.m_bgEnd        = "#393939";
  this.m_bgPressStart = "#333";
  this.m_bgPressEnd   = "#484848";
  this.m_padding      = "3px 11px";
  this.m_paddingPress = "4px 11px 2px 11px";
  this.m_borderRadius = "11px";
  this.m_widthOff     = 24;
}


//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jun 2011  Andy Frank  Creation
//

/**
 * HudScrollPanePeer.
 */
fan.webfwt.HudScrollPanePeer = fan.sys.Obj.$extend(fan.webfwt.WebScrollPanePeer);
fan.webfwt.HudScrollPanePeer.prototype.$ctor = function(self) {}

// css
fan.fwt.WidgetPeer.addCss(
  "div._webfwt_HudScrollPane_ { "+
  " background:rgba(0,0,0,0.2);" +
  " border:1px solid #222;" +
  " -webkit-box-shadow:inset 0px 3px 3px #2c2c2c;" +
  " -moz-box-shadow:   inset 0px 3px 3px #2c2c2c;" +
  " box-shadow:        inset 0px 3px 3px #2c2c2c;" +
  "}" +
  "div._webfwt_HudScrollPane_::-webkit-scrollbar:vertical {" +
  " border-left: 1px solid #222;" +
  " background: -webkit-gradient(linear, left top, right top, from(#5b5b5b), to(#393939));" +
  "}" +
  "div._webfwt_HudScrollPane_::-webkit-scrollbar-track-piece:vertical {" +
  " background: -webkit-gradient(linear, left top, right top, from(#252525), to(#333));" +
  " border: 1px solid #282828;" +
  "}" +
  "div._webfwt_HudScrollPane_::-webkit-scrollbar-thumb {" +
  " border: 1px solid #282828;" +
  "}" +
  "div._webfwt_HudScrollPane_::-webkit-scrollbar-thumb:vertical {" +
  " background: -webkit-gradient(linear, left top, right top, from(#5b5b5b), to(#393939));" +
  "}");

fan.webfwt.HudScrollPanePeer.prototype.create = function(parentElem, self)
{
  var elem = fan.webfwt.WebScrollPanePeer.prototype.create.call(this, parentElem, self);
  elem.className += " _webfwt_HudScrollPane_";
  elem.style.background = "rgba(0,0,0,0.2)";
  return elem;
}
//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jun 2011  Andy Frank  Creation
//

/**
 * HudListPeer.
 */
fan.webfwt.HudListPeer = fan.sys.Obj.$extend(fan.webfwt.TreeListPeer);
fan.webfwt.HudListPeer.prototype.$ctor = function(self) {}

// css
fan.fwt.WidgetPeer.addCss(
  "div._webfwt_HudList_ { "+
  " background:none;" +
  "}" +
  "div._webfwt_HudList_ > div { "+
  " color:#fff;" +
  " border-bottom:none;" +
  "}" +
  "div._webfwt_HudList_ > div.group { "+
  " background:#505050;" +
  " border:none;" +
  " color:#ccc;" +
  " text-shadow:#000 0 -1px;" +
  "}" +
  "div._webfwt_HudList_ > div.selected { background:#666; }" +
  "div._webfwt_HudList_:focus > div.selected { " +
  " background:#3d80df;" +
  " background-image:-webkit-linear-gradient(top, #5a9ce6, #1d67bc);" +
  " background-image:-moz-linear-gradient(top, #5a9ce6, #1d67bc);" +
  " background-image:-ms-linear-gradient(top, #5a9ce6, #1d67bc);" +
  " background-image:linear-gradient(top, #5a9ce6, #1d67bc);" +
  "}" +
  "div._webfwt_HudList_ > div > span.def { color:#666; }" +
  "div._webfwt_HudList_ > div > span.pill { background:#666; }" +
  "div._webfwt_HudList_ > div.selected > span.def { color:#fff; }" +
  "div._webfwt_HudList_ > div.selected > span.pill { background:#154f92; }" +
  "div._webfwt_HudList_:focus > div.selected > span.pill { background:#154f92; }" +
  "");

fan.webfwt.HudListPeer.prototype.setupContainer = function(self, container)
{
  // add css class
  fan.webfwt.TreeListPeer.prototype.setupContainer.call(this, self, container)
  container.className =
    "_webfwt_WebScrollPane_ _webfwt_WebList_ _webfwt_TreeList_" +
    " _webfwt_HudScrollPane_ _webfwt_HudList_";
}

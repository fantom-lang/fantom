//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Dec 2011  Andy Frank  Creation
//

/**
 * PaleTreeListPeer.
 */
fan.webfwt.PaleTreeListPeer = fan.sys.Obj.$extend(fan.webfwt.TreeListPeer);
fan.webfwt.PaleTreeListPeer.prototype.$ctor = function(self) {}

// css
fan.fwt.WidgetPeer.addCss(
  "div._webfwt_PaleTreeList_ { "+
  " background:#d4dbe3;" +
  "}" +
  "div._webfwt_PaleTreeList_ > div.group {" +
  " color:#325373;" +
  " background:#aec0d0;" +
  " border-color:#9aacbc;" +
  " text-shadow:#e2e8f0 0px 1px;" +
  "}" +
  "");

fan.webfwt.PaleTreeListPeer.prototype.setupContainer = function(self, container)
{
  // add css class
  fan.webfwt.TreeListPeer.prototype.setupContainer.call(this, self, container)
  container.className =
    "_webfwt_WebScrollPane_ _webfwt_WebList_ _webfwt_TreeList_ _webfwt_PaleTreeList_";
}

//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Jun 2011  Andy Frank  Move Fantom implementation to JavaScript
//

/**
 * ColWebListPeer.
 */
fan.webfwt.ColWebListPeer = fan.sys.Obj.$extend(fan.webfwt.WebListPeer);
fan.webfwt.ColWebListPeer.prototype.$ctor = function(self)
{
  // 16 Mar 2012 - WebKit has some weird bug where focusing this
  // element shifts our offset -1px - overrriding focus to be a
  // noop seems to fix the issue
  self.focus = function() {}
}

// css
fan.fwt.WidgetPeer.addCss(
  "div._webfwt_ColWebList_ {" +
  " background:#fff;" +
  "}" +
  "div._webfwt_ColWebList_ > div { "+
  " position:relative;" +
  " font:" + fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.sysFontView()) + ";" +
  " padding:3px 4px;" +
  " overflow:hidden;" +
  " white-space:nowrap;" +
  " text-overflow:ellipsis;" +
  "}" +
  "div._webfwt_ColWebList_ > div > div { "+
  " overflow:hidden;" +
  "}" +
  "div._webfwt_ColWebList_ > div > span { "+
  " float:right;" +
  " padding-top:2px;" +
  " padding-left:4px;" +
  " color:#999;" +
  " font:" + fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.sysFont().toSize(10)) + ";" +
  "}" +
  "div._webfwt_ColWebList_ > div.selected { "+
  " background:#3d80df;" +
  " color:#fff;" +
  "}" +
  "div._webfwt_ColWebList_ > div.selected span { "+
  " color:#fff;" +
  "}");

// IE seems to have trouble doing text-overflow properly
if (!fan.fwt.DesktopPeer.$isIE)
 fan.fwt.WidgetPeer.addCss(
   "div._webfwt_ColWebList_ > div > div { text-overflow:ellipsis; }");

fan.webfwt.ColWebListPeer.prototype.setupContainer = function(self, elem)
{
  // add css class
  elem.className = "_webfwt_WebScrollPane_ _webfwt_WebList_ _webfwt_ColWebList_";
}

fan.webfwt.ColWebListPeer.prototype.repaintSelection = function(self, ix, selected)
{
  for (var i=0; i<ix.length; i++)
    this.indexToElem(ix[i]).className = selected ? "selected" : "";
}

fan.webfwt.ColWebListPeer.prototype.makeRow = function(self, item)
{
  var model = self.m_tree.m_model;
  var row = document.createElement("div");

  // symbol
  if (model.hasChildren(item))
  {
    var symbol = document.createElement("span");
    symbol.appendChild(document.createTextNode("\u25ba"));
    row.appendChild(symbol);
  }

  // text
  var text = model.text(item);
  var div = document.createElement("div")
  div.appendChild(document.createTextNode(text));
  div.title = text;
  row.appendChild(div);

  return row;
}

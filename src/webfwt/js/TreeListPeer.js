//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Jun 2011  Andy Frank  Creation
//

/**
 * TreeListPeer.
 */
fan.webfwt.TreeListPeer = fan.sys.Obj.$extend(fan.webfwt.WebListPeer);
fan.webfwt.TreeListPeer.prototype.$ctor = function(self) {}

// css
fan.fwt.WidgetPeer.addCss(
  "div._webfwt_TreeList_ {" +
  " background:#fff;" +
  "}" +
  "div._webfwt_TreeList_ > div { "+
  " font:" + fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.sysFontView()) + ";" +
  " padding:4px 8px;" +
  " overflow:hidden;" +
  " white-space:nowrap;" +
  "}" +
  "div._webfwt_TreeList_zebra_ > div:nth-child(odd) { "+
  " background:#f1f5fa;" +
  "}" +
  "div._webfwt_TreeList_ > div > div { "+
  " overflow:hidden;" +
  "}" +
  "div._webfwt_TreeList_ > div.group { "+
  " background:#eee;" +
  " border-top:1px solid #d2d2d2;" +
  " border-bottom:1px solid #d2d2d2;" +
  " color:#666;" +
  " text-transform:uppercase;" +
  " text-shadow:#fff 0 1px;" +
  " font:" + fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.sysFontSmall().toBold()) + ";" +
  "}" +
  "div._webfwt_TreeList_ > div.group:first-child { "+
  " border-top:none;" +
  "}" +
  "div._webfwt_TreeList_ > div > img { "+
  " padding-right:6px;" +
  " float:left;" +
  "}" +
  "div._webfwt_TreeList_ > div > span { "+
  " float:right;" +
  " font:" + fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.sysFontSmall()) + ";" +
  "}" +
  "div._webfwt_TreeList_ > div > span.imgOnly { "+
  " float:right;" +
  " font-size:2px;" +
  "}" +
  "div._webfwt_TreeList_ > div > span.def { "+
  " color:#325373;" +
  " margin-top:1px;" +
  " padding-left:6px;" +
  "}" +
  "div._webfwt_TreeList_ > div > span.pill { "+
  " background:#4f749a;" +
  " color:#fff;" +
  " padding:1px 6px;" +
  " -moz-border-radius:   15px;" +
  " -webkit-border-radius:15px;" +
  " border-radius:        15px;" +
  " margin-top:0px;" +
  " margin-left:6px;" +
  "}" +
  "div._webfwt_TreeList_ > div.selected {" +
  " background:#cbcbcb;" +
  " font-weight:bold;" +
  "}" +
  "div:focus > div._webfwt_TreeList_ > div.selected { " +
  " background:#3d80df;" +
  " background-image:-webkit-linear-gradient(top, #1d67bc, #5a9ce6 1px, #1d67bc);" +
  " background-image:-moz-linear-gradient(top, #1d67bc, #5a9ce6 1px, #1d67bc);" +
  " background-image:-ms-linear-gradient(top, #1d67bc, #5a9ce6 1px, #1d67bc);" +
  " background-image:linear-gradient(top, #1d67bc, #5a9ce6 1px, #1d67bc);" +
  " color:#fff;" +
  "}" +
  "div:focus > div._webfwt_TreeList_ > div.selected > span.def {" +
  "  color:#fff;" +
  "}" +
  "div._webfwt_TreeList_ > div.selected > span.pill {" +
  "  background:#154f92;" +
  "}");

// IE seems to have trouble doing text-overflow properly
if (!fan.fwt.DesktopPeer.$isIE)
 fan.fwt.WidgetPeer.addCss(
   "div._webfwt_TreeList_ > div > div { text-overflow:ellipsis; }");

fan.webfwt.TreeListPeer.prototype.setupContainer = function(self, container)
{
//  // cache border color
//  this.m_rowBorder = null;
//  if (self.m_borderColor != null)
//    this.m_rowBorder = "1px solid " + self.m_borderColor.toCss();

  // add css class
  container.className = "_webfwt_WebScrollPane_ _webfwt_WebList_ _webfwt_TreeList_";
  if (self.zebraStripe()) container.className += " _webfwt_TreeList_zebra_";
//  if (self.m_bg != null) fan.fwt.WidgetPeer.setBg(container, self.m_bg);

  // calc icon offset to vertically center text
  var size = self.iconSize();
  this.iconOffset = size.m_h > 16 ? Math.floor((size.m_h - 16) / 2) : 0;
}

fan.webfwt.WebListPeer.prototype.repaintSelection = function(self, indices, selected)
{
  for (var i=0; i<indices.length; i++)
  {
    var ix   = indices[i];
    var elem = this.indexToElem(ix);
    var img  = null;

    if (elem == undefined) continue;

    for (var j=0; j<elem.childNodes.length; j++)
    {
      var kid = elem.childNodes[j];
      if (kid.tagName == "IMG") img = kid;
    }

    var elemClass = elem.className.indexOf("group") == -1 ? "" : "group"
    elem.className = elemClass + (selected ? " selected" : "");

    if (img != null)
    {
      var item = this.m_items.get(ix);
      var icon = self.icon(item, selected);
      img.src  = fan.fwt.WidgetPeer.uriToImageSrc(icon.m_uri);
    }
  }
}

fan.webfwt.TreeListPeer.prototype.makeRow = function(self, item)
{
  var text    = self.text(item);
  var font    = self.font(item);
  var icon    = self.icon(item, false);
  var depth   = self.depth(item);
  var aux     = self.aux(item);
  var auxIcon = self.auxIcon(item, false);

  var img  = null;
  var div  = null;
  var span = null;

  var row  = document.createElement("div");
  if (depth > 0) row.style.paddingLeft = (8+(depth*12)) + "px";
//  if (this.m_rowBorder != null) row.style.borderBottom = this.m_rowBorder

  div = document.createElement("div")
  div.title = text;
  div.appendChild(document.createTextNode(text));
  if (font != null) div.style.font = fan.fwt.WidgetPeer.fontToCss(font);

  if (aux != null || auxIcon != null)
  {
    span = document.createElement("span");

    var imgAux = null;
    if (auxIcon != null)
    {
      imgAux = document.createElement("img");
      imgAux.src = fan.fwt.WidgetPeer.uriToImageSrc(auxIcon.m_uri);
    }

    if (aux != null && auxIcon == null)
    {
      span.className = self.auxStyle();
      span.appendChild(document.createTextNode(aux));
    }
    else if (aux == null && auxIcon != null)
    {
      span.className = "imgOnly";
      span.appendChild(imgAux);
    }
    else
    {
      var spanAux = document.createElement("span");
      spanAux.className = self.auxStyle();
      spanAux.appendChild(document.createTextNode(aux));
      span.appendChild(spanAux);
      span.appendChild(imgAux);
    }
  }

  if (icon != null)
  {
    var ioff = this.iconOffset;
    if (ioff > 0)
    {
      div.style.paddingTop = ioff + "px";
      if (span != null) span.style.marginTop = (ioff+1) + "px";
    }

    img = document.createElement("img");
    img.src = fan.fwt.WidgetPeer.uriToImageSrc(icon.m_uri);

    var size = self.iconSize();
    img.width = size.m_w;
    img.height = size.m_h;
  }

  if (self.isHeading(item)) row.className = "group";
  if (span != null) row.appendChild(span);
  if (img  != null) row.appendChild(img);
  row.appendChild(div);
  return row;
}


//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jun 2011  Andy Frank  Creation
//

/**
 * HudComboPeer.
 */
fan.webfwt.HudComboPeer = fan.sys.Obj.$extend(fan.webfwt.WebComboPeer);
fan.webfwt.HudComboPeer.prototype.$ctor = function(self) {}

// CSS - Firefox has trouble renderering content
if (!fan.fwt.DesktopPeer.$isFirefox)
{
  fan.webfwt.HudComboPeer.$bg = "url(" +
    fan.fwt.WidgetPeer.uriToImageSrc(fan.sys.Uri.fromStr("fan://webfwt/res/img/hud-combo-arrows.png"))
    + ") no-repeat right center";
  fan.fwt.WidgetPeer.addCss(
    "select._webfwt_HudCombo_ {" +
    " color:#fff;" +
    " -webkit-appearance:none;" +
    " border:1px solid #131313;" +
    " background:" + fan.webfwt.HudComboPeer.$bg + ",-webkit-linear-gradient(top, #5b5b5b, #393939);" +
    " background:" + fan.webfwt.HudComboPeer.$bg + ",linear-gradient(top, #5b5b5b #393939);" +
    " -webkit-box-shadow:0 1px 1px #555;" +
    " box-shadow:        0 1px 1px #555;" +
    "}" +
    "select._webfwt_HudCombo_ option {" +
    " color:#000;" +
    "}");
}

fan.webfwt.HudComboPeer.prototype.create = function(parentElem, self)
{
  var elem = fan.fwt.ComboPeer.prototype.create.call(this, parentElem, self);
  var select = elem.firstChild;
  select.className = "_fwt_Combo_ _webfwt_HudCombo_";
  return elem;
}


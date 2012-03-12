//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Jun 09  Andy Frank  Creation
//

/**
 * Static init
 */

fan.concurrent.Actor.locals().set("gfx.env", fan.fwt.FwtEnv.make());

//
// fwt::Combo CSS
//
if (fan.fwt.DesktopPeer.$isWebkit)
{
  fan.fwt.ComboPeer.$bg = "url(" +
    fan.fwt.WidgetPeer.uriToImageSrc(fan.sys.Uri.fromStr("fan://fwt/res/img/arrowUpDown.png"))
    + ") no-repeat right center";
  fan.fwt.WidgetPeer.addCss(
    "select._fwt_Combo_ {" +
    " -webkit-appearance:none;" +
    " border:1px solid #9a9a9a;" +
    " border-radius:4px;" +
    " padding:2px 18px 2px 6px;"+
    " background:" + fan.fwt.ComboPeer.$bg + ",-webkit-linear-gradient(top, #fefefe, #cfcfcf);" +
    " background:" + fan.fwt.ComboPeer.$bg + ",linear-gradient(top, #fefefe #cfcfcf);" +
    " -webkit-box-shadow:0 1px 1px #ddd;" +
    " box-shadow:        0 1px 1px #ddd;" +
    "}" +
    "select._fwt_Combo_[disabled] {" +
    " opacity: 0.6;" +
    "}");
}
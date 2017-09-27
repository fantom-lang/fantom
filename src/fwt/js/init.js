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
// Desktop
//
fan.fwt.DesktopPeer.clipboard  = function() { return fan.fwt.DesktopPeer.$clipboard; }
fan.fwt.DesktopPeer.$clipboard = new fan.fwt.Clipboard();

//
// fwt::MenuItem CSS
//
fan.fwt.WidgetPeer.addCss(
  "div._fwt_MenuItem_ {" +
  " font:" + fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.sysFont()) + ";" +
  " padding: 2px 12px 0px 12px;" +
  " white-space: nowrap;" +
  " -webkit-box-sizing: border-box;" +
  "    -moz-box-sizing: border-box;" +
  "         box-sizing: border-box;" +
  "}" +
  "div._fwt_MenuItem_ img {" +
  "  padding: 2px 4px 3px 0;" +
  "  vertical-align: middle;" +
  "}" +
  "div._fwt_MenuItem_.sep {" +
  " margin: 6px 0 0 0;" +
  " padding: 0 0 6px 0;" +
  " border-top: 1px solid #dadada;" +
  "}" +
  "div._fwt_MenuItem_.disabled {" +
  " color: #999;" +
  "}" +
  "div._fwt_MenuItem_:hover," +
  "div._fwt_MenuItem_:focus {" +
  " background: #3d80df;" +
  " color: #fff;" +
  "}" +
  "div._fwt_MenuItem_.disabled:hover {" +
  " background: none;" +
  " color: #999;" +
  "}");

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

//
// fwt::Dialog CSS
//
fan.fwt.WidgetPeer.addCss(
  "div._fwt_Dialog_mask_ {" +
  " position: fixed;" +
  " z-index: 100;" +
  " top:0; left:0; width:100%; height:100%;" +
  " background: #000;" +
  " opacity: 0.0;" +
  " -webkit-transition: 100ms;" +
  "    -moz-transition: 100ms;" +
  "}" +
  "div._fwt_Dialog_shell_ {" +
  " position: fixed;" +
  " z-index: 101;" +
  " top:0; left:0; width:100%; height:100%;" +
  "}" +
  "div._fwt_Dialog_tbar_ {" +
  " height: 19px;" +
  " padding: 5px 6px 4px 6px;" +
  " color: #fff;" +
  " font: " + fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.sysFont()) + ";" +
  // " textShadow: 0 -1px 1px #1c1c1c;" +
  " text-align: center;" +
  " border-bottom: 1px solid #282828;" +
  " border-radius: 4px 4px 0 0;" +
  " background: #5a5a5a;" +
  " background-image: -webkit-linear-gradient(top, #707070, #5a5a5a 50%, #525252 50%, #484848); " +
  " background-image:    -moz-linear-gradient(top, #707070, #5a5a5a 50%, #525252 50%, #484848); " +
  " background-image:         linear-gradient(top, #707070, #5a5a5a 50%, #525252 50%, #484848); " +
  " box-shadow: inset 0px 1px #7c7c7c;" +
  "}" +
  "div._fwt_Dialog_ {" +
  " border: 1px solid #404040;" +
  " border-radius: 5px 5px 0 0;" +
  " box-shadow: 0 5px 12px rgba(0, 0, 0, 0.5);" +
  "}" +
  "div._fwt_Dialog_.opening {" +
  " opacity: 0;" +
  " -webkit-transform: scale(0.75);" +
  "    -moz-transform: scale(0.75);" +
  "}" +
  "div._fwt_Dialog_.open {" +
  " -webkit-transition: -webkit-transform 100ms, opacity 100ms;" + //, top 250ms, left 250ms, width 250ms, height 250ms;" +
  "    -moz-transition:    -moz-transform 100ms, opacity 100ms;" + //, top 250ms, left 250ms, width 250ms, height 250ms;" +
  "}");

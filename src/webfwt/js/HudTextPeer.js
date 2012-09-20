//
// Copyright (c) 2012, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Feb 2012  Andy Frank  Creation
//

/**
 * HudTextPeer.
 */
fan.webfwt.HudTextPeer = fan.sys.Obj.$extend(fan.webfwt.WebTextPeer);
fan.webfwt.HudTextPeer.prototype.$ctor = function(self) {}

fan.fwt.WidgetPeer.addCss(
  "._webfwt_HudText_ {" +
  " color:#fff;" +
  " border:1px solid #181818;" +
  " background:#2c2c2c;" +
  " -webkit-box-shadow: inset 0px 1px 2px #1c1c1c;" +
  " -moz-box-shadow:    inset 0px 1px 2px #1c1c1c;" +
  " box-shadow:         inset 0px 1px 2px #1c1c1c;" +
  "}" +
  "input._webfwt_HudText_::-webkit-input-placeholder { color: #777 }" +
  "input._webfwt_HudText_:-moz-placeholder { color: #777 }" +
  "input._webfwt_HudText_:-ms-input-placeholder { color: #777 }"
  );

fan.webfwt.HudTextPeer.prototype.$cssClass = function(readonly)
{
  return readonly
    ? "_fwt_Text_ _webfwt_HudText_ _fwt_Text_readonly_"
    : "_fwt_Text_ _webfwt_HudText_";
}
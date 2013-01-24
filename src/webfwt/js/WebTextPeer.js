//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Sep 2011  Andy Frank  Creation
//

/**
 * WebTextPeer.
 */
fan.webfwt.WebTextPeer = fan.sys.Obj.$extend(fan.fwt.TextPeer);
fan.webfwt.WebTextPeer.prototype.$ctor = function(self)
{
  fan.fwt.TextPeer.prototype.$ctor.call(this, self);
}

fan.webfwt.WebTextPeer.counter = 0;
fan.webfwt.WebTextPeer.prototype.subCreate = function(self, control)
{
  // placeHolder
  if (self.m_placeHolder) control.placeholder = self.m_placeHolder;

  // shadow/insets/border
  this.setShadow(self, control);
  if (self.m_insets) control.style.padding = fan.fwt.WidgetPeer.insetsToCss(self.m_insets);
  if (self.m_textBorder) fan.fwt.WidgetPeer.setBorder(control, self.m_textBorder);

  // image
  if (self.m_image != null)
  {
    var src = fan.fwt.WidgetPeer.uriToImageSrc(self.m_image.m_uri);
    control.style.backgroundImage = "url(" + src + ")";
    control.style.backgroundRepeat = "no-repeat";
  }

  var phColor = self.placeHolderColor();
  if (phColor)
  {
    var cls = this.subClass = "_webTextCls_" + (fan.webfwt.WebTextPeer.counter++);
    fan.fwt.WidgetPeer.addCss(
      "input." + cls + "::-webkit-input-placeholder { color:" + phColor.toCss() + "}" +
      "input." + cls + ":-moz-placeholder { color:" + phColor.toCss() + "}" +
      "input." + cls + ":-ms-input-placeholder { color:" + phColor.toCss() + "}");
    fan.fwt.WidgetPeer.addClassName(control, cls);
  }
}

fan.webfwt.WebTextPeer.prototype.setShadow = function(self, control)
{
  var shadow = "";
  if (self.m_dropShadow != null)
    shadow += self.m_dropShadow.toCss();

  if (self.m_innerShadow != null)
  {
    if (shadow.length > 0) shadow += ",";
    shadow += "inset " + self.m_innerShadow.toCss();
  }

  control.style.webkitBoxShadow = shadow;
  control.style.MozBoxShadow = shadow;
  control.style.boxShadow = shadow;
}

fan.webfwt.WebTextPeer.prototype.subSync = function(self, control)
{
  var w = this.m_size.m_w;
  var h = this.m_size.m_h;
  var d = self.m_dropShadow;
  if (d != null)
  {
    h -= d.m_offset.m_y + d.m_blur + d.m_spread;
    control.style.height = h + "px";
  }
  if (self.m_image != null)
  {
    var left = self.m_halignImage == fan.gfx.Halign.m_left;
    var pad = left ? control.style.paddingLeft : control.style.paddingRight;

    if (pad == "") pad = "2px";  // see TextPeer.css for default
    pad = parseInt(pad);

    var bx = w - pad - 16;
    control.style.backgroundPosition = bx + "px center";
  }
}

// backdoor hook to override style
fan.webfwt.WebTextPeer.prototype.$style = function(self) { return self.m_style; }
fan.webfwt.WebTextPeer.prototype.$disabledStyle = function(self) { return self.m_disabledStyle; }
fan.webfwt.WebTextPeer.prototype.$cssClass = function(readonly)
{
  var cls = fan.fwt.TextPeer.prototype.$cssClass.call(this, readonly);
  if (this.subClass) cls += " " + this.subClass;
  return cls;
}

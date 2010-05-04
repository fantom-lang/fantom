//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 May 09  Andy Frank  Creation
//

/**
 * LabelPeer.
 */
fan.fwt.LabelPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.LabelPeer.prototype.$ctor = function(self) {}

fan.fwt.LabelPeer.prototype.m_text = "";
fan.fwt.LabelPeer.prototype.text   = function(self) { return this.m_text; }
fan.fwt.LabelPeer.prototype.text$  = function(self, val)
{
  this.m_text = val;
  this.needRebuild = true;
}

fan.fwt.LabelPeer.prototype.m_bg = null;
fan.fwt.LabelPeer.prototype.bg   = function(self) { return this.m_bg; }
fan.fwt.LabelPeer.prototype.bg$  = function(self, val)
{
  this.m_bg = val;
  this.needRebuild = true;
}

fan.fwt.LabelPeer.prototype.m_fg = null;
fan.fwt.LabelPeer.prototype.fg   = function(self) { return this.m_fg; }
fan.fwt.LabelPeer.prototype.fg$  = function(self, val)
{
  this.m_fg = val;
  this.needRebuild = true;
}

fan.fwt.LabelPeer.prototype.m_font = null;
fan.fwt.LabelPeer.prototype.font   = function(self) { return this.m_font; }
fan.fwt.LabelPeer.prototype.font$  = function(self, val)
{
  this.m_font = val;
  this.needRebuild = true;
}

fan.fwt.LabelPeer.prototype.m_halign = null;
fan.fwt.LabelPeer.prototype.halign   = function(self) { return this.m_halign; }
fan.fwt.LabelPeer.prototype.halign$  = function(self, val)
{
  this.m_halign = val;
  this.needRebuild = true;
}

fan.fwt.LabelPeer.prototype.m_image = null;
fan.fwt.LabelPeer.prototype.image  = function(self) { return this.m_image; }
fan.fwt.LabelPeer.prototype.image$ = function(self, val)
{
  this.m_image = val;
  if (val != null)
  {
    var $this = this;
    var func = function() { $this.needRebuild = true; }
    fan.fwt.FwtEnvPeer.loadImage(val, self, func);
  }
  this.needRebuild = true;
}

fan.fwt.LabelPeer.prototype.create = function(parentElem, self)
{
  this.needRebuild = true; // make sure we force rebuild
  return fan.fwt.WidgetPeer.prototype.create.call(this, parentElem, self);
}

fan.fwt.LabelPeer.prototype.sync = function(self)
{
  if (this.needRebuild == true)
  {
    this.rebuild(self);
    this.needRebuild = false;
  }
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

fan.fwt.LabelPeer.prototype.needRebuild = true;
fan.fwt.LabelPeer.prototype.rebuild = function(self)
{
  var parent = this.elem;      // parent elem
  var uri  = this.$uri(self);  // uri if applicable
  var text = null;             // text node
  var img  = null;             // img node

  // remove old subtree
  while (parent.firstChild != null)
  {
    var child = parent.firstChild;
    parent.removeChild(child);
    child = null;
    delete child;
  }

  // setup image
  if (this.m_image != null)
  {
    if (uri == null)
      img = document.createElement("div");
    else
    {
      img = document.createElement("a");
      img.href = uri.uri;
    }
    img.style.display = "inline-block";
    img.style.verticalAlign = "middle";

    var imgElem = document.createElement("img");
    imgElem.border = "0";
    imgElem.src = fan.fwt.WidgetPeer.uriToImageSrc(this.m_image.m_uri);

    img.appendChild(imgElem);
    parent.appendChild(img);
  }

  // setup text
  if (this.m_image == null || this.m_text.length > 0)
  {
    if (uri == null)
      text = document.createElement("div");
    else
    {
      text = document.createElement("a");
      text.href = uri.uri;
      switch (uri.underline)
      {
        case "none": text.style.textDecoration = "none"; break;
        case "hover":
          text.style.textDecoration = "none";
          text.onmouseover = function() { text.style.textDecoration = "underline"; }
          text.onmouseout  = function() { text.style.textDecoration = "none"; }
          break;
      }
    }
    if (this.m_fg != null) text.style.color = this.m_fg.toStr();
    text.style.display = "inline-block";
    text.style.position = "relative";
    text.style.top = "-1px";
    text.style.verticalAlign = "middle";
    if (this.m_text.length > 0)
      text.appendChild(document.createTextNode(this.m_text));
    else
      text.innerHTML = "&nbsp;";  // to force height of empty labels
    parent.appendChild(text);
  }

  // insert padding b/w img and text
  if (img != null && text != null)
  {
    var hgap = this.$hgap(self);
    if (hgap == null) hgap = 3;
    img.style.paddingRight = hgap + "px";
  }

  // apply style
  var s = this.elem.style;
  s.font = fan.fwt.WidgetPeer.fontToCss(this.m_font==null ? fan.fwt.DesktopPeer.$sysFont : this.m_font);
  if (this.m_bg != null) s.background = this.m_bg.toStr();
  switch (this.m_halign)
  {
    case fan.gfx.Halign.m_left:   s.textAlign = "left"; break;
    case fan.gfx.Halign.m_fill:   s.textAlign = "left"; break;
    case fan.gfx.Halign.m_center: s.textAlign = "center"; break;
    case fan.gfx.Halign.m_right:  s.textAlign = "right"; break;
    default:                      s.textAlign = "left"; break;
  }
  s.cursor = "default";
  s.whiteSpace = "nowrap";

  // override style
  var override = this.$style(self);
  if (override != null && text != null)
  {
    s = text.style;
    for (var k in override.keyMap)
    {
      var key = override.keyMap[k];
      var val = override.valMap[k];
      s.setProperty(key, val, "");
    }
  }
}

// Backdoor hook to override hgap b/w image and text [returns Int?]
fan.fwt.LabelPeer.prototype.$hgap = function(self) { return null; }

// Backdoor hook to override text style [returns [Str:Str]?]
fan.fwt.LabelPeer.prototype.$style = function(self) { return null; }

// Backdoor hook to reuse Label for hyperlinks
// { uri:<encoded-uri>, underline:<css-underline>" }
fan.fwt.LabelPeer.prototype.$uri = function(self) { return null; }



//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jan 11  Andy Frank  Creation
//

/**
 * MiniComboPeer.
 */
fan.webfwt.MiniComboPeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.MiniComboPeer.prototype.$ctor = function(self)
{
  fan.fwt.PanePeer.prototype.$ctor.call(this, self);
  this.m_dropDownOpen = false;
  this.m_pressed = false;
  this.m_rebuild = true;

  this.m_textColor    = "#000";
  this.m_border       = "1px solid #404040";
  this.m_shadowBg     = "#e0e0e0";
  this.m_bgStart      = "#fefefe";
  this.m_bgEnd        = "#cbcbcb";
  this.m_bgPressStart = "#ccc";
  this.m_bgPressEnd   = "#d9d9d9";
  this.m_padding      = "2px 8px 2px 10px";
  this.m_paddingPress = "3px 8px 1px 10px";
  this.m_borderRadius = "10px";
  this.m_widthOff     = 22;
}

fan.webfwt.MiniComboPeer.prototype.m_text = "";
fan.webfwt.MiniComboPeer.prototype.text = function(self) { return this.m_text; }
fan.webfwt.MiniComboPeer.prototype.text$ = function(self, val)
{
  this.m_rebuild = true;
  this.m_text = val;
}

// override enabled to set rebuild flag
fan.webfwt.MiniComboPeer.prototype.enabled$ = function(self, val)
{
  this.m_rebuild = true;
  fan.fwt.WidgetPeer.prototype.enabled$.call(this, self, val);
}

fan.webfwt.MiniComboPeer.prototype.dropDownClosed = function(self)
{
  this.m_dropDownOpen = false;
  this.m_pressed = false;
  this.repaint(self);
}

fan.webfwt.MiniComboPeer.prototype.create = function(parentElem, self)
{
  var $this = this;
  var div = document.createElement("div");
  this.m_rebuild = true;

  div.onmousedown = function(event)
  {
    if (!self.enabled()) return false;
    $this.m_pressed = true;
    $this.repaint(self);
    return false;
  }

  div.onmouseout = function(event)
  {
    if (!self.enabled()) return;
    if ($this.m_dropDownOpen) return;
    $this.m_pressed = false;
    $this.repaint(self);
  }

  div.onmouseup = function(event)
  {
    if (!self.enabled()) return;
    if ($this.m_pressed != true) return;  // mouseout before up
    $this.m_dropDownOpen = true;
    self.openDropDown();
  }

  // for inset ridge on bottom
  var inset = document.createElement("div");
  var style = inset.style;
  style.background = this.m_shadowBg;
  style.paddingBottom = "1px";
  style.MozBorderRadius    = this.m_borderRadius;
  style.webkitBorderRadius = this.m_borderRadius;
  style.borderRadius       = this.m_borderRadius;

  // offset top to keep centered w/ inset
  var offset = this.emptyDiv();
  offset.style.paddingTop = "1px";

  inset.appendChild(div);
  offset.appendChild(inset);
  parentElem.appendChild(offset);
  return offset;
}

fan.webfwt.MiniComboPeer.prototype.prefSize = function(self, hints)
{
  return fan.fwt.WidgetPeer.prototype.prefSize.call(this, self, hints);
}

fan.webfwt.MiniComboPeer.prototype.sync = function(self)
{
  var div = this.elem.firstChild.firstChild;
  var style = div.style;

  if (this.m_rebuild)
  {
    // set style
    style.display = "table-cell";
    style.height  = "14px";
    style.border  = this.m_border;
    style.color   = this.m_textColor;
    style.font    = fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.$sysFontSmall);
    style.cursor  = "default";
    style.minWidth = "32px";
    style.textAlign = "center";
    style.whiteSpace = "nowrap";
    style.verticalAlign = "middle";
    style.MozBorderRadius    = this.m_borderRadius;
    style.webkitBorderRadius = this.m_borderRadius;
    style.borderRadius       = this.m_borderRadius;

    // remove old text node
    if (div.firstChild != null)
    {
      var child = div.firstChild;
      div.removeChild(child);
      child = null;
      delete child;
    }

    // add new text node
    var span = document.createElement("span");
    span.appendChild(document.createTextNode(this.m_text));
    span.innerHTML += " <span style='font-size:8px;'>&#x25bc;</span>"
    div.appendChild(span);

    this.repaint(self);
    this.m_rebuild = false;
  }

  var w = this.m_size.m_w;
  var h = this.m_size.m_h - 1;
  style.width = (w-this.m_widthOff) + "px"
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}

fan.webfwt.MiniComboPeer.prototype.repaint = function(self)
{
  // TODO FIXIT: this is getting called when null in some
  // circumstances - not sure why yet
  if (this.elem == null) return

  var inset = this.elem.firstChild;
  var div = inset.firstChild;
  var style = div.style;
  if (this.m_pressed)
  {
    inset.style.background = this.m_shadowBg;
    inset.style.opacity = "1.0";
    style.padding = this.m_paddingPress;
    fan.fwt.WidgetPeer.setBg(div, fan.gfx.Gradient.fromStr("0% 0%, 0% 100%, " +
      this.m_bgPressStart + ", " +
      this.m_bgPressEnd));
  }
  else // normal
  {
    if (this.m_enabled)
    {
      inset.style.background = this.m_shadowBg;
      inset.style.opacity = "1.0";
    }
    else
    {
      inset.style.background = "none";
      inset.style.opacity = "0.35";
    }
    style.padding = this.m_padding;
    fan.fwt.WidgetPeer.setBg(div, fan.gfx.Gradient.fromStr("0% 0%, 0% 100%, " +
      this.m_bgStart + ", " +
      this.m_bgEnd));
  }
}
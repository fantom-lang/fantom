//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jul 2011  Andy Frank  Creation
//

/**
 * StyledButtonPeer.
 */
fan.webfwt.StyledButtonPeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.StyledButtonPeer.prototype.$ctor = function(self)
{
  fan.fwt.PanePeer.prototype.$ctor.call(this, self);
}

fan.webfwt.StyledButtonPeer.prototype.create = function(parentElem, self)
{
  var button = this.emptyDiv();
  this.m_pressed = false;
  this.updateState(self, button);
  fan.fwt.WidgetPeer.setBorder(button, self.m_border);
  if (self.m_toolTip != null) button.title = self.m_toolTip;

  var $this = this;
  button.onmousedown = function(event)
  {
    if (!self.enabled()) return false;
    $this.m_pressed = true;
    $this.updateState(self, button, true);
    return false;
  }

  button.onmouseout = function(event)
  {
    if (!self.enabled()) return;
    if (!$this.m_pressed) return;
    $this.m_pressed = false;
    $this.updateState(self, button, true);
  }

  button.onmouseup = function(event)
  {
    if (!self.enabled()) return;
    if (!$this.m_pressed) return;
    $this.m_pressed = false;
    if (self.m_mode == fan.fwt.ButtonMode.m_toggle)
      self.m_selected = !self.m_selected;
    $this.updateState(self, button, true);
    self.fireAction();
  }

  parentElem.appendChild(button);
  return button;
}

fan.webfwt.StyledButtonPeer.prototype.updateState = function(self, button, notify)
{
  if (button === undefined) button = this.elem;
  if (notify === undefined) notify = false;
  if (button == null) return;

  if (this.m_pressed || self.m_selected)
  {
    // notify pressed event
    if (notify)
    {
      var e = fan.fwt.Event.make();
      e.m_id = fan.fwt.EventId.m_mouseDown;
      e.m_widget = self;
      self.onPressed().fire(e);
    }

    // TODO FIXIT: offset doesn't get picked up
    // on first paint - peer not yet exist - so
    // need to handle inside sync()
    fan.fwt.WidgetPeer.setBg(button, self.m_bgPressed);
    this.setShadow(button, self);
    this.offsetContent(self, 0, 1)
  }
  else
  {
    // notify released event
    if (notify)
    {
      var e = fan.fwt.Event.make();
      e.m_id = fan.fwt.EventId.m_mouseUp;
      e.m_widget = self;
      self.onReleased().fire(e);
    }

    // update state
    fan.fwt.WidgetPeer.setBg(button, self.m_bg);
    this.setShadow(button, self);
    this.offsetContent(self, 0, 0)
  }
}

fan.webfwt.StyledButtonPeer.prototype.setShadow = function(button, self)
{
  var shadow = "";
  if (self.m_dropShadow != null)
    shadow += self.m_dropShadow.toCss();

  if (this.m_pressed || self.m_selected)
  {
    if (self.m_innerShadowPressed != null)
    {
      if (shadow.length > 0) shadow += ",";
      shadow += "inset " + self.m_innerShadowPressed.toCss();
    }
  }
  else
  {
    if (self.m_innerShadow != null)
    {
      if (shadow.length > 0) shadow += ",";
      shadow += "inset " + self.m_innerShadow.toCss();
    }
  }

  button.style.webkitBoxShadow = shadow;
  button.style.MozBoxShadow = shadow;
  button.style.boxShadow = shadow;
}

fan.webfwt.StyledButtonPeer.prototype.offsetContent = function(self, dx, dy)
{
  var c = self.m_content;
  if (c != null && c.peer.elem != null)
  {
    if (this.m_origPos == null) this.m_origPos = c.peer.m_pos;
    var p = this.m_origPos;
    c.peer.m_pos = fan.gfx.Point.make(p.m_x+dx, p.m_y+dy);
    c.peer.sync(c);
  }
}

fan.webfwt.StyledButtonPeer.prototype.sync = function(self)
{
  // sync size
  var b = self.m_border;
  var d = self.m_dropShadow;
  var w = this.m_size.m_w - (b == null ? 0 : b.m_widthLeft + b.m_widthRight);
  var h = this.m_size.m_h - (b == null ? 0 : b.m_widthTop + b.m_widthBottom);
  if (d != null) h -= d.m_offset.m_y + d.m_blur + d.m_spread;
  this.elem.style.opacity = this.m_enabled ? "1.0" : "0.35";
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}

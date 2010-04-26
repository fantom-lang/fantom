//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 09  Andy Frank  Creation
//

/**
 * ButtonPeer.
 */
fan.fwt.ButtonPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.ButtonPeer.prototype.$ctor = function(self) {}

fan.fwt.ButtonPeer.prototype.font = function(self) { return this.m_font; }
fan.fwt.ButtonPeer.prototype.font$ = function(self, val) { this.m_font = val; }
fan.fwt.ButtonPeer.prototype.m_font = null;

fan.fwt.ButtonPeer.prototype.image = function(self) { return this.m_image; }
fan.fwt.ButtonPeer.prototype.image$ = function(self, val) { this.m_image = val; }
fan.fwt.ButtonPeer.prototype.m_image = null;

fan.fwt.ButtonPeer.prototype.selected = function(self) { return this.m_selected; }
fan.fwt.ButtonPeer.prototype.selected$ = function(self, val)
{
  this.m_selected = val;
  if (this.elem != null) this.sync(self);
}
fan.fwt.ButtonPeer.prototype.m_selected = false;

fan.fwt.ButtonPeer.prototype.text = function(self) { return this.m_text; }
fan.fwt.ButtonPeer.prototype.text$ = function(self, val) { this.m_text = val; }
fan.fwt.ButtonPeer.prototype.m_text = "";

fan.fwt.ButtonPeer.prototype.m_pressed = false;

fan.fwt.ButtonPeer.prototype.prefSize = function(self, hints)
{
  var pref = fan.fwt.WidgetPeer.prototype.prefSize.call(this, self, hints);
  return fan.gfx.Size.make(pref.m_w, 25);
}

fan.fwt.ButtonPeer.prototype.create = function(parentElem, self)
{
  if (self.m_mode == fan.fwt.ButtonMode.m_push || self.m_mode == fan.fwt.ButtonMode.m_toggle)
    return this.makePush(parentElem, self);

  if (self.m_mode == fan.fwt.ButtonMode.m_check || self.m_mode == fan.fwt.ButtonMode.m_radio)
    return this.makeCheck(parentElem, self);

  // TODO - sep
}

fan.fwt.ButtonPeer.prototype.makePush = function(parentElem, self)
{
  var div = this.emptyDiv();
  var style = div.style;
  style.font = fan.fwt.WidgetPeer.fontToCss(this.m_font==null ? fan.fwt.DesktopPeer.$sysFont : this.m_font);
  style.border  = "1px solid #404040";
  style.MozBorderRadius    = "4px";
  style.webkitBorderRadius = "4px";
  style.textAlign  = "center";
  style.cursor     = "default";
  style.whiteSpace = "nowrap";

  var $this = this;
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
    $this.m_pressed = false;
    $this.repaint(self);
  }

  div.onmouseup = function(event)
  {
    if (!self.enabled()) return;
    if ($this.m_pressed != true) return;  // mouseout before up

    // toggle selected if toggle mode
    if (self.m_mode == fan.fwt.ButtonMode.m_toggle)
      $this.m_selected = !$this.m_selected;

    var evt = fan.fwt.Event.make();
    evt.m_id = fan.fwt.EventId.m_action;
    evt.m_widget = self;

    var list = self.m_onAction.list();
    for (var i=0; i<list.size(); i++) list.get(i).call(evt);

    $this.m_pressed = false;
    $this.repaint(self);
  }

  parentElem.appendChild(div);
  return div;
}

fan.fwt.ButtonPeer.prototype.makeCheck = function(parentElem, self)
{
  var check = document.createElement("input");
  check.type = (self.m_mode == fan.fwt.ButtonMode.m_check) ? "checkbox" : "radio";
  check.style.marginRight = "6px";

  var div = this.emptyDiv();
  with (div.style)
  {
    font = fan.fwt.WidgetPeer.fontToCss(this.m_font==null ? fan.fwt.DesktopPeer.$sysFont : this.m_font);
    whiteSpace = "nowrap";
  }
  div.appendChild(check);
  div.onclick = function(event)
  {
    if (!self.enabled()) return;

    // bind selected to widget
    self.selected$(check.checked);

    var evt = fan.fwt.Event.make();
    evt.m_id = fan.fwt.EventId.m_action;
    evt.m_widget = self;

    var list = self.m_onAction.list();
    for (var i=0; i<list.size(); i++) list.get(i).call(evt);
  }

  parentElem.appendChild(div);
  return div;
}

fan.fwt.ButtonPeer.prototype.repaint = function(self)
{
  // sometimes repaint() is getting called on removed
  // widgets, so now just trap and ignore for now
  if (this.elem == null) return;

  if (self.m_mode == fan.fwt.ButtonMode.m_push ||
      self.m_mode == fan.fwt.ButtonMode.m_toggle)
  {
    var div = this.elem;
    var style = div.style;
    var pressed = this.m_pressed || this.m_selected;

    if (pressed)
    {
      style.padding = "4px 6px 2px 6px";
      fan.fwt.WidgetPeer.setBg(div, fan.gfx.Gradient.fromStr("0% 0%, 0% 100%, #b7b7b7, #c8c8c8 0.10, #cecece 0.10, #d9d9d9"));
    }
    else
    {
      style.padding = "3px 6px";
      if (this.m_enabled)
      {
        style.color = "#000";
        style.border = "1px solid #404040";
        fan.fwt.WidgetPeer.setBg(div, fan.gfx.Gradient.fromStr("0% 0%, 0% 100%, #fefefe, #d8d8d8 0.90, #d1d1d1 0.90, #b9b9b9"));
      }
      else
      {
        style.color = "#999";
        style.border = "1px solid #999";
        style.background = "#e0e0e0";
      }
    }
  }
}

fan.fwt.ButtonPeer.prototype.sync = function(self)
{
  var w = this.m_size.m_w;
  var h = this.m_size.m_h;

  if (self.m_mode == fan.fwt.ButtonMode.m_push ||
      self.m_mode == fan.fwt.ButtonMode.m_toggle)
  {
    var div = this.elem;

    // remove old text node
    while (div.firstChild != null)
    {
      var child = div.firstChild;
      div.removeChild(child);
      child = null;
      delete child;
    }

    // add new text node
    div.appendChild(document.createTextNode(this.m_text));

    // account for padding/border
    h -= 8;
    w -= 14;
  }
  else if (self.m_mode == fan.fwt.ButtonMode.m_check ||
           self.m_mode == fan.fwt.ButtonMode.m_radio)
  {
    var div = this.elem;

    // set state
    var check = this.elem.firstChild;
    check.checked = this.m_selected;

    // set text
    while (div.childNodes.length > 1) div.removeChild(div.lastChild);
    div.appendChild(document.createTextNode(this.m_text));
  }

  this.repaint(self);
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}
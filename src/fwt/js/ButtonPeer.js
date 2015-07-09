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

// CSS
fan.fwt.WidgetPeer.addCss(
  "div._fwt_Button_:focus {" +
  " -webkit-box-shadow:0 0 2px 2px #7baddc;" +
  " -moz-box-shadow:   0 0 2px 2px #7baddc;" +
  " box-shadow:        0 0 2px 2px #7baddc;" +
  "}" +
  "div._fwt_Button_.push {" +
  " color: black;" +
  " border: 1px solid #555;" +
  " border-radius: 4px;" +
  " text-align: center;" +
  " white-space: nowrap;" +
  " padding: 3px 6px;" +
  " background: -webkit-linear-gradient(top, #fefefe, #d8d8d8 90%, #d1d1d1 90%, #b9b9b9);" +
  " background:    -moz-linear-gradient(top, #fefefe, #d8d8d8 90%, #d1d1d1 90%, #b9b9b9);" +
  " background:         linear-gradient(top, #fefefe, #d8d8d8 90%, #d1d1d1 90%, #b9b9b9);" +
  "}" +
  "div._fwt_Button_.push.pressed {" +
  " padding: 4px 6px 2px 6px;" +
  " background: -webkit-linear-gradient(top, #b7b7b7, #c8c8c8 10%, #cecece 10%, #d9d9d9);" +
  " background:    -moz-linear-gradient(top, #b7b7b7, #c8c8c8 10%, #cecece 10%, #d9d9d9);" +
  " background:         linear-gradient(top, #b7b7b7, #c8c8c8 10%, #cecece 10%, #d9d9d9);" +
  "}" +
  "div._fwt_Button_.push.def {" +
  " background: -webkit-linear-gradient(top, #c2d7f3, #a6b8d0 90%, #9aaac0 90%, #91a1b6);" +
  " background:    -moz-linear-gradient(top, #c2d7f3, #a6b8d0 90%, #9aaac0 90%, #91a1b6);" +
  " background:         linear-gradient(top, #c2d7f3, #a6b8d0 90%, #9aaac0 90%, #91a1b6);" +
  "}" +
  "div._fwt_Button_.push.def.pressed {" +
  " background: -webkit-linear-gradient(top, #8f9eb3, #96a6bb 10%, #9eafc6 10%, #a7b9d0);" +
  " background:    -moz-linear-gradient(top, #8f9eb3, #96a6bb 10%, #9eafc6 10%, #a7b9d0);" +
  " background:         linear-gradient(top, #8f9eb3, #96a6bb 10%, #9eafc6 10%, #a7b9d0);" +
  "}");

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

fan.fwt.ButtonPeer.prototype.toolTip = function(self) { return this.m_toolTip; }
fan.fwt.ButtonPeer.prototype.toolTip$ = function(self, val) { this.m_toolTip = val; }
fan.fwt.ButtonPeer.prototype.m_toolTip = "";

fan.fwt.ButtonPeer.prototype.m_pressed = false;

fan.fwt.ButtonPeer.prototype.create = function(parentElem, self)
{
  if (self.m_mode == fan.fwt.ButtonMode.m_push || self.m_mode == fan.fwt.ButtonMode.m_toggle)
    return this.makePush(parentElem, self);

  if (self.m_mode == fan.fwt.ButtonMode.m_check || self.m_mode == fan.fwt.ButtonMode.m_radio)
    return this.makeCheck(parentElem, self);

  // else sep
  var sep = this.emptyDiv();
  sep.style.padding = "6px";
  parentElem.appendChild(sep);
  return sep;
}

fan.fwt.ButtonPeer.prototype.m_$defCursor = "default";

fan.fwt.ButtonPeer.prototype.makePush = function(parentElem, self)
{
  var div = document.createElement("div");
  div.tabIndex = 0;
  div.className = "_fwt_Button_ push";
  div.style.font = fan.fwt.WidgetPeer.fontToCss(
    this.m_font==null ? fan.fwt.DesktopPeer.$sysFont : this.m_font);
  div.title = this.m_toolTip;
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

    $this.fireAction(self);
    $this.m_pressed = false;
    $this.repaint(self);
  }

  div.onkeydown = function(event)
  {
    if (!self.enabled()) return;
    if (event.keyCode == 32)
    {
      // consume event
      event.stopPropagation();

      // toggle selected if toggle mode
      if (self.m_mode == fan.fwt.ButtonMode.m_toggle)
        $this.m_selected = !$this.m_selected;

      // indicate press
      $this.m_pressed = true;
      $this.repaint(self);

      // allow time for state change to display, then fire
      // event and restore button state
      setTimeout(function() {
        $this.fireAction(self);
        $this.m_pressed = false;
        $this.repaint(self);
      }, 100);
    }
  }

  var wrap = this.emptyDiv();
  wrap.style.padding = "2px";
  wrap.appendChild(div);
  parentElem.appendChild(wrap);
  return wrap;
}

fan.fwt.ButtonPeer.prototype.makeCheck = function(parentElem, self)
{
  var check = document.createElement("input");
  check.type = (self.m_mode == fan.fwt.ButtonMode.m_check) ? "checkbox" : "radio";
  check.style.marginRight = "6px";

  var div = this.emptyDiv();
  div.title = this.m_toolTip;
  with (div.style)
  {
    font = fan.fwt.WidgetPeer.fontToCss(this.m_font==null ? fan.fwt.DesktopPeer.$sysFont : this.m_font);
    whiteSpace = "nowrap";
  }
  div.appendChild(check);
  var $this = this;
  div.onclick = function(event)
  {
    if (!self.enabled()) return;

    // find check value
    var val = check.checked;
    if (event.target.nodeName != "INPUT") val = !val;

    // bind selected to widget
    self.selected$(val);

    // fire event
    $this.fireAction(self);
  }

  parentElem.appendChild(div);
  return div;
}

fan.fwt.ButtonPeer.prototype.$focusElem = function()
{
  if (this.elem == null) return null;
  return this.elem.firstChild;
}

fan.fwt.ButtonPeer.prototype.focus = function(self)
{
  var elem = this.$focusElem();
  if (elem != null) elem.focus();
}

fan.fwt.ButtonPeer.prototype.hasFocus = function(self)
{
  var elem = this.$focusElem();
  if (elem == null) return false;
  return elem === document.activeElement;
}

fan.fwt.ButtonPeer.prototype.fireAction = function(self)
{
  var evt = fan.fwt.Event.make();
  evt.m_id = fan.fwt.EventId.m_action;
  evt.m_widget = self;

  var list = self.onAction().list();
  for (var i=0; i<list.size(); i++) list.get(i).call(evt);
}

fan.fwt.ButtonPeer.prototype.repaint = function(self)
{
  // sometimes repaint() is getting called on removed
  // widgets, so now just trap and ignore for now
  if (this.elem == null) return;

  if (self.m_mode == fan.fwt.ButtonMode.m_push ||
      self.m_mode == fan.fwt.ButtonMode.m_toggle)
  {
    var div = this.elem.firstChild;
    var style = div.style;
    var pressed = this.m_pressed || this.m_selected;

    if (pressed) fan.fwt.WidgetPeer.addClassName(div, "pressed");
    else fan.fwt.WidgetPeer.removeClassName(div, "pressed");
  }
}

fan.fwt.ButtonPeer.prototype.sync = function(self)
{
  var w = this.m_size.m_w;
  var h = this.m_size.m_h;

  if (self.m_mode == fan.fwt.ButtonMode.m_push ||
      self.m_mode == fan.fwt.ButtonMode.m_toggle)
  {
    var div = this.elem.firstChild;
    div.tabIndex = this.m_enabled ? 0 : -1;
    div.title = this.m_toolTip;

    // set def
    if (this.m_def == true) fan.fwt.WidgetPeer.addClassName(div, "def");

    // remove old text node
    while (div.firstChild != null)
    {
      var child = div.firstChild;
      div.removeChild(child);
      child = null;
      delete child;
    }

    // create new text node
    var textNode = document.createTextNode(this.m_text);

    if (this.m_image != null)
    {
      // create img elem
      var img = document.createElement("img");
      img.border = "0";
      img.src = fan.fwt.WidgetPeer.uriToImageSrc(this.m_image.m_uri);
      img.style.verticalAlign = "middle";
      img.style.lineHeight = this.m_image.m_h + "px";

      // create wrapper
      var wrap = document.createElement("div");
      wrap.appendChild(img);

      // add text if non-empty
      if (this.m_text.length > 0)
      {
        img.style.paddingRight = "4px";

        var text = document.createElement("div");
        text.style.display = "inline-block";
        text.style.position = "relative";
        text.style.top = "-1px";
        text.style.verticalAlign = "middle";
        if (self.m_fg) text.style.color = self.m_fg.toCss();

        text.appendChild(textNode);
        wrap.appendChild(text);
      }

      // add wrapper
      div.appendChild(wrap);
    }
    else
    {
      // add new text node
      div.appendChild(textNode);
    }

    // account for padding/border
    h -= 4;
    w -= 4;
  }
  else if (self.m_mode == fan.fwt.ButtonMode.m_check ||
           self.m_mode == fan.fwt.ButtonMode.m_radio)
  {
    var div = this.elem;
    div.title = this.m_toolTip;
    div.style.color = self.m_fg ? self.m_fg.toCss() : (this.m_enabled ? "#000" : "#444");

    // set state
    var check = this.elem.firstChild;
    check.checked  = this.m_selected;
    check.disabled = !this.m_enabled;

    // set text
    while (div.childNodes.length > 1) div.removeChild(div.lastChild);
    div.appendChild(document.createTextNode(this.m_text));
  }

  this.repaint(self);
  this.elem.style.opacity = this.m_enabled ? "1.0" : "0.35";
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}
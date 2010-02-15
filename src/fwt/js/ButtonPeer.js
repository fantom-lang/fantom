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
  var outer = this.emptyDiv();
  with (outer.style)
  {
    paddingRight = "6px";
  }

  var inner = document.createElement("div");
  with (inner.style)
  {
    font       = this.m_font==null ? "bold 10pt Arial" : this.m_font.toStr();
    color      = "#333";
    textAlign  = "center";
    cursor     = "default";
    whiteSpace = "nowrap";
    // use repaint for styles that change b/w pressed/unpressed
  }

  var $this = this;
  outer.onmousedown = function(event)
  {
    if (!self.enabled()) return false;
    $this.m_pressed = true;
    $this.repaint(self);
    return false;
  }

  outer.onmouseout = function(event)
  {
    if (!self.enabled()) return;
    $this.m_pressed = false;
    $this.repaint(self);
  }

  outer.onmouseup = function(event)
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

  outer.appendChild(inner)
  parentElem.appendChild(outer);
  return outer;
}

fan.fwt.ButtonPeer.prototype.makeCheck = function(parentElem, self)
{
  var check = document.createElement("input");
  check.type = (self.m_mode == fan.fwt.ButtonMode.m_check) ? "checkbox" : "radio";
  check.style.marginRight = "6px";

  var div = this.emptyDiv();
  with (div.style)
  {
    font = this.m_font==null ? "10pt Arial" : this.m_font.toStr();
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
  if (self.m_mode == fan.fwt.ButtonMode.m_push ||
      self.m_mode == fan.fwt.ButtonMode.m_toggle)
  {
    var outer = this.elem;
    var inner = outer.firstChild;
    var pressed = this.m_pressed || this.m_selected;

    if (pressed)
    {
      with (outer.style)
      {
        var x = outer.offsetWidth-6;
        var uri = fan.sys.UriPodBase + "fwt/res/img/button-right.png";
        background = "url(" + uri + ") no-repeat " + x + "px -25px";
        height = "25px";
      }
      with (inner.style)
      {
        var uri = fan.sys.UriPodBase + "fwt/res/img/button-left.png";
        background = "url(" + uri + ") no-repeat 0 -25px";
        height = "25px";
        padding = "5px 6px 0 12px";
      }
    }
    else
    {
      with (outer.style)
      {
        var uri = fan.sys.UriPodBase + "fwt/res/img/button-right.png";
        background = "url(" + uri + ") no-repeat top right";
        height = "25px";
      }
      with (inner.style)
      {
        var uri = fan.sys.UriPodBase + "fwt/res/img/button-left.png";
        background = "url(" + uri + ") no-repeat";
        height = "25px";
        padding = "4px 6px 0 12px";
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
    var div = this.elem.firstChild;

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
    div.style.color = this.m_enabled ? "#000" : "#999";
    this.elem.style.borderColor =  this.m_enabled ? "#555" : "#999";

    // account for padding/border
    w -= 6;
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
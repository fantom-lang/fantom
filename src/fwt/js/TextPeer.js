//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jun 09  Andy Frank  Creation
//

/**
 * TextPeer.
 */
fan.fwt.TextPeer = fan.sys.Obj.$extend(fan.fwt.TextWidgetPeer);
fan.fwt.TextPeer.prototype.$ctor = function(self)
{
  this.control = null;
}

fan.fwt.TextPeer.prototype.text = function(self) { return this.m_text; }
fan.fwt.TextPeer.prototype.text$ = function(self, val, sync)
{
  this.m_text = val;
  if (sync === undefined) sync = true;
  if (sync && this.control != null) this.control.value = this.m_text;
}
fan.fwt.TextPeer.prototype.m_text = "";

fan.fwt.TextPeer.prototype.create = function(parentElem, self)
{
  // create actual input element
  if (self.m_multiLine)
  {
    var text = document.createElement("textarea");
    text.cols = self.m_prefCols;
    text.rows = self.m_prefRows;
    text.style.resize = "none";
    this.control = text;
  }
  else
  {
    var text = document.createElement("input");
    text.type = self.m_password ? "password" : "text";
    text.size = self.m_prefCols;
    this.control = text;
  }

  // placeholder
  var ph = this.$placeHolder(self);
  if (ph != null) this.control.placeholder = ph;

  // wire up event handlers to keep text prop synchronized
  var $this = this;
  this.control.onkeyup = function(e)
  {
    // fire onModify
    $this.fireModify(self);

    // fire onAction
    if (e.keyCode == 13 && self.onAction().size() > 0)
    {
      var ae = fan.fwt.Event.make();
      ae.m_id = fan.fwt.EventId.m_action;
      ae.m_widget = self;
      var list = self.onAction().list();
      for (var i=0; i<list.size(); i++) list.get(i).call(ae);
    }
  }
  // cut/paste events fire before input.value is set, so use a small delay
  // to allow value to be set so it can be synced to m_text
  text.onpaste = function(event) { setTimeout(function() { $this.fireModify(self); }, 10); }
  text.oncut   = function(event) { setTimeout(function() { $this.fireModify(self); }, 10); }

  // style
  var s = this.control.style;
  s.padding = "3px 2px 2px 2px"
  s.margin  = "0";
  s.outline = "none";
  s.borderBottom = "1px solid #d0d0d0";
  s.borderLeft   = "1px solid #9d9d9d";
  s.borderRight  = "1px solid #afafaf";
  s.borderTop    = "1px solid #707070";
  s.font = fan.fwt.WidgetPeer.fontToCss(this.m_font);

  // assemble
  var div = this.emptyDiv();
  div.appendChild(this.control);
  parentElem.appendChild(div);
  return div;
}

fan.fwt.TextPeer.prototype.fireModify = function(self)
{
  // short-circuit if not modified
  if (this.m_text == this.control.value) return;

  // sync control value to widget
  this.text$(self, this.control.value, false);

  // fire onModify
  if (self.onModify().size() > 0)
  {
    var me = fan.fwt.Event.make();
    me.m_id = fan.fwt.EventId.m_modified;
    me.m_widget = self;
    var list = self.onModify().list();
    for (var i=0; i<list.size(); i++) list.get(i).call(me);
  }
}

fan.fwt.TextPeer.prototype.sync = function(self)
{
  var text = this.control;

  // setting value will force cursor to end of text, so only
  // set if different to avoid relayout "bugs" where cursor
  // jumps unexpectedly
  if (text.value != this.m_text) text.value = this.m_text;

  // sync control
  text.readOnly = !self.m_editable;
  text.disabled = !this.m_enabled;

  // sync style
  var fade = !self.m_editable || !this.m_enabled;
  text.style.background = fade ? "#e4e4e4" : "#fff";
  var shadow = "inset 0px 1px 2px" + (fade ? "#a2a2a2" : "#b7b7b7");
  text.style.webkitBoxShadow = shadow;
  text.style.mozBoxShadow = shadow;
  text.style.boxShadow = shadow;

  // hook for override
  fan.fwt.WidgetPeer.applyStyle(text,
    fade ? this.$disabledStyle(self) : this.$style(self));

  if (self.m_multiLine)
  {
    // cache size
    var oldw = this.elem.style.width;
    var oldh = this.elem.style.height;

    // sync and measure pref
    this.elem.style.width  = "auto";
    this.elem.style.height = "auto";
    var pw = this.elem.offsetWidth;
    var ph = this.elem.offsetHeight;

    // restore old size
    this.elem.style.width  = oldw;
    this.elem.style.height = oldh;

    // check if explicit size
    var w = this.m_size.m_w;
    var h = this.m_size.m_h;
    if ((w > 0 && w != pw) || (h > 0 && h != ph))
    {
      text.style = "absolute";
      text.style.MozBoxSizing = "border-box";
      text.style.boxSizing = "border-box";
      text.style.width  = "100%";
      text.style.height = "100%";
    }
  }

  // sync widget size
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

// Backdoor hook to override style [returns [Str:Str]?]
fan.fwt.TextPeer.prototype.$style = function(self) { return null; }
fan.fwt.TextPeer.prototype.$disabledStyle = function(self) { return null; }

// Backdoor hook to set placeholder text [returns Str?]
fan.fwt.TextPeer.prototype.$placeHolder = function(self) { return null; }

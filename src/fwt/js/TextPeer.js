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
    text.style.position = "absolute";
    text.style.left     = "0px";
    text.style.top      = "1px";
    text.style.outline  = "none";
    text.style.padding  = "2px";
    text.style.resize   = "none";
    text.style.font     = fan.fwt.WidgetPeer.fontToCss(this.m_font);
    this.control = text;
  }
  else
  {
    var text = document.createElement("input");
    text.type = self.m_password ? "password" : "text";
    text.size = self.m_prefCols;
    text.style.outline = "none";
    text.style.padding = "1px 2px 2px 2px";
    text.style.margin  = "0px";
    text.style.font    = fan.fwt.WidgetPeer.fontToCss(this.m_font);
    this.control = text;
  }

  // wire up event handlers to keep text prop synchronized
  var $this = this;
  text.onkeyup = function(e)
  {
    // fire onModify
    $this.fireModify(self);

    // fire onAction
    if (e.keyCode == 13 && self.m_onAction.size() > 0)
    {
      var ae = fan.fwt.Event.make();
      ae.m_id = fan.fwt.EventId.m_action;
      ae.m_widget = self;
      var list = self.m_onAction.list();
      for (var i=0; i<list.size(); i++) list.get(i).call(ae);
    }
  }
  // cut/paste events fire before input.value is set, so use a small delay
  // to allow value to be set so it can be synced to m_text
  text.onpaste = function(event) { setTimeout(function() { $this.fireModify(self); }, 10); }
  text.oncut   = function(event) { setTimeout(function() { $this.fireModify(self); }, 10); }

  // inner div
  var inner = document.createElement("div");
  inner.style.borderTop = "1px solid #ccc";
  inner.appendChild(this.control);

  // container element
  var div = this.emptyDiv();
  div.style.borderBottom = "1px solid #d0d0d0";
  div.style.borderLeft   = "1px solid #9d9d9d";
  div.style.borderRight  = "1px solid #afafaf";
  div.style.borderTop    = "1px solid #707070";
  div.appendChild(inner);
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
  if (self.m_onModify.size() > 0)
  {
    var me = fan.fwt.Event.make();
    me.m_id = fan.fwt.EventId.m_modified;
    me.m_widget = self;
    var list = self.m_onModify.list();
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

  var fade = !self.m_editable || !this.m_enabled;
  text.style.background = fade ? "#e4e4e4" : "#fff";
  text.style.border     = fade ? "1px solid #d7d7d7" : "1px solid #f5f5f5";
  text.style.borderBottom = "none";

  // sync input control size
  if (self.m_multiLine)
  {
    text.style.width  = (this.m_size.m_w - 8) + "px";
    text.style.height = (this.m_size.m_h - 8) + "px";
  }
  else
  {
    text.style.width  = (this.m_size.m_w - 8) + "px";
    text.style.height = (this.m_size.m_h - 7) + "px";
  }

  // sync widget size
  var w = this.m_size.m_w - 2;
  var h = this.m_size.m_h - 2;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}


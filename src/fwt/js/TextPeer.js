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
fan.fwt.TextPeer.prototype.$ctor = function(self) {}

fan.fwt.TextPeer.prototype.text = function(self) { return this.m_text; }
fan.fwt.TextPeer.prototype.text$ = function(self, val, sync)
{
  this.m_text = val;

  if (sync == undefined) sync = true;
  if (sync && this.elem != null && this.elem.firstChild != null)
    this.elem.firstChild.value = this.m_text;
}
fan.fwt.TextPeer.prototype.m_text = "";

fan.fwt.TextPeer.prototype.sync = function(self)
{
  var text = this.elem.firstChild;

  // do we need to create element?
  if (text == null)
  {
    if (self.m_multiLine) { text = document.createElement("textarea"); }
    else { text = document.createElement("input"); text.type = "text"; }
    this.elem.appendChild(text);
  }

  // sync control
  text.value = this.m_text;
  text.readOnly = !self.m_editable;
  text.disabled = !this.m_enabled;
  if (self.m_multiLine)
  {
    // TODO - this differs a pixel or two by browser - so we'll need
    // to go back and fine tune
    text.style.width  = (this.m_size.m_w-6)+'px';
    text.style.height = (this.m_size.m_h-7)+'px';
  }
  else
  {
    // TODO - can we use CSS here for size??
    text.size  = self.m_prefCols;
  }
  text.onkeyup = function(event)
  {
    // IE-ness
    var target = event ? event.target : window.event.srcElement;
    var event  = event ? event : window.event;

    // sync control value to widget
    self.peer.text$(self, target.value, false);

    // fire onAction
    if (event.keyCode == 13 && self.m_onAction.size() > 0)
    {
      var ae = fan.fwt.Event.make();
      ae.id = fan.fwt.EventId.m_action;
      var list = self.m_onAction.list();
      for (var i=0; i<list.length; i++) list[i].call(ae);
    }

    // fire onModify
    if (self.m_onModify.size() > 0)
    {
      var me = fan.fwt.Event.make();
      me.id = fan.fwt.EventId.m_action;
      var list = self.m_onModify.list();
      for (var i=0; i<list.length; i++) list[i].call(me);
    }
  }
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}
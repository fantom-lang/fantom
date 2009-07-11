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

fan.fwt.TextPeer.prototype.text$get = function(self) { return this.text; }
fan.fwt.TextPeer.prototype.text$set = function(self, val)
{
  this.text = val;
  if (this.elem != null && this.elem.firstChild != null)
    this.elem.firstChild.value = this.text;
}
fan.fwt.TextPeer.prototype.text = "";

fan.fwt.TextPeer.prototype.sync = function(self)
{
  var text = this.elem.firstChild;

  // do we need to create element?
  if (text == null)
  {
    if (self.multiLine) { text = document.createElement("textarea"); }
    else { text = document.createElement("input"); text.type = "text"; }
    this.elem.appendChild(text);
  }

  // sync control
  text.value = this.text;
  text.readOnly = !self.editable;
  if (self.multiLine)
  {

    // TODO - this differs a pixel or two by browser - so we'll need
    // to go back and fine tune
    text.style.width  = (this.size.w-6)+'px';
    text.style.height = (this.size.h-7)+'px';
  }
  else
  {
    // TODO - can we use CSS here for size??
    text.size  = self.prefCols;
  }
  text.onkeyup = function(event)
  {
    // IE-ness
    var target = event ? event.target : window.event.srcElement;
    var event  = event ? event : window.event;

    // sync control value to widget
    self.text$set(target.value);

    // fire onAction
    if (event.keyCode == 13 && self.onAction.size() > 0)
    {
      var ae = fan.fwt.Event.make();
      ae.id = fan.fwt.EventId.action;
      var list = self.onAction.list();
      for (var i=0; i<list.length; i++) list[i].call(ae);
    }

    // fire onModify
    if (self.onModify.size() > 0)
    {
      var me = fan.fwt.Event.make();
      me.id = fan.fwt.EventId.action;
      var list = self.onModify.list();
      for (var i=0; i<list.length; i++) list[i].call(me);
    }
  }
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}
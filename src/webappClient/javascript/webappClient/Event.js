//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Feb 09  Andy Frank  Creation
//

var webappClient_Event = sys_Obj.extend(
{
  $ctor: function() {},
  type: function() { return sys_Type.find("webappClient::Event"); },

  target: function()
  {
    return webappClient_Elem.make(this.event.target);
  },

  x: function() { return this.event.pageX; },
  y: function() { return this.event.pageY; },

  alt:   function() { return this.event.altKey; },
  ctrl:  function() { return this.event.ctrlKey; },
  shift: function() { return this.event.shiftKey; },

  toStr: function()
  {
    return "Event[" +
      "target:" + this.target() +
      ", x:" + this.x() + ", y:" + this.y() +
      ", alt:" + this.alt() + ", ctrl:" + this.ctrl() + ", shift:" + this.shift() +
      "]";
  }
});

webappClient_Event.make = function(event)
{
  var wrap = new webappClient_Event();
  if (event != null) wrap.event = event;
  return wrap;
}
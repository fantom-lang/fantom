//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Feb 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

var webappClient_Event = sys_Obj.$extend(sys_Obj);

webappClient_Event.prototype.$ctor = function() {}

webappClient_Event.prototype.target = function()
{
  return webappClient_Elem.make(this.event.target);
}

webappClient_Event.prototype.x = function() { return this.event.pageX; }
webappClient_Event.prototype.y = function() { return this.event.pageY; }

webappClient_Event.prototype.alt   = function() { return this.event.altKey; }
webappClient_Event.prototype.ctrl  = function() { return this.event.ctrlKey; }
webappClient_Event.prototype.shift = function() { return this.event.shiftKey; }

webappClient_Event.prototype.type = function()
{
  return sys_Type.find("webappClient::Event");
}

webappClient_Event.prototype.toStr = function()
{
  return "Event[" +
    "target:" + this.target() +
    ", x:" + this.x() + ", y:" + this.y() +
    ", alt:" + this.alt() + ", ctrl:" + this.ctrl() + ", shift:" + this.shift() +
    "]";
}

webappClient_Event.make = function(event)
{
  var wrap = new webappClient_Event();
  if (event != null) wrap.event = event;
  return wrap;
}
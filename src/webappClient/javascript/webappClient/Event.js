//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Feb 09  Andy Frank  Creation
//

sys_Type.addType("webappClient::Event");
var webappClient_Event = sys_Obj.extend(
{
  $ctor: function() {},
  type: function() { return sys_Type.find("webappClient::Event"); },

  target: function()
  {
    return webappClient_Elem.make(this.event.target);
  },

  x: function() { return this.event.pageX; },
  y: function() { return this.event.pageY; }

});

webappClient_Event.make = function(event)
{
  var wrap = new webappClient_Event();
  if (event != null) wrap.event = event;
  return wrap;
}
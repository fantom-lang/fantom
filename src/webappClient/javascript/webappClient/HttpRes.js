//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

var webappClient_HttpRes = sys_Obj.extend(
{
  $ctor: function()
  {
    sys_Type.addType("webappClient::HttpRes");
    this.status.parent = this;
    this.content.parent = this;
  },

  type: function()
  {
    return sys_Type.find("webappClient::HttpRes");
  },

  status:
  {
    get: function() { return val },
    set: function(val) { this.val = val; },
    val: true
  },

  content:
  {
    get: function() { return val },
    set: function(val) { this.val = val; },
    val: true
  }
});

webappClient_HttpRes.make = function()
{
  return new webappClient_HttpRes();
}
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Dec 08  Andy Frank  Creation
//

/**
 * Err
 */
var sys_Err = sys_Obj.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function(msg)
  {
    this.msg = msg;
  },

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  type: function()
  {
    return sys_Type.find("sys::Err");
  },

  toString: function()
  {
    return this.type() + ": " + this.msg;
  }

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Err.make = function(cause)
{
  // TODO - needs alot of work!
  if (cause instanceof sys_Err) return cause;
  if (cause instanceof TypeError) return new sys_NullErr(cause.message);
  if ((typeof cause) == "string") return new sys_Err(cause);
  return new sys_Err(cause.message);
}

//////////////////////////////////////////////////////////////////////////
// Err subclasses
//////////////////////////////////////////////////////////////////////////

sys_Type.addType("sys::Err");
sys_Type.addType("sys::ArgErr");
sys_Type.addType("sys::IOErr");
sys_Type.addType("sys::IndexErr");
sys_Type.addType("sys::NullErr");
sys_Type.addType("sys::ParseErr");

var sys_ArgErr = sys_Err.extend(
{
  $ctor: function(msg) { this._super(msg); },
  type: function() { return sys_Type.find("sys::ArgErr"); }
});
sys_ArgErr.make = function (msg) { return new sys_ArgErr(msg); }

var sys_NullErr  = sys_Err.extend(
{
  $ctor: function(msg) { this._super(msg); },
  type: function() { return sys_Type.find("sys::NullErr"); }
});
sys_NullErr.make = function (msg) { return new sys_NullErr(msg); }

var sys_IOErr  = sys_Err.extend(
{
  $ctor: function(msg) { this._super(msg); },
  type: function() { return sys_Type.find("sys::IOErr"); }
});
sys_IOErr.make = function (msg) { return new sys_IOErr(msg); }

var sys_IndexErr = sys_Err.extend(
{
  $ctor: function(msg) { this._super(msg); },
  type: function() { return sys_Type.find("sys::IndexErr"); }
});
sys_IndexErr.make = function (msg) { return new sys_IndexErr(msg); }

var sys_ParseErr = sys_Err.extend(
{
  $ctor: function(type, val, more)
  {
    var msg = type;
    if (val != undefined)
    {
      msg = "Invalid " + type + ": '" + val + "'";
      if (more != undefined) msg += ": " + more;
    }
    this._super(msg)
  },
  type: function() { return sys_Type.find("sys::ParseErr"); }
});
sys_ParseErr.make = function(type, val, more) { return new sys_ParseErr(type,val,more); }

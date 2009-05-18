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
  return new sys_Err(cause == undefined ? cause : cause.message);
}

sys_Err.trace = function(self)
{
  // TODO
  //if (println) println(self);
  //else alert(self);
}

//////////////////////////////////////////////////////////////////////////
// Err subclasses
//////////////////////////////////////////////////////////////////////////

// ArgErr
var sys_ArgErr = sys_Err.extend(
{
  $ctor: function(msg) { this._super(msg); },
  type: function() { return sys_Type.find("sys::ArgErr"); }
});
sys_ArgErr.make = function(msg) { return new sys_ArgErr(msg); }

// NullErr
var sys_NullErr  = sys_Err.extend(
{
  $ctor: function(msg) { this._super(msg); },
  type: function() { return sys_Type.find("sys::NullErr"); }
});
sys_NullErr.make = function(msg) { return new sys_NullErr(msg); }

// IOErr
var sys_IOErr  = sys_Err.extend(
{
  $ctor: function(msg) { this._super(msg); },
  type: function() { return sys_Type.find("sys::IOErr"); }
});
sys_IOErr.make = function(msg) { return new sys_IOErr(msg); }

// IndexErr
var sys_IndexErr = sys_Err.extend(
{
  $ctor: function(msg) { this._super(msg); },
  type: function() { return sys_Type.find("sys::IndexErr"); }
});
sys_IndexErr.make = function(msg) { return new sys_IndexErr(msg); }

// ParseErr
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

// ReadonlyErr
var sys_ReadonlyErr = sys_Err.extend(
{
  $ctor: function(msg) { this._super(msg); },
  type: function() { return sys_Type.find("sys::ReadonlyErr"); }
});
sys_ReadonlyErr.make = function(msg) { return new sys_ReadonlyErr(msg); }

// UnknownPodErr
var sys_UnknownPodErr = sys_Err.extend(
{
  $ctor: function(msg) { this._super(msg); },
  type: function() { return sys_Type.find("sys::UnknownPodErr"); }
});
sys_UnknownPodErr.make = function(msg) { return new sys_UnknownPodErr(msg); }

// UnknownTypeErr
var sys_UnknownTypeErr = sys_Err.extend(
{
  $ctor: function(msg) { this._super(msg); },
  type: function() { return sys_Type.find("sys::UnknownTypeErr"); }
});
sys_UnknownTypeErr.make = function(msg) { return new sys_UnknownTypeErr(msg); }

// UnknownSlotErr
var sys_UnknownSlotErr = sys_Err.extend(
{
  $ctor: function(msg) { this._super(msg); },
  type: function() { return sys_Type.find("sys::UnknownSlotErr"); }
});
sys_UnknownSlotErr.make = function(msg) { return new sys_UnknownSlotErr(msg); }


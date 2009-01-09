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
    this.msg  = msg;
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
  },

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Err.make = function(cause)
{
  // TODO - needs alot of work!
  if (cause instanceof TypeError)
    return new sys_NullErr(cause.message);
  return new sys_Err(cause.message);
}

//////////////////////////////////////////////////////////////////////////
// Err subclasses
//////////////////////////////////////////////////////////////////////////

var sys_NullErr  = sys_Err.extend(
{
  type: function()
  {
    return sys_Type.find("sys::NullErr");
  }
});

var sys_IndexErr = sys_Err.extend(
{
  type: function()
  {
    return sys_Type.find("sys::IndexErr");
  }
});

var sys_ParseErr = sys_Err.extend(
{
  _ctor: function(type, val, more)
  {
    var msg = "Invalid " + type + ": '" + val + "'";
    if (more != null) msg += ": " + more;
    this._super(msg)
  },

  type: function()
  {
    return sys_Type.find("sys::ParseErr");
  }
});
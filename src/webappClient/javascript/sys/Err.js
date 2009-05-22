//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Err
 */
var sys_Err = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Err.prototype.$ctor = function(msg)
{
  this.msg = msg;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_Err.prototype.type = function()
{
  return sys_Type.find("sys::Err");
}

sys_Err.prototype.toString = function()
{
  return this.type() + ": " + this.msg;
}

//////////////////////////////////////////////////////////////////////////
// Static
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
  sys_Obj.echo(self)
}

//////////////////////////////////////////////////////////////////////////
// Err subclasses
//////////////////////////////////////////////////////////////////////////

// ArgErr
var sys_ArgErr = sys_Obj.$extend(sys_Err);
sys_ArgErr.prototype.$ctor = function(msg) { sys_Err.prototype.$ctor.call(this, msg); }
sys_ArgErr.prototype.type = function() { return sys_Type.find("sys::ArgErr"); }
sys_ArgErr.make = function(msg) { return new sys_ArgErr(msg); }

// NullErr
var sys_NullErr = sys_Obj.$extend(sys_Err);
sys_NullErr.prototype.$ctor = function(msg) { sys_Err.prototype.$ctor.call(this, msg); }
sys_NullErr.prototype.type = function() { return sys_Type.find("sys::NullErr"); }
sys_NullErr.make = function(msg) { return new sys_NullErr(msg); }

// IOErr
var sys_IOErr = sys_Obj.$extend(sys_Err);
sys_IOErr.prototype.$ctor = function(msg) { sys_Err.prototype.$ctor.call(this, msg); }
sys_IOErr.prototype.type = function() { return sys_Type.find("sys::IOErr"); }
sys_IOErr.make = function(msg) { return new sys_IOErr(msg); }

// IndexErr
var sys_IndexErr = sys_Obj.$extend(sys_Err);
sys_IndexErr.prototype.$ctor = function(msg) { sys_Err.prototype.$ctor.call(this, msg); }
sys_IndexErr.prototype.type = function() { return sys_Type.find("sys::IndexErr"); }
sys_IndexErr.make = function(msg) { return new sys_IndexErr(msg); }

// ParseErr
var sys_ParseErr = sys_Obj.$extend(sys_Err);
sys_ParseErr.prototype.$ctor = function(type, val, more)
{
  var msg = type;
  if (val != undefined)
  {
    msg = "Invalid " + type + ": '" + val + "'";
    if (more != undefined) msg += ": " + more;
  }
  sys_Err.prototype.$ctor.call(this, msg)
}
sys_ParseErr.prototype.type = function() { return sys_Type.find("sys::ParseErr"); }
sys_ParseErr.make = function(type, val, more) { return new sys_ParseErr(type,val,more); }

// ReadonlyErr
var sys_ReadonlyErr = sys_Obj.$extend(sys_Err);
sys_ReadonlyErr.prototype.$ctor = function(msg) { sys_Err.prototype.$ctor.call(this, msg); }
sys_ReadonlyErr.prototype.type = function() { return sys_Type.find("sys::ReadonlyErr"); }
sys_ReadonlyErr.make = function(msg) { return new sys_ReadonlyErr(msg); }

// UnknownPodErr
var sys_UnknownPodErr = sys_Obj.$extend(sys_Err);
sys_UnknownPodErr.prototype.$ctor = function(msg) { sys_Err.prototype.$ctor.call(this, msg); }
sys_UnknownPodErr.prototype.type = function() { return sys_Type.find("sys::UnknownPodErr"); }
sys_UnknownPodErr.make = function(msg) { return new sys_UnknownPodErr(msg); }

// UnknownTypeErr
var sys_UnknownTypeErr = sys_Obj.$extend(sys_Err);
sys_UnknownTypeErr.prototype.$ctor = function(msg) { sys_Err.prototype.$ctor.call(this, msg); }
sys_UnknownTypeErr.prototype.type = function() { return sys_Type.find("sys::UnknownTypeErr"); }
sys_UnknownTypeErr.make = function(msg) { return new sys_UnknownTypeErr(msg); }

// UnknownSlotErr
var sys_UnknownSlotErr = sys_Obj.$extend(sys_Err);
sys_UnknownSlotErr.prototype.$ctor = function(msg) { sys_Err.prototype.$ctor.call(this, msg); }
sys_UnknownSlotErr.prototype.type = function() { return sys_Type.find("sys::UnknownSlotErr"); }
sys_UnknownSlotErr.make = function(msg) { return new sys_UnknownSlotErr(msg); }


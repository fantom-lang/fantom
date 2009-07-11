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
fan.sys.Err = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Err.prototype.$ctor = function(msg)
{
  this.msg = msg;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Err.prototype.type = function()
{
  return fan.sys.Type.find("sys::Err");
}

fan.sys.Err.prototype.toString = function()
{
  return this.type() + ": " + this.msg;
}

fan.sys.Err.prototype.message = function()
{
  return this.msg;
}

fan.sys.Err.prototype.traceToStr = function()
{
  return this.toString();
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Err.make = function(cause)
{
  // TODO - needs alot of work!
  if (cause instanceof fan.sys.Err) return cause;
  if (cause instanceof TypeError) return new fan.sys.NullErr(cause.message);
  if ((typeof cause) == "string") return new fan.sys.Err(cause);
  return new fan.sys.Err(''+cause);
}

fan.sys.Err.trace = function(self)
{
  fan.sys.Obj.echo(self)
}

//////////////////////////////////////////////////////////////////////////
// Err subclasses
//////////////////////////////////////////////////////////////////////////

// ArgErr
fan.sys.ArgErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.ArgErr.prototype.$ctor = function(msg) { fan.sys.Err.prototype.$ctor.call(this, msg); }
fan.sys.ArgErr.prototype.type = function() { return fan.sys.Type.find("sys::ArgErr"); }
fan.sys.ArgErr.make = function(msg) { return new fan.sys.ArgErr(msg); }

// NullErr
fan.sys.NullErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.NullErr.prototype.$ctor = function(msg) { fan.sys.Err.prototype.$ctor.call(this, msg); }
fan.sys.NullErr.prototype.type = function() { return fan.sys.Type.find("sys::NullErr"); }
fan.sys.NullErr.make = function(msg) { return new fan.sys.NullErr(msg); }

// IOErr
fan.sys.IOErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.IOErr.prototype.$ctor = function(msg) { fan.sys.Err.prototype.$ctor.call(this, msg); }
fan.sys.IOErr.prototype.type = function() { return fan.sys.Type.find("sys::IOErr"); }
fan.sys.IOErr.make = function(msg) { return new fan.sys.IOErr(msg); }

// IndexErr
fan.sys.IndexErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.IndexErr.prototype.$ctor = function(msg) { fan.sys.Err.prototype.$ctor.call(this, msg); }
fan.sys.IndexErr.prototype.type = function() { return fan.sys.Type.find("sys::IndexErr"); }
fan.sys.IndexErr.make = function(msg) { return new fan.sys.IndexErr(msg); }

// ParseErr
fan.sys.ParseErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.ParseErr.prototype.$ctor = function(type, val, more)
{
  var msg = type;
  if (val != undefined)
  {
    msg = "Invalid " + type + ": '" + val + "'";
    if (more != undefined) msg += ": " + more;
  }
  fan.sys.Err.prototype.$ctor.call(this, msg)
}
fan.sys.ParseErr.prototype.type = function() { return fan.sys.Type.find("sys::ParseErr"); }
fan.sys.ParseErr.make = function(type, val, more) { return new fan.sys.ParseErr(type,val,more); }

// ReadonlyErr
fan.sys.ReadonlyErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.ReadonlyErr.prototype.$ctor = function(msg) { fan.sys.Err.prototype.$ctor.call(this, msg); }
fan.sys.ReadonlyErr.prototype.type = function() { return fan.sys.Type.find("sys::ReadonlyErr"); }
fan.sys.ReadonlyErr.make = function(msg) { return new fan.sys.ReadonlyErr(msg); }

// UnknownPodErr
fan.sys.UnknownPodErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnknownPodErr.prototype.$ctor = function(msg) { fan.sys.Err.prototype.$ctor.call(this, msg); }
fan.sys.UnknownPodErr.prototype.type = function() { return fan.sys.Type.find("sys::UnknownPodErr"); }
fan.sys.UnknownPodErr.make = function(msg) { return new fan.sys.UnknownPodErr(msg); }

// UnknownTypeErr
fan.sys.UnknownTypeErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnknownTypeErr.prototype.$ctor = function(msg) { fan.sys.Err.prototype.$ctor.call(this, msg); }
fan.sys.UnknownTypeErr.prototype.type = function() { return fan.sys.Type.find("sys::UnknownTypeErr"); }
fan.sys.UnknownTypeErr.make = function(msg) { return new fan.sys.UnknownTypeErr(msg); }

// UnknownSlotErr
fan.sys.UnknownSlotErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnknownSlotErr.prototype.$ctor = function(msg) { fan.sys.Err.prototype.$ctor.call(this, msg); }
fan.sys.UnknownSlotErr.prototype.type = function() { return fan.sys.Type.find("sys::UnknownSlotErr"); }
fan.sys.UnknownSlotErr.make = function(msg) { return new fan.sys.UnknownSlotErr(msg); }

// UnsupportedErr
fan.sys.UnsupportedErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnsupportedErr.prototype.$ctor = function(msg) { fan.sys.Err.prototype.$ctor.call(this, msg); }
fan.sys.UnsupportedErr.prototype.type = function() { return fan.sys.Type.find("sys::UnsupportedErr"); }
fan.sys.UnsupportedErr.make = function(msg) { return new fan.sys.UnsupportedErr(msg); }

// UnresolvedErr
fan.sys.UnresolvedErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnresolvedErr.prototype.$ctor = function(msg) { fan.sys.Err.prototype.$ctor.call(this, msg); }
fan.sys.UnresolvedErr.prototype.type = function() { return fan.sys.Type.find("sys::UnresolvedErr"); }
fan.sys.UnresolvedErr.make = function(msg) { return new fan.sys.UnresolvedErr(msg); }


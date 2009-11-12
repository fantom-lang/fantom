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

fan.sys.Err.prototype.$ctor = function(message, cause)
{
  this.m_message = message;
  this.m_cause   = cause;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Err.prototype.cause = function()
{
  return this.m_cause;
}

fan.sys.Err.prototype.type = function()
{
  return fan.sys.Type.find("sys::Err");
}

fan.sys.Err.prototype.toStr = function()
{
  return this.type() + ": " + this.m_message;
}

fan.sys.Err.prototype.message = function()
{
  return this.m_message;
}

fan.sys.Err.prototype.trace = function()
{
  fan.sys.Obj.echo(this.traceToStr());
}

fan.sys.Err.prototype.traceToStr = function()
{
  var s = this.type() + ": " + this.m_message;
  if (this.m_cause != null)
  {
    s += "\n  Caused by: " + this.m_cause.traceToStr();
  }
  return s;
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Err.make = function(err, cause)
{
  if (err instanceof fan.sys.Err) return err;
  if (err instanceof Error)
  {
    // TODO
    //  EvalError
    //  RangeError
    //  ReferenceError
    //  SyntaxError
    //  TypeError
    //  URIError
    return new fan.sys.Err(err.message);
  }
  return new fan.sys.Err("" + err, cause);
}

//////////////////////////////////////////////////////////////////////////
// Err subclasses
//////////////////////////////////////////////////////////////////////////

// ArgErr
fan.sys.ArgErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.ArgErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.ArgErr.prototype.type = function() { return fan.sys.Type.find("sys::ArgErr"); }
fan.sys.ArgErr.make = function(msg, cause) { return new fan.sys.ArgErr(msg, cause); }

// CastErr
fan.sys.CastErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.CastErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.CastErr.prototype.type = function() { return fan.sys.Type.find("sys::CastErr"); }
fan.sys.CastErr.make = function(msg, cause) { return new fan.sys.CastErr(msg, cause); }

// NullErr
fan.sys.NullErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.NullErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.NullErr.prototype.type = function() { return fan.sys.Type.find("sys::NullErr"); }
fan.sys.NullErr.make = function(msg, cause) { return new fan.sys.NullErr(msg, cause); }

// IOErr
fan.sys.IOErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.IOErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.IOErr.prototype.type = function() { return fan.sys.Type.find("sys::IOErr"); }
fan.sys.IOErr.make = function(msg, cause) { return new fan.sys.IOErr(msg, cause); }

// IndexErr
fan.sys.IndexErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.IndexErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.IndexErr.prototype.type = function() { return fan.sys.Type.find("sys::IndexErr"); }
fan.sys.IndexErr.make = function(msg, cause) { return new fan.sys.IndexErr(msg, cause); }

// NameErr
fan.sys.NameErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.NameErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.NameErr.prototype.type = function() { return fan.sys.Type.find("sys::NameErr"); }
fan.sys.NameErr.make = function(msg, cause) { return new fan.sys.NameErr(msg, cause); }

// ParseErr
fan.sys.ParseErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.ParseErr.prototype.$ctor = function(type, val, more, cause)
{
  var msg = type;
  if (val != undefined)
  {
    msg = "Invalid " + type + ": '" + val + "'";
    if (more != undefined) msg += ": " + more;
  }
  fan.sys.Err.prototype.$ctor.call(this, msg, cause)
}
fan.sys.ParseErr.prototype.type = function() { return fan.sys.Type.find("sys::ParseErr"); }
fan.sys.ParseErr.make = function(type, val, more, cause) { return new fan.sys.ParseErr(type,val,more,cause); }

// ReadonlyErr
fan.sys.ReadonlyErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.ReadonlyErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.ReadonlyErr.prototype.type = function() { return fan.sys.Type.find("sys::ReadonlyErr"); }
fan.sys.ReadonlyErr.make = function(msg, cause) { return new fan.sys.ReadonlyErr(msg, cause); }

// UnknownPodErr
fan.sys.UnknownPodErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnknownPodErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.UnknownPodErr.prototype.type = function() { return fan.sys.Type.find("sys::UnknownPodErr"); }
fan.sys.UnknownPodErr.make = function(msg, cause) { return new fan.sys.UnknownPodErr(msg, cause); }

// UnknownTypeErr
fan.sys.UnknownTypeErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnknownTypeErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.UnknownTypeErr.prototype.type = function() { return fan.sys.Type.find("sys::UnknownTypeErr"); }
fan.sys.UnknownTypeErr.make = function(msg, cause) { return new fan.sys.UnknownTypeErr(msg, cause); }

// UnknownSlotErr
fan.sys.UnknownSlotErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnknownSlotErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.UnknownSlotErr.prototype.type = function() { return fan.sys.Type.find("sys::UnknownSlotErr"); }
fan.sys.UnknownSlotErr.make = function(msg, cause) { return new fan.sys.UnknownSlotErr(msg, cause); }

// UnsupportedErr
fan.sys.UnsupportedErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnsupportedErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.UnsupportedErr.prototype.type = function() { return fan.sys.Type.find("sys::UnsupportedErr"); }
fan.sys.UnsupportedErr.make = function(msg, cause) { return new fan.sys.UnsupportedErr(msg, cause); }

// UnresolvedErr
fan.sys.UnresolvedErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnresolvedErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.UnresolvedErr.prototype.type = function() { return fan.sys.Type.find("sys::UnresolvedErr"); }
fan.sys.UnresolvedErr.make = function(msg, cause) { return new fan.sys.UnresolvedErr(msg, cause); }


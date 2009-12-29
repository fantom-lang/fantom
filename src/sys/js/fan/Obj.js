//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

// Define the "uber-pod" and sys pods
var fan = {};
fan.sys = {};

/**
 * Obj is the base class for all Fantom types.
 */
fan.sys.Obj = function() {};

//////////////////////////////////////////////////////////////////////////
// OO
//////////////////////////////////////////////////////////////////////////

/**
 * Handles the boilerplate code for implementing OO-style
 * inhertiance in Javascript.
 */
fan.sys.Obj.$init = {};
fan.sys.Obj.$extend = function(base)
{
  //function f() { this.$ctor.apply(this, arguments); }
  function f()
  {
    if (arguments.length > 0 && arguments[0] === fan.sys.Obj.$init) return;
    this.$ctor.apply(this, arguments);
  }
  //f.prototype = new base;
  f.prototype = new base(fan.sys.Obj.$init)
  f.prototype.constructor = f;
  return f;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Obj.prototype.$ctor = function() {}
fan.sys.Obj.prototype.make$ = function() {}

fan.sys.Obj.prototype.equals = function(that)
{
  return this === that;
}

fan.sys.Obj.prototype.compare = function(that)
{
  if (this < that) return -1;
  if (this > that) return 1;
  return 0;
}

fan.sys.Obj.prototype.$with = function(f)
{
  f.call(this);
  return this;
}

fan.sys.Obj.prototype.isImmutable = function()
{
  return this.type().isConst();
}

fan.sys.Obj.prototype.toImmutable = function()
{
  if (this.type().isConst()) return this;
  throw fan.sys.NotImmutableErr.make(this.type().toString());
}

fan.sys.Obj.prototype.type = function()
{
  return fan.sys.Type.find("sys::Obj")
}

fan.sys.Obj.prototype.toStr = function()
{
  return "" + this.type();
}

fan.sys.Obj.prototype.toString = function()
{
  return "" + this.toStr();
}

fan.sys.Obj.prototype.trap = function(name, args)
{
  var slot = this.type().slot(name, true);
  if (slot instanceof fan.sys.Method)
  {
    return slot.invoke(this, args);
  }
  else
  {
    var argSize = (args == null) ? 0 : args.length;
    if (argSize == 0) return slot.get(this);
    if (argSize == 1) // one arg -> setter
    {
      var val = args[0];
      slot.set(this, val);
      return val;
    }
    throw fan.sys.ArgErr.make("Invalid number of args to get or set field '" + name + "'");
  }
}



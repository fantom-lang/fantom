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
 * Obj is the base class for all Fan types.
 */
fan.sys.Obj = function() {};

//////////////////////////////////////////////////////////////////////////
// OO
//////////////////////////////////////////////////////////////////////////

/**
 * Handles the boilerplate code for implementing OO-style
 * inhertiance in Javascript.
 */
fan.sys.Obj.$extend = function(base)
{
  function f() { this.$ctor.apply(this, arguments); }
  f.prototype = new base;
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
  return this == that;
}

fan.sys.Obj.prototype.compare = function(that)
{
  if (this < that) return -1;
  if (this > that) return 1;
  return 0;
}

fan.sys.Obj.prototype.$with = function(func)
{
  func(this);
  return this;
}

fan.sys.Obj.prototype.isImmutable = function()
{
  return false;
}

fan.sys.Obj.prototype.toImmutable = function()
{
  return this;
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

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Obj.equals = function(self, that)
{
  if (self instanceof fan.sys.Obj) return self.equals(that);
  else if (self instanceof Long) return fan.sys.Int.equals(self, that);
  else if ((typeof self) == "number") return fan.sys.Int.equals(self, that);
  else if (self != null && self.constructor == Array) return fan.sys.List.equals(self, that);
  else
  {
    if (self != null && self.$fanType != null)
      return fan.sys.Float.equals(self, that);
    else
      return self == that;
   }
}

fan.sys.Obj.compare = function(self, that)
{
  if (self instanceof fan.sys.Obj)
  {
    if (that == null) return +1;
    return self.compare(that);
  }
  else if (self != null && self.$fanType != null)
  {
    return fan.sys.Float.compare(self, that);
  }
  else
  {
    if (self == null)
    {
      if (that != null) return -1;
      return 0;
    }
    if (that == null) return 1;
    if (self < that) return -1;
    if (self > that) return 1;
    return 0;
  }
}

fan.sys.Obj.is = function(obj, type)
{
  if (obj == null) return false;
  return fan.sys.Obj.type(obj).is(type);
}

fan.sys.Obj.as = function(obj, type)
{
  if (obj == null) return false;
  if (fan.sys.Obj.type(obj).is(type)) return obj;
  return null;
}

fan.sys.Obj.isImmutable = function(self)
{
  if (self instanceof fan.sys.Obj)
    return self.isImmutable();
  else
  {
    if ((typeof self) == "boolean") return true;
    if ((typeof self) == "number") return true;
// TODO
    if (self != null && self.$fanType != null) return true;
    throw new fan.sys.Err("sys::Obj.isImmutable: Not a Fan type: " + self);
  }
}

fan.sys.Obj.toImmutable = function(self)
{
  return self
}

fan.sys.Obj.type = function(self)
{
  if (self == null) throw fan.sys.Err.make("fan.sys.Obj.type: self is null");
  if (self instanceof fan.sys.Obj)
    return self.type();
  else
    return fan.sys.Type.toFanType(self);
}

fan.sys.Obj.toStr = function(obj)
{
  if (obj == null) return "null";
  if (typeof obj == "string") return obj;
  if (obj.constructor == Array) return fan.sys.List.toStr(obj);

  // TODO - can't for the life of me figure how the
  // heck Error.toString would ever try to call Obj.toStr
  // so trap it for now
  if (obj instanceof Error) return Error.prototype.toString.call(obj);

// TEMP
if (obj.$fanType == fan.sys.Type.find("sys::Float")) return fan.sys.Float.toStr(obj);

  return obj.toString();
}

fan.sys.Obj.echo = function(str)
{
  var s = fan.sys.Obj.toStr(str);
  try { console.log(s); }
  catch (e1)
  {
    try { println(s); }
    catch (e2) {} //alert(s); }
  }
}

fan.sys.Obj.$with = function(self, func)
{
  func(self);
  return self;
}


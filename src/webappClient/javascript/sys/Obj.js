//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Obj is the base class for all Fan types.
 */
function sys_Obj() {}

//////////////////////////////////////////////////////////////////////////
// OO
//////////////////////////////////////////////////////////////////////////

/**
 * Handles the boilerplate code for implementing OO-style
 * inhertiance in Javascript.
 */
sys_Obj.$extend = function(base)
{
  function f() { this.$ctor.apply(this, arguments); }
  f.prototype = new base;
  f.prototype.constructor = f;
  return f;
}

/**
 * Mixin the slots from the base type to the target type.
 */
sys_Obj.$mixin = function(target, base)
{
  for (var p in base.prototype)
   target.prototype[p] = base.prototype[p];

  for (var p in base)
    target[p] = base[p];
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_Obj.prototype.$ctor = function() {}
sys_Obj.prototype.$make = function() {}

sys_Obj.prototype.equals = function(that)
{
  return this == that;
}

sys_Obj.prototype.compare = function(that)
{
  if (this < that) return -1;
  if (this > that) return 1;
  return 0;
}

sys_Obj.prototype.$with = function(func)
{
  func(this);
  return this;
}

sys_Obj.prototype.isImmutable = function()
{
  return false;
}

sys_Obj.prototype.type = function()
{
  return sys_Type.find("sys::Obj")
}

sys_Obj.prototype.toStr = function()
{
  return "" + this.type();
}

sys_Obj.prototype.toString = function()
{
  return "" + this.toStr();
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

sys_Obj.equals = function(self, that)
{
  if (self instanceof sys_Obj)
    return self.equals(that);
  else if ((typeof self) == "number")
    return sys_Float.equals(self, that);
  else if (self != null && self.constructor == Array)
    return sys_List.equals(self, that);
  else
  {
    if (self != null && self.$fanType != null)
      return sys_Int.equals(self, that);
    else
      return self == that;
   }
}

sys_Obj.compare = function(self, that)
{
  if (self instanceof sys_Obj)
  {
    if (that == null) return +1;
    return self.compare(that);
  }
  else if ((typeof self) == "number")
  {
    return sys_Float.compare(self, that);
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

sys_Obj.is = function(obj, type)
{
  if (obj == null) return false;
  return sys_Obj.type(obj).is(type);
}

sys_Obj.as = function(obj, type)
{
  if (obj == null) return false;
  if (sys_Obj.type(obj).is(type)) return obj;
  return null;
}

sys_Obj.isImmutable = function(self)
{
  if (self instanceof sys_Obj)
    return self.isImmutable();
  else
  {
    if ((typeof self) == "boolean") return true;
    if ((typeof self) == "number") return true;
// TODO
    if (self != null && self.$fanType != null) return true;
    throw new sys_Err("sys::Obj.isImmutable: Not a Fan type: " + self);
  }
}

sys_Obj.type = function(self)
{
  if (self == null) throw sys_Err.make("sys_Obj.type: self is null");
  if (self instanceof sys_Obj)
    return self.type();
  else
    return sys_Type.toFanType(self);
}

sys_Obj._toStr = function(obj)
{
  if (obj == null) return "null";
  if (typeof obj == "string") return obj;
  if (obj.constructor == Array) return sys_List.toStr(obj);
  return obj.toString();
}

sys_Obj.echo = function(str)
{
  var s = sys_Obj._toStr(str);
  try { console.log(s); }
  catch (e1)
  {
    try { println(s); }
    catch (e2) {} //alert(s); }
  }
}


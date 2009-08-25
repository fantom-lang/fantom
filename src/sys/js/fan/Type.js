//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Type models sys::Type.  Implementation classes are:
 *   - ClassType
 *   - GenericType (ListType, MapType, FuncType)
 *   - NullableType
 */
fan.sys.Type = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.$ctor = function(qname, base, mixins)
{
  // workaround for inhertiance
  if (qname == undefined) return;

  // mixins
  if (mixins == undefined) mixins = [];
  for (var i=0; i<mixins.length; i++)
    mixins[i] = fan.sys.Type.find(mixins[i]);

  var s = qname.split("::");
  this.m_qname   = qname;
  this.m_pod     = fan.sys.Pod.find(s[0]);
  this.m_name    = s[1];
  this.m_base    = base == null ? null : fan.sys.Type.find(base);
  this.m_mixins  = mixins;
  this.m_slots   = [];
  this.m_$qname  = 'fan.' + this.m_pod + '.' + this.m_name;
  this.m_isMixin = false;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.base = function()      { return this.m_base; }
fan.sys.Type.prototype.mixins = function()    { return this.m_mixins; }
fan.sys.Type.prototype.isClass = function()   { return !this.m_isMixin && this.m_base.m_qname != "sys::Enum"; }
fan.sys.Type.prototype.isEnum = function()    { return this.m_base != null && this.m_base.m_qname == "sys::Enum"; }
fan.sys.Type.prototype.isMixin = function()   { return this.m_isMixin; }
fan.sys.Type.prototype.log = function()       { return fan.sys.Log.get(this.m_pod.m_name); }
fan.sys.Type.prototype.name = function()      { return this.m_name; }
fan.sys.Type.prototype.qname = function()     { return this.m_qname; }
fan.sys.Type.prototype.pod = function()       { return this.m_pod; }
fan.sys.Type.prototype.signature = function() { return this.m_qname; }
fan.sys.Type.prototype.toStr = function()     { return this.signature(); }
fan.sys.Type.prototype.toLocale = function()  { return this.signature(); }
fan.sys.Type.prototype.type = function()      { return fan.sys.Type.find("sys::Type"); }
fan.sys.Type.prototype.toListOf = function()  { return new fan.sys.ListType(this); }
fan.sys.Type.prototype.emptyList = function() { return new fan.sys.ListType(this); }

fan.sys.Type.prototype.fits = function(that) { return this.is(that); }
fan.sys.Type.prototype.is = function(that)
{
  if (this.equals(that)) return true;

  // check base class
  var base = this.m_base;
  while (base != null)
  {
    if (base.equals(that)) return true;
    base = base.m_base;
  }

  // check mixins
  var m = this.m_mixins;
  for (var i=0; i<m.length; i++)
    if (fan.sys.Type.isMixin(m[i], that)) return true;

  return false;
}

fan.sys.Type.isMixin = function(mixin, that)
{
  if (mixin.equals(that)) return true;
  var m = mixin.m_mixins;
  for (var i=0; i<m.length; i++)
    if (fan.sys.Type.isMixin(m[i], that))
      return true;
  return false;
}

// TODO
fan.sys.Type.prototype.toNullable = function() { return this; }
fan.sys.Type.prototype.toNonNullable = function() { return this; }

//////////////////////////////////////////////////////////////////////////
// Make
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.make = function()
{
  // return defVal if cached
  if (this.m_$defVal != null) return this.m_$defVal;

  // look for defVal and cache if exists
  var obj = eval(this.m_$qname);
  if (obj.m_defVal != null) { this.m_$defVal = obj.m_defVal; return obj.m_defVal; }
  return obj.make();
}

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.slots = function()
{
  // TODO - include inheritance
  var acc = [];
  for (var i in this.m_slots)
    acc.push(this.m_slots[i]);
  return acc;
}

fan.sys.Type.prototype.methods = function()
{
  // TODO - include inheritance
  var acc = [];
  for (var i in this.m_slots)
    if (this.m_slots[i] instanceof fan.sys.Method)
      acc.push(this.m_slots[i]);
  return acc;
}

fan.sys.Type.prototype.fields = function()
{
  // TODO - include inheritance
  var acc = [];
  for (var i in this.m_slots)
    if (this.m_slots[i] instanceof fan.sys.Field)
      acc.push(this.m_slots[i]);
  return acc;
}

fan.sys.Type.prototype.slot = function(name, checked)
{
  if (checked == undefined) checked = true;
  var s = this.$slot(name);
  if (s == null && checked)
    throw fan.sys.UnknownSlotErr.make(this.m_qname + "." + name);
  return s;
}

fan.sys.Type.prototype.method = function(name, checked)
{
  if (checked == undefined) checked = true;
  var f = this.$slot(name);
  if ((f == null || !(f instanceof fan.sys.Method)) && checked)
    throw fan.sys.UnknownSlotErr.make(this.m_qname + "." + name);
  return f;
}

fan.sys.Type.prototype.field = function(name, checked)
{
  if (checked == undefined) checked = true;
  var f = this.$slot(name);
  if ((f == null || !(f instanceof fan.sys.Field)) && checked)
    throw fan.sys.UnknownSlotErr.make(this.m_qname + "." + name);
  return f;
}

// addMethod
fan.sys.Type.prototype.$am = function(name, flags)
{
  var m = new fan.sys.Method(this, name, flags);
  this.m_slots[name] = m;
  return this;
}

// addField
fan.sys.Type.prototype.$af = function(name, flags, of)
{
  var t = fanx_TypeParser.load(of);
  var f = new fan.sys.Field(this, name, flags, t);
  this.m_slots[name] = f;
  return this;
}

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.$slot = function(name)
{
  // check self first
  var slot = this.m_slots[name];
  if (slot != null) return slot;

  // walk inheritance
  var base = this.m_base;
  while (base != null)
  {
    slot = base.m_slots[name];
    if (slot != null) return slot;
    base = base.m_base;
  }

  // not found
  return null;
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

/**
 * Find the Fan type for this qname.
 */
fan.sys.Type.find = function(sig, checked)
{
  return fanx_TypeParser.load(sig, checked);
}

/**
 * Get the Fan type
 */
fan.sys.Type.toFanType = function(obj)
{
  if (obj== null) throw fan.sys.Err.make("sys::Type.toFanType: obj is null");
  if (obj.$fanType != undefined) return obj.$fanType;
  if ((typeof obj) == "boolean" || obj instanceof Boolean) return fan.sys.Type.find("sys::Bool");
  if ((typeof obj) == "number"  || obj instanceof Number)  return fan.sys.Type.find("sys::Int");
  if ((typeof obj) == "string"  || obj instanceof String)  return fan.sys.Type.find("sys::Str");
  throw fan.sys.Err.make("sys::Type.toFanType: Not a Fan type: " + obj);
}

fan.sys.Type.common = function(objs)
{
  if (objs.length == 0) return fan.sys.Type.find("sys::Obj").toNullable();
  var nullable = false;
  var best = null;
  for (var i=0; i<objs.length; i++)
  {
    var obj = objs[i];
    if (obj == null) { nullable = true; continue; }
    var t = fan.sys.Obj.type(obj);
    if (best == null) { best = t; continue; }
    while (!t.is(best))
    {
      best = best.base();
      if (best == null) return nullable ? fan.sys.Type.find("sys::Obj").toNullable() : fan.sys.Type.find("sys::Obj");
    }
  }
  if (best == null) best = fan.sys.Type.find("sys::Obj");
  return nullable ? best.toNullable() : best;
}

/*************************************************************************
 * ListType
 ************************************************************************/

fan.sys.ListType = fan.sys.Obj.$extend(fan.sys.Type)
fan.sys.ListType.prototype.$ctor = function(v)
{
  this.v = v;
  this.m_mixins = [];
}
fan.sys.ListType.prototype.signature = function() { return this.v.signature() + '[]'; }
fan.sys.ListType.prototype.equals = function(that)
{
  if (that instanceof fan.sys.ListType)
    return this.v.equals(that.v);
  else
    return false;
}

/*************************************************************************
 * MapType
 ************************************************************************/

fan.sys.MapType = fan.sys.Obj.$extend(fan.sys.Type);

fan.sys.MapType.prototype.$ctor = function(k, v)
{
  this.k = k;
  this.v = v;
  this.m_mixins = [];
}

fan.sys.MapType.prototype.signature = function()
{
  return "[" + this.k.signature() + ':' + this.v.signature() + ']';
}

fan.sys.MapType.prototype.equals = function(that)
{
  if (that instanceof fan.sys.MapType)
    return this.k.equals(that.k) && this.v.equals(that.v);
  else
    return false;
}

/*************************************************************************
 * FuncType
 ************************************************************************/

fan.sys.FuncType = fan.sys.Obj.$extend(fan.sys.Type);

fan.sys.FuncType.prototype.$ctor = function(params, ret)
{
  this.params = params;
  this.ret = ret;
  this.m_mixins = [];
}

fan.sys.FuncType.prototype.signature = function()
{
  var s = '|'
  for (var i=0; i<this.params.length; i++)
  {
    if (i > 0) s += ',';
    s += this.params[i].signature();
  }
  s += '->';
  s += this.ret.signature();
  s += '|';
  return s;
}

fan.sys.FuncType.prototype.equals = function(that)
{
  if (that instanceof fan.sys.FuncType)
  {
    if (this.params.length != that.params.length) return false;
    for (var i=0; i<this.params.length; i++)
      if (!this.params[i].equals(that.params[i])) return false;
    return this.ret.equals(that.ret);
  }
  return false;
}

fan.sys.FuncType.prototype.is = function(that)
{
  if (this == that) return true;
  if (that instanceof fan.sys.FuncType)
  {
    // match return type (if void is needed, anything matches)
    if (that.ret.m_qname != "sys::Void" && !this.ret.is(that.ret)) return false;

    // match params - it is ok for me to have less than
    // the type params (if I want to ignore them), but I
    // must have no more
    if (this.params.length > that.params.length) return false;
    for (var i=0; i<this.params.length; ++i)
      if (!that.params[i].is(this.params[i])) return false;

    // this method works for the specified method type
    return true;
  }
  return this.base().is(that);
}


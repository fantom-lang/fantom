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
var sys_Type = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Type.prototype.$ctor = function(qname, base)
{
  // workaround for inhertiance
  if (qname == undefined) return;

  var s = qname.split("::");
  this.m_qname  = qname;
  this.m_pod    = sys_Pod.find(s[0]);
  this.m_name   = s[1];
  this.m_base   = base == null ? null : sys_Type.find(base);
  this.m_slots  = [];
  this.m_$qname = qname.replace("::", "_");
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_Type.prototype.base = function()      { return this.m_base; }
sys_Type.prototype.isClass = function()   { return this.m_base == null || (this.m_base.m_qname != "sys::Enum" && this.m_base.m_qname != "sys::Mixin"); }
sys_Type.prototype.isEnum = function()    { return this.m_base != null && this.m_base.m_qname == "sys::Enum"; }
sys_Type.prototype.isMixin = function()   { return this.m_base != null && this.m_base.m_qname == "sys::Mixin"; }
sys_Type.prototype.name = function()      { return this.n_name; }
sys_Type.prototype.qname = function()     { return this.m_qname; }
sys_Type.prototype.signature = function() { return this.m_qname; }
sys_Type.prototype.toStr = function()     { return this.signature(); }
sys_Type.prototype.toLocale = function()  { return this.signature(); }
sys_Type.prototype.type = function()      { return sys_Type.find("sys::Type"); }
sys_Type.prototype.toListOf = function()  { return new sys_ListType(this); }
sys_Type.prototype.emptyList = function() { return new sys_ListType(this); }

sys_Type.prototype.fits = function(that) { return this.is(that); }
sys_Type.prototype.is = function(that)
{
  if (this.equals(that)) return true;
  var base = this.m_base;
  while (base != null)
  {
    if (base.equals(that)) return true;
    base = base.m_base;
  }
  return false;
}

// TODO
sys_Type.prototype.toNullable = function() { return this; }
sys_Type.prototype.toNonNullable = function() { return this; }

//////////////////////////////////////////////////////////////////////////
// Make
//////////////////////////////////////////////////////////////////////////

sys_Type.prototype.make = function()
{
  if(this.m_$obj == null) this.m_$obj = eval(this.m_$qname);
  return (this.m_$obj.defVal != null) ? this.m_$obj.defVal : this.m_$obj.make();
}

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

sys_Type.prototype.slots = function()
{
  // TODO - include inheritance
  var acc = [];
  for (var i in this.m_slots)
    acc.push(this.m_slots[i]);
  return acc;
}

sys_Type.prototype.methods = function()
{
  // TODO - include inheritance
  var acc = [];
  for (var i in this.m_slots)
    if (this.m_slots[i] instanceof sys_Method)
      acc.push(this.m_slots[i]);
  return acc;
}

sys_Type.prototype.fields = function()
{
  // TODO - include inheritance
  var acc = [];
  for (var i in this.m_slots)
    if (this.m_slots[i] instanceof sys_Field)
      acc.push(this.m_slots[i]);
  return acc;
}

sys_Type.prototype.slot = function(name, checked)
{
  if (checked == undefined) checked = true;
  var s = this.$slot(name);
  if (s == null && checked)
    throw sys_UnknownSlotErr.make(this.m_qname + "." + name);
  return s;
}

sys_Type.prototype.method = function(name, checked)
{
  if (checked == undefined) checked = true;
  var f = this.$slot(name);
  if ((f == null || !(f instanceof sys_Method)) && checked)
    throw sys_UnknownSlotErr.make(this.m_qname + "." + name);
  return f;
}

sys_Type.prototype.field = function(name, checked)
{
  if (checked == undefined) checked = true;
  var f = this.$slot(name);
  if ((f == null || !(f instanceof sys_Field)) && checked)
    throw sys_UnknownSlotErr.make(this.m_qname + "." + name);
  return f;
}

// addMethod
sys_Type.prototype.$am = function(name)
{
  var m = new sys_Method(this, name);
  this.m_slots[name] = m;
  return this;
}

// addField
sys_Type.prototype.$af = function(name, flags, of)
{
  var t = fanx_TypeParser.load(of);
  var f = new sys_Field(this, name, flags, t);
  this.m_slots[name] = f;
  return this;
}

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

sys_Type.prototype.$slot = function(name)
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
sys_Type.find = function(sig, checked)
{
  return fanx_TypeParser.load(sig, checked);
}

/**
 * Get the Fan type
 */
sys_Type.toFanType = function(obj)
{
  if (obj== null) throw sys_Err.make("sys::Type.toFanType: obj is null");
  if (obj.$fanType != undefined) return obj.$fanType;
  if ((typeof obj) == "boolean" || obj instanceof Boolean) return sys_Type.find("sys::Bool");
  if ((typeof obj) == "number"  || obj instanceof Number)  return sys_Type.find("sys::Float");
  if ((typeof obj) == "string"  || obj instanceof String)  return sys_Type.find("sys::Str");
  throw sys_Err.make("sys::Type.toFanType: Not a Fan type: " + obj);
}

sys_Type.common = function(objs)
{
  if (objs.length == 0) return sys_Type.find("sys::Obj").toNullable();
  var nullable = false;
  var best = null;
  for (var i=0; i<objs.length; i++)
  {
    var obj = objs[i];
    if (obj == null) { nullable = true; continue; }
    var t = sys_Obj.type(obj);
    if (best == null) { best = t; continue; }
    while (!t.is(best))
    {
      best = best.base();
      if (best == null) return nullable ? sys_Type.find("sys::Obj").toNullable() : sys_Type.find("sys::Obj");
    }
  }
  if (best == null) best = sys_Type.find("sys::Obj");
  return nullable ? best.toNullable() : best;
}

/*************************************************************************
 * ListType
 ************************************************************************/

var sys_ListType = sys_Obj.$extend(sys_Type)
sys_ListType.prototype.$ctor = function(v) { this.v = v; }
sys_ListType.prototype.signature = function() { return this.v.signature() + '[]'; }
sys_ListType.prototype.equals = function(that)
{
  if (that instanceof sys_ListType)
    return this.v.equals(that.v);
  else
    return false;
}

/*************************************************************************
 * MapType
 ************************************************************************/

var sys_MapType = sys_Obj.$extend(sys_Type);

sys_MapType.prototype.$ctor = function(k, v)
{
  this.k = k;
  this.v = v;
}

sys_MapType.prototype.signature = function()
{
  return "[" + this.k.signature() + ':' + this.v.signature() + ']';
}

sys_MapType.prototype.equals = function(that)
{
  if (that instanceof sys_MapType)
    return this.k.equals(that.k) && this.v.equals(that.v);
  else
    return false;
}

/*************************************************************************
 * FuncType
 ************************************************************************/

var sys_FuncType = sys_Obj.$extend(sys_Type);

sys_FuncType.prototype.$ctor = function(params, ret)
{
  this.params = params;
  this.ret = ret;
}

sys_FuncType.prototype.signature = function()
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

sys_FuncType.prototype.equals = function(that)
{
  if (that instanceof sys_FuncType)
  {
    if (this.params.length != that.params.length) return false;
    for (var i=0; i<this.params.length; i++)
      if (!this.params[i].equals(that.params[i])) return false;
    return this.ret.equals(that.ret);
  }
  return false;
}

sys_FuncType.prototype.is = function(that)
{
  if (this == that) return true;
  if (that instanceof sys_FuncType)
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


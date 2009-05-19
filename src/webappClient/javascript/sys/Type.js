//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 08  Andy Frank  Creation
//

/**
 * Type models sys::Type.  Implementation classes are:
 *   - ClassType
 *   - GenericType (ListType, MapType, FuncType)
 *   - NullableType
 */
var sys_Type = sys_Obj.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function(qname, base)
  {
    var s = qname.split("::");
    this.m_qname  = qname;
    this.m_pod    = sys_Pod.find(s[0]);
    this.m_name   = s[1];
    this.m_base   = base == null ? null : sys_Type.find(base);
    this.m_slots  = [];
    this.m_$qname = qname.replace("::", "_");
  },

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  base: function()      { return this.m_base; },
  isClass: function()   { return this.m_base == null || (this.m_base.m_qname != "sys::Enum" && this.m_base.m_qname != "sys::Mixin"); },
  isEnum: function()    { return this.m_base != null && this.m_base.m_qname == "sys::Enum"; },
  isMixin: function()   { return this.m_base != null && this.m_base.m_qname == "sys::Mixin"; },
  name: function()      { return this.n_name; },
  qname: function()     { return this.m_qname; },
  signature: function() { return this.m_qname; },
  toStr: function()     { return this.signature(); },
  toLocale: function()  { return this.signature(); },
  type: function()      { return sys_Type.find("sys::Type"); },
  toListOf: function()  { return new sys_ListType(this); },
  emptyList: function() { return new sys_ListType(this); },

  fits: function(that) { return this.is(that); },
  is: function(that)
  {
    if (this.equals(that)) return true;
    var base = this.m_base;
    while (base != null)
    {
      if (base.equals(that)) return true;
      base = base.m_base;
    }
    return false;
  },

  // TODO
  toNullable: function() { return this; },
  toNonNullable: function() { return this; },

//////////////////////////////////////////////////////////////////////////
// Make
//////////////////////////////////////////////////////////////////////////

  make: function()
  {
    if(this.m_$obj == null) this.m_$obj = eval(this.m_$qname);
    return (this.m_$obj.defVal != null) ? this.m_$obj.defVal : this.m_$obj.make();
  },

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

  slots: function()
  {
    // TODO - include inheritance
    var acc = [];
    for (var i in this.m_slots)
      acc.push(this.m_slots[i]);
    return acc;
  },

  methods: function()
  {
    // TODO - include inheritance
    var acc = [];
    for (var i in this.m_slots)
      if (this.m_slots[i] instanceof sys_Method)
        acc.push(this.m_slots[i]);
    return acc;
  },

  fields: function()
  {
    // TODO - include inheritance
    var acc = [];
    for (var i in this.m_slots)
      if (this.m_slots[i] instanceof sys_Field)
        acc.push(this.m_slots[i]);
    return acc;
  },

  slot: function(name, checked)
  {
    if (checked == undefined) checked = true;
    var s = this.$slot(name);
    if (s == null && checked)
      throw sys_UnknownSlotErr.make(this.m_qname + "." + name);
    return s;
  },

  method: function(name, checked)
  {
    if (checked == undefined) checked = true;
    var f = this.$slot(name);
    if ((f == null || !(f instanceof sys_Method)) && checked)
      throw sys_UnknownSlotErr.make(this.m_qname + "." + name);
    return f;
  },

  field: function(name, checked)
  {
    if (checked == undefined) checked = true;
    var f = this.$slot(name);
    if ((f == null || !(f instanceof sys_Field)) && checked)
      throw sys_UnknownSlotErr.make(this.m_qname + "." + name);
    return f;
  },

  // addMethod
  $am: function(name)
  {
    var m = new sys_Method(this, name);
    this.m_slots[name] = m;
    return this;
  },

  // addField
  $af: function(name, flags, of)
  {
    var t = fanx_TypeParser.load(of);
    var f = new sys_Field(this, name, flags, t);
    this.m_slots[name] = f;
    return this;
  },

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  $slot: function(name)
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
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  m_base:   null,   // base Type
  m_qname:  null,   // qname
  m_pod:    null,   // pod
  m_name:   null,   // type name
  m_slots:  null,   // slot array
  m_$qname: null    // javascript qname
});

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

var sys_ListType = sys_Type.extend(
{
  $ctor: function(v) { this.v = v; },
  signature: function() { return this.v.signature() + '[]'; },
  equals: function(that)
  {
    if (that instanceof sys_ListType)
      return this.v.equals(that.v);
    else
      return false;
  }
});

/*************************************************************************
 * MapType
 ************************************************************************/

var sys_MapType = sys_Type.extend(
{
  $ctor: function(k, v)
  {
    this.k = k;
    this.v = v;
  },

  signature: function()
  {
    return "[" + this.k.signature() + ':' + this.v.signature() + ']';
  },

  equals: function(that)
  {
    if (that instanceof sys_MapType)
      return this.k.equals(that.k) && this.v.equals(that.v);
    else
      return false;
  }
});

/*************************************************************************
 * FuncType
 ************************************************************************/

var sys_FuncType = sys_Type.extend(
{
  $ctor: function(params, ret)
  {
    this.params = params;
    this.ret = ret;
  },

  signature: function()
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
  },

  equals: function(that)
  {
    if (that instanceof sys_FuncType)
    {
      if (this.params.length != that.params.length) return false;
      for (var i=0; i<this.params.length; i++)
        if (!this.params[i].equals(that.params[i])) return false;
      return this.ret.equals(that.ret);
    }
    return false;
  },

  is: function(that)
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
    return base().is(that);
  }
});


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
    this.m_qname = qname;
    this.n_name  = qname.split("::")[1];
    this.m_base  = base;
    this.m_slots = [];
  },

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  base: function()      { return sys_Type.find(this.m_base); },
  isClass: function()   { return this.m_base != "sys::Enum" && this.m_base != "sys::Mixin"; },
  isEnum: function()    { return this.m_base == "sys::Enum"; },
  isMixin: function()   { return this.m_base == "sys::Mixin"; },
  name: function()      { return this.n_name; },
  qname: function()     { return this.m_qname; },
  signature: function() { return this.m_qname; },
  toStr: function()     { return this.signature(); },
  type: function()      { return sys_Type.find("sys::Type"); },
  toListOf: function()  { return new sys_ListType(this); },
  emptyList: function() { return new sys_ListType(this); },

  // TODO
  toNullable: function() { return this; },
  toNonNullable: function() { return this; },

//////////////////////////////////////////////////////////////////////////
// Make
//////////////////////////////////////////////////////////////////////////

  make: function()
  {
    var jst = this.m_qname.replace("::", "_");
    var str = "(" + jst+ ".defVal != null) ? " + jst + ".defVal : " + jst + ".make();";
    return eval(str);
  },

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

  slots: function()
  {
    var acc = [];
    for (var i in this.m_slots)
      acc.push(this.m_slots[i]);
    return acc;
  },

  fields: function()
  {
    var acc = [];
    for (var i in this.m_slots)
      if (this.m_slots[i] instanceof sys_Field)
        acc.push(this.m_slots[i]);
    return acc;
  },

  slot: function(name, checked)
  {
    if (checked == undefined) checked = true;
    var s = this.m_slots[name];
    if (s == null && checked)
      throw sys_UnknownSlotErr.make(this.m_qname + "." + name);
    return s;
  },

  field: function(name, checked)
  {
    if (checked == undefined) checked = true;
    var f = this.m_slots[name];
    if ((f == null || !(f instanceof sys_Field)) && checked)
      throw sys_UnknownSlotErr.make(this.m_qname + "." + name);
    return f;
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
// Fields
//////////////////////////////////////////////////////////////////////////

  m_base:  null,
  m_qname: null,
  m_name:  null,
  m_slots: null

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
/*
  for (var i=0; i<objs.length; i++)
  {
    var obj = objs[i];
    if (obj == null) { nullable = true; continue; }
    var t = type(obj);
    if (best == null) { best = t; continue; }
    while (!t.is(best))
    {
      best = best.base();
      if (best == null) return nullable ? Sys.ObjType.toNullable() : Sys.ObjType;
    }
  }
*/
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


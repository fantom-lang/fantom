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
    this.n_name = qname.split("::")[1];
    if (base != null) this.m_base = base;
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
  toString: function()  { return this.m_qname; },
  type: function()      { return sys_Type.find("sys::Type"); },

  make: function()
  {
    var jst = this.m_qname.replace("::", "_");
    var str = "(" + jst+ ".defVal != null) ? " + jst + ".defVal : " + jst + ".make();";
    return eval(str);
  },

  // TODO
  slot: function(name, checked) { throw new Error("Type.slot not yet implemented"); },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  m_base: "sys::Obj",
  m_qname: "",
  m_name: ""

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

/**
 * Find the Fan type for this qname.
 */
sys_Type.find = function(qname)
{
  return sys_Type.typeMap[qname];
}

/**
 * Add a Fan type for this qname.
 */
sys_Type.addType = function(qname, base)
{
  sys_Type.typeMap[qname] = new sys_Type(qname, base);
}
sys_Type.typeMap = Array();

/**
 * Get the Fan type
 */
sys_Type.toFanType = function(obj)
{
  if ((typeof obj) == "boolean") return sys_Type.find("sys::Bool");
  //if ((typeof obj) == "number")  return sys_Type.find("sys::Int");
  if ((typeof obj) == "number")  return sys_Type.find("sys::Float");
  if ((typeof obj) == "string")  return sys_Type.find("sys::Str");
  throw new sys_Err("Not a Fan type: " + obj);
}

//////////////////////////////////////////////////////////////////////////
// Built-in Types
//////////////////////////////////////////////////////////////////////////

sys_Type.addType("sys::Bool");
sys_Type.addType("sys::Buf");
sys_Type.addType("sys::Charset");
sys_Type.addType("sys::Date");
sys_Type.addType("sys::DateTime");
sys_Type.addType("sys::Duration");
sys_Type.addType("sys::Enum");
sys_Type.addType("sys::Err");
sys_Type.addType("sys::Field", "sys::Slot");
sys_Type.addType("sys::Float", "sys::Num");
sys_Type.addType("sys::Func");
sys_Type.addType("sys::Int", "sys::Num");
sys_Type.addType("sys::List");
sys_Type.addType("sys::Log");
sys_Type.addType("sys::Map");
sys_Type.addType("sys::Method");
sys_Type.addType("sys::Month", "sys::Enum");
sys_Type.addType("sys::Namespace");
sys_Type.addType("sys::Num");
sys_Type.addType("sys::Obj");
sys_Type.addType("sys::Range");
sys_Type.addType("sys::Slot");
sys_Type.addType("sys::Str");
sys_Type.addType("sys::StrBuf");
sys_Type.addType("sys::Test");
sys_Type.addType("sys::Thread");
sys_Type.addType("sys::Type");
sys_Type.addType("sys::Uri");
sys_Type.addType("sys::Weekday");
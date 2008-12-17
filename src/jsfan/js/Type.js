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

  _ctor: function(qname)
  {
    this.qname = qname;
  },

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  type: function()
  {
    return sys_Type.find("sys::Type");
  },

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
sys_Type.addType = function(qname)
{
  sys_Type.typeMap[qname] = new sys_Type(qname);
}
sys_Type.typeMap = Array();

/**
 * Get the Fan type
 */
sys_Type.toFanType = function(obj)
{
  if ((typeof obj) == "boolean") return sys_Type.find("sys::Bool");
  if ((typeof obj) == "string")  return sys_Type.find("sys::Str");
  throw new sys_Err("Not a Fan type: " + obj);
}

//////////////////////////////////////////////////////////////////////////
// Primitive Types
//////////////////////////////////////////////////////////////////////////

sys_Type.addType("sys::Bool");
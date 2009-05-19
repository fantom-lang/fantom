//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 09  Andy Frank  Creation
//

/**
 * Pod is a module containing Types.
 */
var sys_Pod = sys_Obj.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function(name)
  {
    this.m_name  = name;
    this.m_types = [];
  },

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  findType: function(qname, checked)
  {
    if (checked == undefined) checked = true;
    var t = this.m_types[qname];
    if (t == null && checked)
      throw sys_UnknownTypeErr.make(qname);
    return t;
  },

  toStr: function() { return this.m_name; },

  // addType
  $at: function(name, baseQname)
  {
    var qname = this.m_name + "::" + name;
    if (this.m_types[name] != null)
      throw sys_Err.make("Type already exists " + qname);
    var t = new sys_Type(qname, baseQname);
    this.m_types[name] = t;
    return t;
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  m_name:  null,
  m_types: null

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Pod.list = function()
{
  return sys_Pod.$pods;
}

sys_Pod.find = function(name, checked)
{
  if (checked == undefined) checked = true;
  var p = sys_Pod.$pods[name];
  if (p == null && checked)
    throw sys_UnknownPodErr.make(name);
  return p;
}

sys_Pod.$add = function(name)
{
  if (sys_Pod.$pods[name] != null)
    throw sys_Err.make("Pod already exists " + name);
  var p = new sys_Pod(name);
  sys_Pod.$pods[name] = p;
  return p;
}
sys_Pod.$pods = [];
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Pod is a module containing Types.
 */
var sys_Pod = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Pod.prototype.$ctor = function(name)
{
  this.m_name  = name;
  this.m_types = [];
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_Pod.prototype.name = function()
{
  return this.m_name;
}

sys_Pod.prototype.findType = function(qname, checked)
{
  if (checked == undefined) checked = true;
  var t = this.m_types[qname];
  if (t == null && checked)
    throw sys_UnknownTypeErr.make(qname);
  return t;
}

sys_Pod.prototype.loc = function(key, def)
{
  // TODO
  //if (def == undefined) def = key;

  if (key == "ok.name") return "OK";
  if (key == "cancel.name") return "Cancel";
  if (key == "yes.name") return "Yes";
  if (key == "no.name") return "No";
  if (key == "details.name") return "Details";

  if (key == "err.name") return "Error";
  if (key == "err.image") return "/sys/pod/icons/x32/err.png";

  if (key == "warn.name") return "Warning";
  if (key == "warn.image") return "/sys/pod/icons/x32/warn.png";

  if (key == "info.name") return "Info";
  if (key == "info.image") return "/sys/pod/icons/x32/question.png";

  if (key == "question.name") return "Question";
  if (key == "question.image") return "/sys/pod/icons/x32/question.png";

  return def;
}

sys_Pod.prototype.toStr = function() { return this.m_name; }

// addType
sys_Pod.prototype.$at = function(name, baseQname, mixins)
{
  var qname = this.m_name + "::" + name;
  if (this.m_types[name] != null)
    throw sys_Err.make("Type already exists " + qname);
  var t = new sys_Type(qname, baseQname, mixins);
  this.m_types[name] = t;
  return t;
}

// addMixin
sys_Pod.prototype.$am = function(name, baseQname, mixins)
{
  var t = this.$at(name, baseQname, mixins);
  t.m_isMixin = true;
  return t;
}

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


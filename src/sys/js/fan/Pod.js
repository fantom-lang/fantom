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
fan.sys.Pod = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Pod.prototype.$ctor = function(name)
{
  this.m_name  = name;
  this.m_types = [];
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Pod.prototype.name = function()
{
  return this.m_name;
}

fan.sys.Pod.prototype.types = function()
{
  if (this.$typesArray == null)
  {
    var arr = [];
    for (p in this.m_types) arr.push(this.m_types[p]);
    this.$typesArray = fan.sys.List.make(fan.sys.Type.find("sys::Type"), arr);
  }
  return this.$typesArray;
}

fan.sys.Pod.prototype.findType = function(qname, checked)
{
  if (checked == undefined) checked = true;
  var t = this.m_types[qname];
  if (t == null && checked)
    throw fan.sys.UnknownTypeErr.make(qname);
  return t;
}

fan.sys.Pod.prototype.loc = function(key, def)
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

fan.sys.Pod.prototype.toStr = function() { return this.m_name; }

// addType
fan.sys.Pod.prototype.$at = function(name, baseQname, mixins)
{
  var qname = this.m_name + "::" + name;
  if (this.m_types[name] != null)
    throw fan.sys.Err.make("Type already exists " + qname);
  var t = new fan.sys.Type(qname, baseQname, mixins);
  this.m_types[name] = t;
  return t;
}

// addMixin
fan.sys.Pod.prototype.$am = function(name, baseQname, mixins)
{
  var t = this.$at(name, baseQname, mixins);
  t.m_isMixin = true;
  return t;
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Pod.list = function()
{
  return fan.sys.Pod.$pods;
}

fan.sys.Pod.find = function(name, checked)
{
  if (checked == undefined) checked = true;
  var p = fan.sys.Pod.$pods[name];
  if (p == null && checked)
    throw fan.sys.UnknownPodErr.make(name);
  return p;
}

fan.sys.Pod.$add = function(name)
{
  if (fan.sys.Pod.$pods[name] != null)
    throw fan.sys.Err.make("Pod already exists " + name);
  var p = new fan.sys.Pod(name);
  fan.sys.Pod.$pods[name] = p;
  return p;
}
fan.sys.Pod.$pods = [];


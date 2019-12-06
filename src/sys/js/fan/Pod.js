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
// Management
//////////////////////////////////////////////////////////////////////////

fan.sys.Pod.of = function(obj)
{
  return fan.sys.Type.of(obj).pod();
}

fan.sys.Pod.list = function()
{
  if (fan.sys.Pod.$list == null)
  {
    var pods = fan.sys.Pod.$pods;
    var list = fan.sys.List.make(fan.sys.Pod.$type);
    for (var n in pods) list.add(pods[n]);
    fan.sys.Pod.$list = list.sort().toImmutable();
  }
  return fan.sys.Pod.$list;
}

fan.sys.Pod.load = function(instream) {
  throw fan.sys.UnsupportedErr.make("Pod.load");
}

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Pod.prototype.$ctor = function(name)
{
  this.m_name  = name;
  this.m_types = [];
  this.m_meta = [];
  this.m_version = fan.sys.Version.m_defVal;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Pod.prototype.$typeof = function() { return fan.sys.Pod.$type; }

fan.sys.Pod.prototype.$name = function()
{
  return this.m_name;
}

fan.sys.Pod.prototype.meta = function()
{
  return this.m_meta;
}

fan.sys.Pod.prototype.version = function()
{
  return this.m_version;
}

fan.sys.Pod.prototype.uri = function()
{
  if (this.m_uri == null) this.m_uri = fan.sys.Uri.fromStr("fan://" + this.m_name);
  return this.m_uri;
}

fan.sys.Pod.prototype.depends = function()
{
  if (this.$dependsArray == null)
  {
    var arr = [];
    var depends = this.meta().get("pod.depends").split(";");
    for (var i=0; i<depends.length; ++i) {
      var d = depends[i];
      if (d == "") continue;
      arr.push(fan.sys.Depend.fromStr(d))
    }
    this.$dependsArray = fan.sys.List.make(fan.sys.Depend.$type, arr);
  }
  return this.$dependsArray;
}

fan.sys.Pod.prototype.props = function(uri, maxAge) {
  return fan.sys.Env.cur().props(this, uri, maxAge);
}

fan.sys.Pod.prototype.config = function(key, def) {
  return fan.sys.Env.cur().config(this, key, def);
}

fan.sys.Pod.prototype.doc = function() {
  return null;
}

fan.sys.Pod.prototype.toStr = function() { return this.m_name; }

//////////////////////////////////////////////////////////////////////////
// Files
//////////////////////////////////////////////////////////////////////////

fan.sys.Pod.prototype.files = function() {
  throw fan.sys.UnsupportedErr.make("Pod.files")
}

fan.sys.Pod.prototype.file = function(uri, checked) {
  throw fan.sys.UnsupportedErr.make("Pod.file")
}

//////////////////////////////////////////////////////////////////////////
// Types
//////////////////////////////////////////////////////////////////////////

fan.sys.Pod.prototype.types = function()
{
  if (this.$typesArray == null)
  {
    var arr = [];
    for (p in this.m_types) arr.push(this.m_types[p]);
    this.$typesArray = fan.sys.List.make(fan.sys.Type.$type, arr);
  }
  return this.$typesArray;
}

fan.sys.Pod.prototype.type = function(name, checked)
{
  if (checked === undefined) checked = true;
  var t = this.m_types[name];
  if (t == null && checked)
  {
    //fan.sys.ObjUtil.echo("UnknownType: " + this.m_name + "::" + name);
    //print("# UnknownType: " + this.m_name + "::" + name + "\n");
    throw fan.sys.UnknownTypeErr.make(this.m_name + "::" + name);
  }
  return t;
}

fan.sys.Pod.prototype.locale = function(key, def)
{
  return fan.sys.Env.cur().locale(this, key, def);
}

// addType
fan.sys.Pod.prototype.$at = function(name, baseQname, mixins, facets, flags)
{
  var qname = this.m_name + "::" + name;
  if (this.m_types[name] != null)
    throw fan.sys.Err.make("Type already exists " + qname);
  var t = new fan.sys.Type(qname, baseQname, mixins, facets, flags);
  this.m_types[name] = t;
  return t;
}

// addMixin
fan.sys.Pod.prototype.$am = function(name, baseQname, mixins, facets, flags)
{
  var t = this.$at(name, baseQname, mixins, facets, flags);
  t.m_isMixin = true;
  return t;
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Pod.find = function(name, checked)
{
  if (checked === undefined) checked = true;
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

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

fan.sys.Pod.prototype.log = function()
{
  if (this.m_log == null) this.m_log = fan.sys.Log.get(this.m_name);
  return this.m_log;
}

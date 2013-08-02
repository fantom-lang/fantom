//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Method.
 */
fan.sys.Method = fan.sys.Obj.$extend(fan.sys.Slot);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Method.prototype.$ctor = function(parent, name, flags, returns, params, facets, generic)
{
  if (generic === undefined) generic = null;

  this.m_parent  = parent;
  this.m_name    = name;
  this.m_qname   = parent.qname() + "." + name;
  this.m_flags   = flags;
  this.m_returns = returns;
  this.m_params  = params;
  this.m_func    = new fan.sys.MethodFunc(this, returns);
  this.m_$name   = this.$$name(name);
  this.m_$qname  = this.m_parent.m_$qname + '.' + this.m_$name;
  this.m_facets  = new fan.sys.Facets(facets);
  this.m_mask    = (generic != null) ? 0 : fan.sys.Method.toMask(parent, returns, params);
  this.m_generic = generic;
}

fan.sys.Method.GENERIC = 0x01;
fan.sys.Method.toMask = function(parent, returns, params)
{
  // we only use generics in Sys
  if (parent.pod().$name() != "sys") return 0;

  var p = returns.isGenericParameter() ? 1 : 0;
  for (var i=0; i<params.size(); ++i)
    p |= params.get(i).m_type.isGenericParameter() ? 1 : 0;

  var mask = 0;
  if (p != 0) mask |= fan.sys.Method.GENERIC;
  return mask;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Method.prototype.invoke = function(instance, args)
{
  var func = (this.isCtor() || this.isStatic())
    ? eval(this.m_$qname)
    : instance[this.m_$name];
  var vals = args==null ? [] : args.m_values;

  // if not found, assume this is primitive that needs
  // to map into a static call
  if (func == null && instance != null)
  {
    // Obj maps to ObjUtil
    qname = this.m_$qname;
    if (this.m_parent.m_qname === "sys::Obj")
      qname = "fan.sys.ObjUtil." + this.m_$name;

    func = eval(qname);
    vals.splice(0, 0, instance);
    instance = null;
  }

// TODO FIXIT: if func is null - most likley native
// method hasn't been implemented
if (func == null) fan.sys.ObjUtil.echo("### Method.invoke missing: " + this.m_$qname);

  return func.apply(instance, vals);
}

fan.sys.Method.prototype.$typeof = function() { return fan.sys.Method.$type; }
fan.sys.Method.prototype.returns = function() { return this.m_returns; }
fan.sys.Method.prototype.params  = function() { return this.m_params.ro(); }
fan.sys.Method.prototype.func = function() { return this.m_func; }

//////////////////////////////////////////////////////////////////////////
// Generics
//////////////////////////////////////////////////////////////////////////

fan.sys.Method.prototype.isGenericMethod = function() { return (this.m_mask & fan.sys.Method.GENERIC) != 0; }
fan.sys.Method.prototype.isGenericInstance = function() { return this.m_generic != null; }
fan.sys.Method.prototype.getGenericMethod = function() { return this.m_generic; }

//////////////////////////////////////////////////////////////////////////
// Call Conveniences
//////////////////////////////////////////////////////////////////////////

fan.sys.Method.prototype.callOn = function(target, args) { return this.invoke(target, args); }
fan.sys.Method.prototype.call = function()
{
  var instance = null;
  var args = arguments;

  if (!this.isStatic())
  {
    instance = args[0];
    args = Array.prototype.slice.call(args).slice(1);
  }

  return this.invoke(instance, fan.sys.List.make(fan.sys.Obj.$type, args));
}

fan.sys.Method.prototype.callList = function(args)
{
  var instance = null;
  if (!this.isCtor() && !this.isStatic())
  {
    instance = args.get(0);
    args = args.getRange(new fan.sys.Range(1, -1));
  }
  return this.invoke(instance, args);
}
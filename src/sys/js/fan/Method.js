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

fan.sys.Method.prototype.$ctor = function(parent, name, flags, params)
{
  this.m_parent = parent;
  this.m_name   = name;
  this.m_qname  = parent.qname() + "." + name;
  this.m_flags  = flags;
  this.m_params = params;
  this.m_$name  = this.$name(name);
  this.m_$qname = this.m_parent.m_$qname + '.' + this.m_$name;
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
    func = eval(this.m_$qname);
    vals.splice(0, 0, instance);
    instance = null;
  }

  // TODO FIXIT: if func is null - most likley native
  // method hasn't been implemented
  return func.apply(instance, vals);
}

fan.sys.Method.prototype.$typeof = function() { return fan.sys.Method.$type; }
//fan.sys.Method.prototype.returns = function() { this.m_returns; }
fan.sys.Method.prototype.params  = function() { return this.m_params.ro(); }

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


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

fan.sys.Method.prototype.$ctor = function(parent, name, flags)
{
  this.m_parent = parent;
  this.m_name   = name;
  this.m_qname  = parent.qname() + "." + name;
  this.m_flags  = flags;
  //this.m_of     = of;
  this.m_$name  = this.$name(name);
  this.m_$qname = this.m_parent.m_$qname + '.' + this.m_$name;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Method.prototype.invoke = function(instance, args)
{
  var func = this.isStatic() ? eval(this.m_$qname) : instance[this.m_$name];
  return func.apply(instance, args.m_values);
}

fan.sys.Method.prototype.type = function()
{
  return fan.sys.Method.$type;
}

//////////////////////////////////////////////////////////////////////////
// Call Conveniences
//////////////////////////////////////////////////////////////////////////

fan.sys.Method.prototype.call = function()
{
  var instance = null;
  var args = arguments;

  if (!this.isStatic())
  {
    instance = args[0];
    args = Array.prototype.slice.call(args).slice(1);
  }

  return this.invoke(instance, args);
}


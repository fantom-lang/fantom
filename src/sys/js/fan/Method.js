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

fan.sys.Method.prototype.$ctor = function(parent, name)
{
  this.m_parent = parent;
  this.m_name   = name;
  this.m_qname  = parent.qname() + "." + name;
  //this.m_flags  = flags;
  //this.m_of     = of;
  this.m_$name  = this.$name(name);
  this.m_$qname = 'fan.' + parent.pod() + '.' + parent.name() + '.' + this.m_$name;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Method.prototype.invoke = function(instance, args)
{
  instance[this.m_$name].apply(instance, args)
}

fan.sys.Method.prototype.type = function()
{
  return fan.sys.Type.find("sys::Method");
}


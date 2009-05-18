//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//

/**
 * Method.
 */
var sys_Method = sys_Slot.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function(parent, name)
  {
    this.m_parent = parent;
    this.m_name   = name;
    this.m_qname  = parent.qname() + "." + name;
    //this.m_flags  = flags;
    //this.m_of     = of;
    this.m_$name  = this.$name(name);
    this.m_$qname = parent.qname().replace("::","_") + "." + this.m_$name;
  },

  type: function() { return sys_Type.find("sys::Method"); },

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  invoke: function(instance, args)
  {
    instance[this.m_$name].apply(instance, args)
  }

});
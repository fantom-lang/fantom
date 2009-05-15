//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//

/**
 * Field.
 */
var sys_Field = sys_Slot.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function(parent, name, flags, of)
  {
    this.m_parent = parent;
    this.m_name   = name;
    this.m_qname  = parent.qname() + "." + name;
    this.m_flags  = flags;
    this.m_of     = of;
  },

  type: function() { return sys_Type.find("sys::Field"); },

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  of: function() { return this.m_of; },
  get: function(instance) { return instance[this.m_name]; },

  set: function(instance, value, checkConst)
  {
    if (checkConst == undefined) checkConst = true;

    // check const
    if ((this.m_flags & sys_FConst.Const) != 0)
    {
      if (checkConst)
        throw sys_ReadonlyErr.make("Cannot set const field " + this.m_qname);
      else if (value != null && !isImmutable(value))
        throw sys_ReadonlyErr.make("Cannot set const field " + this.m_qname + " with mutable value");
    }

    // TODO
    // check static
    //if ((flags & FConst.Static) != 0 && !parent.isJava())
    //  throw ReadonlyErr.make("Cannot set static field " + qname()).val;

    // TODO
    // check type
    //if (of.isGenericInstance() && value != null)
    //{
    //  if (!type(value).is(of.toNonNullable()))
    //    throw ArgErr.make("Wrong type for field " + qname() + ": " + of + " != " + type(value)).val;
    //}
    if (value != null)
    {
      if (!this.m_of.equals(sys_Obj.type(value)))
        throw sys_ArgErr.make("Wrong type for field " + this.m_qname + ": " + this.m_of + " != " + sys_Obj.type(value));
    }

    // TODO
    //if (setter != null)
    //{
    //  setter.invoke(instance, new Object[] { value });
    //  return;
    //}

    instance[this.m_name] = value;
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  m_of: null

});
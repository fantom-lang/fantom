//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;
using System.Reflection;
using Fanx.Fcode;
using Fanx.Util;

namespace Fan.Sys
{
  /// <summary>
  /// Field is a slot which "stores" a value.
  /// </summary>
  public class Field : Slot
  {

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public Field(Type parent, string name, int flags, Facets facets, int lineNum, Type of)
      : base(parent, name, flags, facets, lineNum)
    {
      this.m_of = of;
    }

  //////////////////////////////////////////////////////////////////////////
  // Signature
  //////////////////////////////////////////////////////////////////////////

    public override Type type()  { return Sys.FieldType;  }

    public Type of() { return m_of; }

    public override string signature() { return m_of.toStr() + " " + m_name; }

    public override object trap(string name, List args)
    {
      // private undocumented access
      if (name == "getter") return m_getter;
      if (name == "setter") return m_setter;
      return base.trap(name, args);
    }

  //////////////////////////////////////////////////////////////////////////
  // Reflection
  //////////////////////////////////////////////////////////////////////////

    public object get() { return get(null); }
    public virtual object get(object instance)
    {
      m_parent.finish();

      if (m_getter != null)
      {
        return m_getter.invoke(instance, Method.noArgs);
      }

      try
      {
        return FanUtil.box(m_reflect.GetValue(instance));
      }
      catch (Exception e)
      {
        if (m_reflect == null)
          throw Err.make("Field not mapped to System.Reflection.FieldInfo correctly").val;

        throw Err.make(e).val;
      }
    }

    public virtual void set(object instance, object value)
    {
      set(instance, value, true);
    }

    public virtual void set(object instance, object value, bool checkConst)
    {
      m_parent.finish();

      // check const
      if ((m_flags & FConst.Const) != 0)
      {
        if (checkConst)
          throw ReadonlyErr.make("Cannot set const field " + qname()).val;
        else if (value != null && !isImmutable(value))
          throw ReadonlyErr.make("Cannot set const field " + qname() + " with mutable value").val;
      }

      // check static
      if ((m_flags & FConst.Static) != 0)
        throw ReadonlyErr.make("Cannot set static field " + qname()).val;

      // check generic type (the .NET runtime will check non-generics)
      if (m_of.isGenericInstance() && value != null)
      {
        if (!type(value).@is(m_of.toNonNullable()))
          throw ArgErr.make("Wrong type for field " + qname() + ": " + m_of + " != " + type(value)).val;
      }

      if (m_setter != null)
      {
        m_setter.invoke(instance, new object[] { value });
        return;
      }

      try
      {
        m_reflect.SetValue(instance, value);
      }
      catch (ArgumentException e)
      {
        throw ArgErr.make(e).val;
      }
      catch (Exception e)
      {
        if (m_reflect == null)
          throw Err.make("Field not mapped to System.Reflection correctly").val;

        throw Err.make(e).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal Type m_of;
    internal Method m_getter;
    internal Method m_setter;
    internal FieldInfo m_reflect;

  }
}
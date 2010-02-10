//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;
using System.Collections;
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
  // Factories
  //////////////////////////////////////////////////////////////////////////

    public static Func makeSetFunc(Map map)
    {
      return new SetFunc(map);
    }

    internal class SetFunc : Func.Indirect1
    {
      internal SetFunc(Map map) { m_map = map; }
      public override Object call(Object obj)
      {
        IDictionaryEnumerator en = m_map.pairsIterator();
        while (en.MoveNext())
        {
          Field field = (Field)en.Key;
          object val = en.Value;
          field.set(obj, val, obj != m_inCtor);
        }
        return null;
      }
      Map m_map;
    }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public Field(Type parent, string name, int flags, Facets facets, int lineNum, Type type)
      : base(parent, name, flags, facets, lineNum)
    {
      this.m_type = type;
    }

  //////////////////////////////////////////////////////////////////////////
  // Signature
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof()  { return Sys.FieldType;  }

    public Type type() { return m_type; }

    public override string signature() { return m_type.toStr() + " " + m_name; }

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
      if (m_type.isGenericInstance() && value != null)
      {
        if (!@typeof(value).@is(m_type.toNonNullable()))
          throw ArgErr.make("Wrong type for field " + qname() + ": " + m_type + " != " + @typeof(value)).val;
      }

      if (m_setter != null)
      {
        m_setter.invoke(instance, new object[] { value });
        return;
      }

      try
      {
        m_reflect.SetValue(instance, unbox(value));
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

    object unbox(object val)
    {
      System.Type t = m_reflect.FieldType;
      if (val is Boolean) return t == BoolType   ? ((Boolean)val).booleanValue() : val;
      if (val is Double)  return t == DoubleType ? ((Double)val).doubleValue()   : val;
      if (val is Long)    return t == Int64Type  ? ((Long)val).longValue()       : val;
      return val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    static System.Type BoolType   = System.Type.GetType("System.Boolean");
    static System.Type DoubleType = System.Type.GetType("System.Double");
    static System.Type Int64Type  = System.Type.GetType("System.Int64");

    internal Type m_type;
    internal Method m_getter;
    internal Method m_setter;
    internal FieldInfo m_reflect;

  }
}
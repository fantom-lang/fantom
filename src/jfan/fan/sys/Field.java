//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//
package fan.sys;

import fanx.fcode.*;

/**
 * Field is a slot which "stores" a value.
 */
public class Field
  extends Slot
{

//////////////////////////////////////////////////////////////////////////
// Fan Constructor
//////////////////////////////////////////////////////////////////////////

  public static Field make(String name, Type of) { return make(name, of, null); }
  public static Field make(String name, Type of, Map facets)
  {
    Field f = new Field();
    make$(f, name, of, facets);
    return f;
  }

  public static void make$(Field self, String name, Type of) { make$(self, name, of, null); }
  public static void make$(Field self, String name, Type of, Map facets)
  {
    if (name == null) throw NullErr.make("name is null").val;
    if (of == null) throw NullErr.make("of is null").val;

    self.flags  = FConst.Public;
    self.name   = name;
    self.qname  = name;
    self.of     = of;
    self.facets = Facets.make(facets);
  }

//////////////////////////////////////////////////////////////////////////
// Java Constructor
//////////////////////////////////////////////////////////////////////////

  public Field(Type parent, String name, int flags, Facets facets, int lineNum, Type of)
  {
    super(parent, name, flags, facets, lineNum);
    this.of = of;
  }

  // ctor for make()
  public Field() {}

//////////////////////////////////////////////////////////////////////////
// Signature
//////////////////////////////////////////////////////////////////////////

  public Type type()  { return Sys.FieldType;  }

  public Type of() { return of; }

  public String signature() { return of.toStr() + " " + name; }

  public Object trap(String name, List args)
  {
    // private undocumented access
    if (name.equals("getter")) return getter;
    if (name.equals("setter")) return setter;
    return super.trap(name, args);
  }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  public Object get() { return get(null); }
  public Object get(Object instance)
  {
    parent.finish();

    if (getter != null)
    {
      return getter.invoke(instance, Method.noArgs);
    }

    try
    {
      return reflect.get(instance);
    }
    catch (Exception e)
    {
      if (parent != null && parent.dynamic)
        throw Err.make("Dynamic field must override get()").val;

      if (reflect == null)
        throw Err.make("Field not mapped to java.lang.reflect correctly").val;

      throw Err.make(e).val;
    }
  }

  public void set(Object instance, Object value)
  {
    set(instance, value, true);
  }

  public void set(Object instance, Object value, boolean checkConst)
  {
    parent.finish();

    // check const
    if ((flags & FConst.Const) != 0)
    {
      if (checkConst)
        throw ReadonlyErr.make("Cannot set const field " + qname()).val;
      else if (value != null && !isImmutable(value))
        throw ReadonlyErr.make("Cannot set const field " + qname() + " with mutable value").val;
    }

    // check static
    if ((flags & FConst.Static) != 0)
      throw ReadonlyErr.make("Cannot set static field " + qname()).val;

    // check generic type (the Java runtime will check non-generics)
    if (of.isGenericInstance() && value != null)
    {
      if (!of.is(type(value)))
        throw ArgErr.make("Wrong type for field " + qname() + ": " + of + " != " + type(value)).val;
    }

    if (setter != null)
    {
      setter.invoke(instance, new Object[] { value });
      return;
    }

    try
    {
      reflect.set(instance, value);
    }
    catch (IllegalArgumentException e)
    {
      throw ArgErr.make(e).val;
    }
    catch (Exception e)
    {
      if (parent != null && parent.dynamic)
        throw Err.make("Dynamic field must override set()").val;

      if (reflect == null)
        throw Err.make("Field not mapped to java.lang.reflect correctly").val;

      throw Err.make(e).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Type of;
  Method getter;
  Method setter;
  java.lang.reflect.Field reflect;

}

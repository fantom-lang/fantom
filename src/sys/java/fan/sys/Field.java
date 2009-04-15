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
// Java Constructor
//////////////////////////////////////////////////////////////////////////

  public Field(Type parent, String name, int flags, Facets facets, int lineNum, Type of)
  {
    super(parent, name, flags, facets, lineNum);
    this.of = of;
  }

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
      // if JavaType handle slot resolution
      if (parent.isJava()) return JavaType.get(this, instance);

      return reflect.get(instance);
    }
    catch (Exception e)
    {
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
    if ((flags & FConst.Static) != 0 && !parent.isJava())
      throw ReadonlyErr.make("Cannot set static field " + qname()).val;

    // check generic type (the Java runtime will check non-generics)
    if (of.isGenericInstance() && value != null)
    {
      if (!type(value).is(of.toNonNullable()))
        throw ArgErr.make("Wrong type for field " + qname() + ": " + of + " != " + type(value)).val;
    }

    if (setter != null)
    {
      setter.invoke(instance, new Object[] { value });
      return;
    }

    try
    {
      // if JavaType handle slot resolution
      if (parent.isJava()) { JavaType.set(this, instance, value); return; }

      reflect.set(instance, value);
    }
    catch (IllegalArgumentException e)
    {
      throw ArgErr.make(e).val;
    }
    catch (Exception e)
    {
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
  Method overload;   // if overloaded by method in JavaType

}
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//
package fan.sys;

import java.util.Iterator;
import java.util.Map.Entry;
import fanx.fcode.*;

/**
 * Field is a slot which "stores" a value.
 */
public class Field
  extends Slot
{

//////////////////////////////////////////////////////////////////////////
// Factories
//////////////////////////////////////////////////////////////////////////

  public static Func makeSetFunc(final Map map)
  {
    return new Func.Indirect1()
    {
      public Object call(Object obj)
      {
        Iterator it = map.pairsIterator();
        while (it.hasNext())
        {
          Entry entry = (Entry)it.next();
          Field field = (Field)entry.getKey();
          Object val = entry.getValue();
          field.set(obj, val, obj != inCtor);
        }
        return null;
      }
    };
  }

//////////////////////////////////////////////////////////////////////////
// Java Constructor
//////////////////////////////////////////////////////////////////////////

  public Field(Type parent, String name, int flags, Facets facets, int lineNum, Type type)
  {
    super(parent, name, flags, facets, lineNum);
    this.type = type;
  }

//////////////////////////////////////////////////////////////////////////
// Signature
//////////////////////////////////////////////////////////////////////////

  public Type typeof()  { return Sys.FieldType;  }

  public Type type() { return type; }

  public String signature() { return type.toStr() + " " + name; }

  public Object trap(String name, List args)
  {
    // private undocumented access
    if (name.equals("setConst")) { set(args.get(0), args.get(1), false); return null; }
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
        throw Err.make("Field not mapped to java.lang.reflect correctly " + qname());

      throw Err.make(e);
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
        throw ReadonlyErr.make("Cannot set const field " + qname());
      else if (value != null && !isImmutable(value))
        throw ReadonlyErr.make("Cannot set const field " + qname() + " with mutable value");
    }

    // check static
    if ((flags & FConst.Static) != 0 && !parent.isJava())
      throw ReadonlyErr.make("Cannot set static field " + qname());

    // check generic type (the Java runtime will check non-generics)
    if (type.isGenericInstance() && value != null)
    {
      if (!typeof(value).is(type.toNonNullable()))
        throw ArgErr.make("Wrong type for field " + qname() + ": " + type + " != " + typeof(value));
    }

    // use the setter by default, however if we have a storage field and
    // the setter was auto-generated then falldown to set the actual field
    // to avoid private setter implicit overrides
    if ((setter != null && !setter.isSynthetic()) || reflect == null)
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
      throw ArgErr.make(e);
    }
    catch (Exception e)
    {
      if (reflect == null)
        throw Err.make("Field not mapped to java.lang.reflect correctly");

      throw Err.make(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Type type;
  Method getter;
  Method setter;
  java.lang.reflect.Field reflect;
  Method overload;   // if overloaded by method in JavaType

}
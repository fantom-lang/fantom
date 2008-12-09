//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Nov 08  Brian Frank  Creation
//
package fan.sys;

import java.util.HashMap;
import java.lang.reflect.Modifier;
import fanx.fcode.*;
import fanx.util.*;

/**
 * JavaType wraps a Java class as a Fan type for FFI reflection.
 */
public class JavaType
  extends Type
{

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  /**
   * Make for a given Java class.  This is only used to map FFI Java types.
   * See FanUtil.toFanType for mapping any class to a sys::Type.
   */
  public static Type make(Class cls)
  {
    // at this point we shouldn't have any native fan type
    String clsName = cls.getName();
    if (clsName.startsWith("fan.")) throw new IllegalStateException(clsName);

    // cache all the java types statically
    synchronized (cache)
    {
      // if cached use that one
      JavaType t = (JavaType)cache.get(clsName);
      if (t != null) return t;

      // create a new one
      t = new JavaType(cls);
      cache.put(clsName, t);
      return t;
    }
  }

  /**
   * Make for a given FFI qname.  We want to keep this as light weight
   * as possible since it is used to stub all the FFI references at
   * pod load time.
   */
  public static JavaType make(String podName, String typeName)
  {
    // we shouldn't be using this method for pure Fan types
    if (!podName.startsWith("[java]")) throw new IllegalStateException(podName);

    // cache all the java types statically
    synchronized (cache)
    {
      // if cached use that one
      String clsName =  toClassName(podName, typeName);
      JavaType t = (JavaType)cache.get(clsName);
      if (t != null) return t;

      // create a new one
      t = new JavaType(podName, typeName);
      cache.put(clsName, t);
      return t;
    }
  }

  private JavaType(String podName, String typeName)
  {
    this.podName = podName;
    this.typeName = typeName;
    this.cls = null;
  }

  private JavaType(Class cls)
  {
    this.podName = "[java]" + cls.getPackage().getName();
    this.typeName = cls.getSimpleName();
    this.cls = cls;
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public Pod pod() { return null; }
  public String name() { return typeName; }
  public String qname() { return podName + "::" + typeName; }
  public String signature() { return qname(); }
  int flags() { return init().flags; }

  public Type base() { return init().base; }
  public List mixins() { return init().mixins; }
  public List inheritance() { return init().inheritance; }
  public boolean is(Type type)
  {
    type = type.toNonNullable();
    if (type == Sys.ObjType) return true;
    return type.toClass().isAssignableFrom(toClass());
  }

  public boolean isValue() { return false; }

  public final boolean isNullable() { return false; }
  public final synchronized Type toNullable()
  {
    if (nullable == null) nullable = new NullableType(this);
    return nullable;
  }

  public List fields() { throw unsupported(); }
  public List methods() { throw unsupported(); }
  public List slots() { throw unsupported(); }
  public Slot slot(String name, boolean checked) { throw unsupported(); }

  public Map facets(boolean inherited) { return Facets.empty().map(); }
  public Object facet(String name, Object def, boolean inherited) { return Facets.empty().get(name, def); }

  public String doc() { return null; }

  public boolean javaRepr() { return true; }

  private RuntimeException unsupported() { return new UnsupportedOperationException(); }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  /**
   * Map a Fan qname to a Java classname:
   *  [java]java.util::Date -> java.util.Date
   */
  static String toClassName(String podName, String typeName)
  {
    return podName.substring(6) + "." + typeName;
  }

  /**
   * Get the Java class which represents this type.  This is
   * either set in constructor by factor or lazily mapped.
   */
  public Class toClass()
  {
    try
    {
      if (cls == null)
        cls = Class.forName(toClassName(podName, typeName));
      return cls;
    }
    catch (Exception e)
    {
      throw new RuntimeException("Cannot map Fan type to Java class: " + qname());
    }
  }

  /**
   * Init is responsible for lazily initialization
   */
  private JavaType init()
  {
    if (flags != -1) return this;
    try
    {
      // find Java class
      Class cls = toClass();

      // flags
      flags = javaModifiersToFanFlags(cls.getModifiers());

      // superclass is base class
      Class superclass = cls.getSuperclass();
      if (superclass != null) base = FanUtil.toFanType(superclass, true, true);
      else base = Sys.ObjType;

      // interfaces are mixins
      Class[] interfaces = cls.getInterfaces();
      mixins = new List(Sys.TypeType, interfaces.length);
      for (int i=0; i<interfaces.length; ++i)
        mixins.add(FanUtil.toFanType(interfaces[i], true, true));
      mixins = mixins.ro();

      // inheritance
      inheritance = ClassType.inheritance(this);
    }
    catch (Exception e)
    {
      System.out.println("ERROR: JavaType.init: " + this);
      e.printStackTrace();
    }
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  /**
   * Map Java modifiers to Fan flags.
   */
  public static int javaModifiersToFanFlags(int m)
  {
    int flags = 0;

    if (Modifier.isAbstract(m))  flags |= FConst.Abstract;
    if (Modifier.isFinal(m))     flags |= FConst.Final;
    if (Modifier.isInterface(m)) flags |= FConst.Mixin;
    if (Modifier.isStatic(m))    flags |= FConst.Static;

    if (Modifier.isPublic(m))   flags |= FConst.Public;
    else if (Modifier.isPrivate(m))  flags |= FConst.Private;
    else if (Modifier.isProtected(m))  flags |= FConst.Protected;
    else flags |= FConst.Internal;

    return flags;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static final HashMap cache = new HashMap(); // String -> JavaType

  private String podName;     // ctor
  private String typeName;    // ctor
  private Type nullable;      // toNullable()
  private Class cls;          // init()
  private int flags = -1;     // init()
  private Type base;          // init()
  private List mixins;        // init()
  private List inheritance;   // init()

}
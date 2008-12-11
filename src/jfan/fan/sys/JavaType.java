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
  public static JavaType make(Class cls)
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
    if (cls.getPackage() == null)
      this.podName = "[java]";
    else
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

  public List fields() { return initSlots().fields; }
  public List methods() { return initSlots().methods; }
  public List slots() { return initSlots().slots; }
  public Slot slot(String name, boolean checked)
  {
    Slot slot = (Slot)initSlots().slotsByName.get(name);
    if (slot != null) return slot;
    if (checked) throw UnknownSlotErr.make(qname() + "." + name).val;
    return null;
  }

  public Map facets(boolean inherited) { return Facets.empty().map(); }
  public Object facet(String name, Object def, boolean inherited) { return Facets.empty().get(name, def); }

  public String doc() { return null; }

  public boolean javaRepr() { return true; }

  private RuntimeException unsupported() { return new UnsupportedOperationException(); }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

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
      throw UnknownTypeErr.make("Cannot map Fan type to Java class: " + qname(), e).val;
    }
  }

  /**
   * Init is responsible for lazily initialization of type
   * level information: flags, base, mixins, and iinheritance.
   */
  private JavaType init()
  {
    if (flags != -1) return this;
    try
    {
      // find Java class
      Class cls = toClass();

      // flags
      flags = classModifiersToFanFlags(cls.getModifiers());

      // superclass is base class
      Class superclass = cls.getSuperclass();
      if (superclass != null) base = toFanType(superclass);
      else base = Sys.ObjType;

      // interfaces are mixins
      Class[] interfaces = cls.getInterfaces();
      mixins = new List(Sys.TypeType, interfaces.length);
      for (int i=0; i<interfaces.length; ++i)
        mixins.add(toFanType(interfaces[i]));
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

  /**
   * Reflect the Java class to map is members to Fan slots.
   */
  private synchronized JavaType initSlots()
  {
    // if already initialized short circuit
    if (slots != null) return this;

    // reflect Java members
    java.lang.reflect.Field[] jfields = toClass().getFields();
    java.lang.reflect.Method[] jmethods = toClass().getMethods();

    // allocate Fan reflection structurs
    List slots = new List(Sys.SlotType, jfields.length+jmethods.length+4);
    List fields = new List(Sys.FieldType, jfields.length);
    List methods = new List(Sys.MethodType, jfields.length+4);
    HashMap slotsByName = new HashMap();

    // map the fields
    for (int i=0; i<jfields.length; ++i)
    {
      Field f = toFan(jfields[i]);
      slots.add(f);
      fields.add(f);
      slotsByName.put(f.name(), f);
    }

    // map the methods
    for (int i=0; i<jmethods.length; ++i)
    {
      Method m = toFan(jmethods[i]);

      // TODO: for now ignore overloads
      if (slotsByName.get(m.name()) != null) continue;

      slots.add(m);
      methods.add(m);
      slotsByName.put(m.name(), m);
    }

    // finish
    this.slots = slots.ro();
    this.fields = fields.ro();
    this.methods = methods.ro();
    this.slotsByName = slotsByName;
    return this;
  }

  private Field toFan(java.lang.reflect.Field java)
  {
    Type parent   = toFanType(java.getDeclaringClass());
    String name   = java.getName();
    int flags     = memberModifiersToFanFlags(java.getModifiers());
    Facets facets = Facets.empty();
    Type of       = toFanType(java.getType());

    Field fan = new Field(parent, name, flags, facets, -1, of);
    fan.reflect = java;
    return fan;
  }

  private Method toFan(java.lang.reflect.Method java)
  {
    Type parent   = toFanType(java.getDeclaringClass());
    String name   = java.getName();
    int flags     = memberModifiersToFanFlags(java.getModifiers());
    Facets facets = Facets.empty();
    Type ret      = toFanType(java.getReturnType());

    Class[] paramClasses = java.getParameterTypes();
    List params = new List(Sys.ParamType, paramClasses.length);
    for (int i=0; i<paramClasses.length; ++i)
    {
      Param param = new Param("p"+i, toFanType(java.getDeclaringClass()), 0);
      params.add(param);
    }

    Method fan = new Method(parent, name, flags, facets, -1, ret, ret, params.ro());
    fan.reflect = new java.lang.reflect.Method[] { java };
    return fan;
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  /**
   * Map a Fan qname to a Java classname:
   *  [java]java.util::Date -> java.util.Date
   */
  static String toClassName(String podName, String typeName)
  {
    if (podName.length() == 6) return typeName;
    return podName.substring(6) + "." + typeName;
  }

  /**
   * Map Java class to Fan type.
   */
  public static Type toFanType(Class cls)
  {
    return FanUtil.toFanType(cls, true);
  }

  /**
   * Map Java class modifiers to Fan flags.
   */
  public static int classModifiersToFanFlags(int m)
  {
    int flags = 0;

    if (Modifier.isAbstract(m))  flags |= FConst.Abstract;
    if (Modifier.isFinal(m))     flags |= FConst.Final;
    if (Modifier.isInterface(m)) flags |= FConst.Mixin;

    if (Modifier.isPublic(m))   flags |= FConst.Public;
    else flags |= FConst.Internal;

    return flags;
  }

  /**
   * Map Java field/method modifiers to Fan flags.
   */
  public static int memberModifiersToFanFlags(int m)
  {
    int flags = 0;

    if (Modifier.isAbstract(m))  flags |= FConst.Abstract;
    if (Modifier.isStatic(m))    flags |= FConst.Static;

    if (Modifier.isFinal(m)) flags |= FConst.Final;
    else flags |= FConst.Virtual;

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

  public static final JavaType ByteType  = make(byte.class);
  public static final JavaType ShortType = make(short.class);
  public static final JavaType CharType  = make(char.class);
  public static final JavaType IntType   = make(int.class);
  public static final JavaType FloatType = make(float.class);

  private String podName;      // ctor
  private String typeName;     // ctor
  private Type nullable;       // toNullable()
  private Class cls;           // init()
  private int flags = -1;      // init()
  private Type base;           // init()
  private List mixins;         // init()
  private List inheritance;    // init()
  private List fields;         // initSlots()
  private List methods;        // initSlots()
  private List slots;          // initSlots()
  private HashMap slotsByName; // initSlots() - String:Slot

}
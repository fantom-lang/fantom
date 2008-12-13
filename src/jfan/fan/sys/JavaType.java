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
  public Method method(String name, boolean checked)
  {
    // check if slot is overloaded by both field and method
    Slot slot = slot(name, checked);
    if (slot instanceof Field)
    {
      Field f = (Field)slot;
      if (f.overload != null) return f.overload;
    }
    return (Method)slot;
  }

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

  public boolean javaRepr() { return false; }

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
      // check if we already have a slot by this name
      java.lang.reflect.Method j = jmethods[i];
      Slot existing = (Slot)slotsByName.get(j.getName());

      // if this method overloads a field
      if (existing instanceof Field)
      {
        // if this is the first method overload over
        // the field then create a link via Field.overload
        Field x = (Field)existing;
        if (x.overload == null)
        {
          Method m = toFan(j);
          x.overload = m;
          methods.add(m);
          continue;
        }

        // otherwise set existing to first method and fall-thru to next check
        existing = x.overload;
      }

      // if this method overloads another method then all
      // we do is add this version to our Method.reflect
      if (existing instanceof Method)
      {
        Method x = (Method)existing;
        java.lang.reflect.Method [] temp = new java.lang.reflect.Method[x.reflect.length+1];
        System.arraycopy(x.reflect, 0, temp, 0, x.reflect.length);
        temp[x.reflect.length] = j;
        x.reflect = temp;
        continue;
      }

      // if we've made it here this method does not overload
      // either a field or method, so we can simply map it
      Method m = toFan(j);
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

  /**
   * Map a Java Field to a Fan field.
   */
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

  /**
   * Map a Java Method to a Fan Method.
   */
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
// Dynamic Resolution and Invocation
//////////////////////////////////////////////////////////////////////////

  /**
   * Create the object using its default constructor.
   */
  public Object make(List args)
  {
    // right now we don't support constructors with arguments
    if (args != null && args.sz() > 0)
      throw UnsupportedErr.make("Cannot call make with args on Java type: " + this).val;

    // route to Class.newInstance
    try { return toClass().newInstance(); }
    catch (Exception e) { throw Err.make(e).val; }
  }

  /**
   * Trap for Field.get against Java type.
   */
  static Object get(Field f, Object instance)
    throws Exception
  {
    java.lang.reflect.Field j = f.reflect;
    Class t = j.getType();
    if (t.isPrimitive())
    {
      if (t == int.class)   return Long.valueOf(j.getLong(instance));
      if (t == byte.class)  return Long.valueOf(j.getLong(instance));
      if (t == short.class) return Long.valueOf(j.getLong(instance));
      if (t == char.class)  return Long.valueOf(j.getLong(instance));
      if (t == float.class) return Double.valueOf(j.getDouble(instance));
    }
    return coerceFromJava(j.get(instance));
  }

  /**
   * Trap for Field.set against Java type.
   */
  static void set(Field f, Object instance, Object val)
    throws Exception
  {
    java.lang.reflect.Field j = f.reflect;
    Class t = j.getType();
    if (t.isPrimitive())
    {
      if (t == int.class)   { j.setInt(instance,   ((Number)val).intValue()); return; }
      if (t == byte.class)  { j.setByte(instance,  ((Number)val).byteValue()); return; }
      if (t == short.class) { j.setShort(instance, ((Number)val).shortValue()); return; }
      if (t == char.class)  { j.setChar(instance,  (char)((Number)val).intValue()); return; }
      if (t == float.class) { j.setFloat(instance, ((Number)val).floatValue()); return; }
    }
    j.set(instance, coerceToJava(val, t));
  }

  /**
   * Trap for Method.invoke against Java type.
   */
  static Object invoke(Method m, Object instance, Object[] args)
    throws Exception
  {
    // resolve the method to use with given arguments
    java.lang.reflect.Method j = resolve(m, args);

    // coerce the arguments
    Class[] params = j.getParameterTypes();
    for (int i=0; i<args.length; ++i)
      args[i] = coerceToJava(args[i], params[i]);

    // invoke the method via reflection and coerce result back to Fan
    return coerceFromJava(j.invoke(instance, args));
  }

  /**
   * Given a set of arguments try to resolve the best method to
   * use for reflection.  The overloaded methods are stored in the
   * Method.reflect array.
   */
  static java.lang.reflect.Method resolve(Method m, Object[] args)
  {
    // if only one method then this is easy; defer argument
    // checking until we actually try to invoke it
    java.lang.reflect.Method[] reflect = m.reflect;
    if (reflect.length == 1) return reflect[0];

    // find best match
    java.lang.reflect.Method best = null;
    for (int i=0; i<reflect.length; ++i)
    {
      java.lang.reflect.Method x = reflect[i];
      Class[] params = x.getParameterTypes();
      if (!argsMatchParams(args, params)) continue;
      if (best == null) { best = x; continue; }
      throw ArgErr.make("Ambiguous method call '" + m.name + "'").val;
    }
    if (best != null) return best;

    // no matches
    throw ArgErr.make("No matching method '" + m.name + "' for arguments").val;
  }

  /**
   * Return if given arguments can be used against the specified
   * parameter types.  We have to take into account that we might
   * coercing the arguments from their Fan represention to Java.
   */
  static boolean argsMatchParams(Object[] args, Class[] params)
  {
    if (args.length != params.length) return false;
    for (int i=0; i<args.length; ++i)
      if (!argMatchesParam(args[i], params[i])) return false;
    return true;
  }

  /**
   * Return if given argument can be used against the specified
   * parameter type.  We have to take into account that we might
   * coercing the arguments from their Fan represention to Java.
   */
  static boolean argMatchesParam(Object arg, Class param)
  {
    // do simple instance of check
    if (param.isInstance(arg)) return true;

    // check implicit primitive coercions
    if (param.isPrimitive())
    {
      // its either boolean, char/numeric
      if (param == boolean.class) return arg instanceof Boolean;
      return arg instanceof Number;
    }

    // check implicit array coercions
    if (param.isArray())
    {
      Class ct = param.getComponentType();
      if (ct.isPrimitive()) return false;
      return arg instanceof List;
    }

    // no coersion to match
    return false;
  }

  /**
   * Coerce the specified Fan representation to the Java class.
   */
  static Object coerceToJava(Object val, Class expected)
  {
    if (expected == int.class)   return Integer.valueOf(((Number)val).intValue());
    if (expected == byte.class)  return Byte.valueOf(((Number)val).byteValue());
    if (expected == short.class) return Short.valueOf(((Number)val).shortValue());
    if (expected == char.class)  return Character.valueOf((char)((Number)val).intValue());
    if (expected == float.class) return Float.valueOf(((Number)val).floatValue());
    if (expected.isArray())
    {
      Class ct = expected.getComponentType();
      if (val instanceof List) return ((List)val).toArray(ct);
    }
    return val;
  }

  /**
   * Coerce a Java object to its Fan representation.
   */
  static Object coerceFromJava(Object val)
  {
    if (val == null) return null;
    Class t = val.getClass();
    if (t == Integer.class)   return Long.valueOf(((Integer)val).longValue());
    if (t == Byte.class)      return Long.valueOf(((Byte)val).longValue());
    if (t == Short.class)     return Long.valueOf(((Short)val).longValue());
    if (t == Character.class) return Long.valueOf(((Character)val).charValue());
    if (t == Float.class)     return Double.valueOf(((Float)val).doubleValue());
    if (t.isArray())
    {
      Class ct = t.getComponentType();
      if (ct.isPrimitive()) return val;
      return new List(FanUtil.toFanType(ct, true), (Object[])val);
    }
    return val;
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
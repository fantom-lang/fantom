//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Nov 08  Brian Frank  Creation
//

package fan.compilerJava;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import fan.sys.*;
import fanx.fcode.*;

/**
 * JavaTypePeer
 */
class JavaTypePeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static JavaTypePeer make(JavaType t)
  {
    return new JavaTypePeer();
  }

//////////////////////////////////////////////////////////////////////////
// Natives
//////////////////////////////////////////////////////////////////////////

  public void doLoad(JavaType self, Map slots)
    throws Exception
  {
    // map to Java class
    Class cls = toJavaClass(self);

    // map Java modifiers to Fan flags
    self.flags = toFanFlags(cls.getModifiers());

    // map Java fields to CSlots
    Field[] fields = cls.getFields();
    for (int i=0; i<fields.length; ++i)
      mapField(self, slots, fields[i]);

    // map Java methods to CSlots
    Method[] methods = cls.getMethods();
    for (int i=0; i<methods.length; ++i)
      mapMethod(self, slots, methods[i]);

    // map Java constructors to CSlots
    Constructor[] ctors = cls.getConstructors();
    for (int i=0; i<ctors.length; ++i)
      mapCtor(self, slots, ctors[i]);
  }

//////////////////////////////////////////////////////////////////////////
// Field
//////////////////////////////////////////////////////////////////////////

  void mapField(JavaType self, Map slots, Field java)
    throws Exception
  {
    String name = java.getName();
    JavaField fan = JavaField.make();
    fan.setParent(self);
    fan.setName(name);
    fan.setFlags(toFanFlags(java.getModifiers()));
    fan.setFieldType(toFanType(java.getType()));
    slots.add(name, fan);
  }

  void mapMethod(JavaType self, Map slots, Method java)
    throws Exception
  {
    String name = java.getName();
    JavaMethod fan = JavaMethod.make();
    fan.setParent(self);
    fan.setName(name);
    fan.setFlags(toFanFlags(java.getModifiers()));
    fan.setReturnTypeSig(toFanType(java.getReturnType()));
    fan.setParamTypes(toFanTypes(java.getParameterTypes()));
    addSlot(slots, name, fan);
  }

  void mapCtor(JavaType self, Map slots, Constructor java)
    throws Exception
  {
    String name = java.getName();
    JavaMethod fan = JavaMethod.make();
    fan.setParent(self);
    fan.setName("<init>");
    fan.setFlags(toFanFlags(java.getModifiers())|FConst.Ctor);
    fan.setReturnType(self);
    fan.setParamTypes(toFanTypes(java.getParameterTypes()));
    addSlot(slots, "<init>", fan);
  }

  void addSlot(Map slots, String name, JavaMethod m)
  {
    // put the first one into the slot, and add
    // the overloads as linked list on that
    JavaSlot x = (JavaSlot)slots.get(name);
    if (x == null) { slots.add(name, m); return; }

    // work around for javac (can't access compiler types)
    if (x instanceof JavaMethod)
    {
      m.setNext(((JavaMethod)x).getNext());
      ((JavaMethod)x).setNext(m);
    }
    else
    {
      m.setNext(((JavaField)x).getNext());
      ((JavaField)x).setNext(m);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  static Class toJavaClass(JavaType t)
    throws Exception
  {
    StringBuilder s = new StringBuilder();
    if (t.isArray())
    {
      int rank = (int)t.arrayRank;
      for (int i=0; i<rank; ++i) s.append('[');
      s.append('L');
      s.append(t.pod.packageName).append('.');
      s.append(t.name, rank, t.name.length()-rank+1);
      s.append(';');
    }
    else
    {
      s.append(t.pod.packageName).append('.').append(t.name);
    }
    return Class.forName(s.toString());
  }

  static List toFanTypes(Class[] cls)
    throws Exception
  {
    List list = new List(Sys.StrType, cls.length);
    for (int i=0; i<cls.length; ++i)
      list.add(toFanType(cls[i]));
    return list;
  }

  static String toFanType(Class cls)
    throws Exception
  {
    return toFanType(cls, false);
  }

  static String toFanType(Class cls, boolean multiDim)
    throws Exception
  {
    // primitives
    if (cls.isPrimitive())
    {
      if (cls == java.lang.Void.TYPE)      return multiDim ? "[java]::void"    : "sys::Void";
      if (cls == java.lang.Boolean.TYPE)   return multiDim ? "[java]::boolean" : "sys::Bool";
      if (cls == java.lang.Long.TYPE)      return multiDim ? "[java]::long"    : "sys::Int";
      if (cls == java.lang.Double.TYPE)    return multiDim ? "[java]::double"  : "sys::Float";
      if (cls == java.lang.Integer.TYPE)   return "[java]::int";
      if (cls == java.lang.Byte.TYPE)      return "[java]::byte";
      if (cls == java.lang.Short.TYPE)     return "[java]::short";
      if (cls == java.lang.Character.TYPE) return "[java]::char";
      if (cls == java.lang.Float.TYPE)     return "[java]::float";
      throw new IllegalStateException(cls.toString());
    }

    // arrays [java]foo.bar::[Baz
    if (cls.isArray())
    {
      Class compCls = cls.getComponentType();

      // if a primary array
      if (compCls.isPrimitive() && !multiDim)
      {
        if (cls == boolean[].class) return "[java]fanx.interop::BooleanArray";
        if (cls == byte[].class)    return "[java]fanx.interop::ByteArray";
        if (cls == short[].class)   return "[java]fanx.interop::ShortArray";
        if (cls == char[].class)    return "[java]fanx.interop::CharArray";
        if (cls == int[].class)     return "[java]fanx.interop::IntArray";
        if (cls == long[].class)    return "[java]fanx.interop::LongArray";
        if (cls == float[].class)   return "[java]fanx.interop::FloatArray";
        if (cls == double[].class)  return "[java]fanx.interop::DoubleArray";
        throw new IllegalStateException(cls.getName());
      }

      // return "[java] foo.bar::[Baz"
      String comp = toFanType(compCls, true);
      int colon = comp.lastIndexOf(':');
      return comp.substring(0, colon+1) + "[" + comp.substring(colon+1);
    }

    // any Java use of String is considered potential nullable
    if (cls.getName().equals("java.lang.String"))
      return multiDim ? "[java]java.lang::String" : "sys::Str?";

    // Java FFI
    return "[java]" + cls.getPackage().getName() + "::" + cls.getSimpleName();
  }

  static long toFanFlags(int m)
    throws Exception
  {
    long flags = 0;

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

}
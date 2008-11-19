//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Nov 08  Brian Frank  Creation
//

package fan.compilerJava;

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
    fan.setReturnType(toFanType(java.getReturnType()));
    fan.setParamTypes(toFanTypes(java.getParameterTypes()));

    // put the first one into the slot, and add
    // the overloads as linked list on that
    JavaSlot x = (JavaSlot)slots.get(name);
    if (x == null) slots.add(name, fan);
    else
    {
      // work around for javac (can't access compiler types)
      if (x instanceof JavaMethod)
      {
        fan.setNext(((JavaMethod)x).getNext());
        ((JavaMethod)x).setNext(fan);
      }
      else
      {
        fan.setNext(((JavaField)x).getNext());
        ((JavaField)x).setNext(fan);
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  static Class toJavaClass(JavaType t)
    throws Exception
  {
    return Class.forName(t.pod.packageName + "." + t.name);
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
    // primitives
    if (cls.isPrimitive())
    {
      if (cls == void.class)    return "sys::Void";
      if (cls == boolean.class) return "sys::Bool";
      if (cls == int.class)     return "sys::Int";
      if (cls == long.class)    return "sys::Int";
      if (cls == byte.class)    return "sys::Int";
      if (cls == short.class)   return "sys::Int";
      if (cls == float.class)   return "sys::Float";
      if (cls == double.class)  return "sys::Float";
      throw new IllegalStateException(cls.toString());
    }

    // Fan classes
    if (cls.getName().equals("java.lang.String")) return "sys::Str";

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
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Nov 08  Brian Frank  Creation
//   13 Dec 08  Brian Frank  Port from Java to Fan using FFI
//

using compiler
using [java] java.lang
using [java] java.lang.reflect::Constructor as JCtor
using [java] java.lang.reflect::Field as JField
using [java] java.lang.reflect::Method as JMethod
using [java] java.lang.reflect::Modifier as JModifier
using [java] java.util
using [java] fanx.util

/**
 * JavaReflect provides Java reflection utilities.
 ** It encapsulates the FFI calls out to Java.
 */
class JavaReflect
{
  **
  ** Map class meta-data and Java members to Fan slots
  ** for the specified JavaType
  **
  static Void load(JavaType self, Str:CSlot slots)
  {
    // map to Java class
    cls := toJavaClass(self)

    // map Java modifiers to Fan flags
    self.flags = toClassFlags(cls.getModifiers)

    // map Java fields to CSlots (public and protected)
    findFields(cls).each |JField j| { mapField(self, slots, j) }

    // map Java methods to CSlots (public and protected)
    findMethods(cls).each |JMethod j| { mapMethod(self, slots, j) }

    // map Java constructors to CSlots
    JCtor[] x := cls.getDeclaredConstructors // TODO
    x.each |JCtor j| { mapCtor(self, slots, j) }
  }

  **
  ** Reflect the public and protected fields which Java
  ** reflection makes very difficult.
  **
  static JField[] findFields(Class? cls)
  {
    acc := HashMap() // mutable keys

    // first add all the public fields
    JField[] x := cls.getFields  // TODO
    x.each |JField j| { acc.put(j, j) }

    // do protected fields working back up the hierarchy; don't
    // worry about interfaces b/c they can declare protected members
    while (cls != null)
    {
      x = cls.getDeclaredFields
      x.each |JField j|
      {
        if (!JModifier.isProtected(j.getModifiers)) return
        if (acc[j] == null) acc.put(j, j)
      }
      cls = cls.getSuperclass
    }

    list := JField[,]
    for (it := acc.values.iterator; it.hasNext; ) list.add(it.next)
    return list
  }

  **
  ** Reflect the public and protected methods which Java
  ** reflection makes very difficult.
  **
  static JMethod[] findMethods(Class? cls)
  {
    acc := HashMap() // mutable keys

    // first add all the public methods
    JMethod[] x := cls.getMethods // TODO
    x.each |JMethod j| { acc.put(j, j) }

    // do protected methods working back up the hierarchy; don't
    // worry about interfaces b/c they can declare protected members
    while (cls != null)
    {
      x = cls.getDeclaredMethods // TODO
      x.each |JMethod j|
      {
        if (!JModifier.isProtected(j.getModifiers)) return
        if (acc[j] == null) acc.put(j, j)
      }
      cls = cls.getSuperclass
    }

    list := JMethod[,]
    for (it := acc.values.iterator; it.hasNext; ) list.add(it.next)
    return list
  }

//////////////////////////////////////////////////////////////////////////
// Java Member -> Fan CSlot
//////////////////////////////////////////////////////////////////////////

  static Void mapField(JavaType self, Str:CSlot slots, JField java)
  {
    mods := java.getModifiers
    if (!JModifier.isPublic(mods) && !JModifier.isProtected(mods)) return

    name := java.getName
    fan := JavaField()
    fan.setParent(self) // TODO
    fan.setName(name)
    fan.setFlags(toMemberFlags(mods))
    fan.setFieldType(toFanType(java.getType))
    slots.add(name, fan)
  }

  static Void mapMethod(JavaType self, Str:CSlot slots, JMethod java)
  {
    mods := java.getModifiers
    if (!JModifier.isPublic(mods) && !JModifier.isProtected(mods)) return

    name := java.getName
    fan := JavaMethod()
    fan.setParent(self) // TODO
    fan.setName(name)
    fan.setFlags(toMemberFlags(mods))
    fan.setReturnTypeSig(toFanType(java.getReturnType))
    fan.setParamTypes(toFanTypes(java.getParameterTypes))
    addSlot(slots, name, fan)
  }

  static Void mapCtor(JavaType self, Str:CSlot slots, JCtor java)
  {
    mods := java.getModifiers
    if (!JModifier.isPublic(mods) && !JModifier.isProtected(mods)) return

    name := java.getName
    fan := JavaMethod()
    fan.setParent(self) // TODO
    fan.setName("<init>")
    fan.setFlags(toMemberFlags(mods)|FConst.Ctor)
    fan.setReturnType(self);
    fan.setParamTypes(toFanTypes(java.getParameterTypes))
    addSlot(slots, "<init>", fan)
  }

  static Void addSlot(Str:CSlot slots, Str name, JavaMethod m)
  {
    // put the first one into the slot, and add
    // the overloads as linked list on that
    JavaSlot? x := slots.get(name)
    if (x == null) { slots.add(name, m); return }

    // work around for javac (can't access compiler types)
    // TODO
    if (x is JavaMethod)
    {
      m.setNext(((JavaMethod)x).getNext())
      ((JavaMethod)x).setNext(m)
    }
    else
    {
      m.setNext(((JavaField)x).getNext())
      ((JavaField)x).setNext(m)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  static Class toJavaClass(JavaType t)
  {
    s := StrBuf()
    if (t.isArray)
    {
      rank := t.arrayRank
      rank.times |,| { s.addChar('[') }
      s.addChar('L')
      s.add(t.pod.packageName).addChar('.')
      s.add(t.name[rank .. -(rank+1)])
      s.addChar(';')
    }
    else
    {
      s.add(t.pod.packageName).addChar('.').add(t.name)
    }
    return Class.forName(s.toStr)
  }

  static Str[] toFanTypes(Class[] cls) // TODO - return type directly?
  {
    acc := Str[,]
    cls.each |Class c| { acc.add(toFanType(c)) }
    return acc
  }

  static Str toFanType(Class cls, Bool multiDim := false) // TODO - return type directly?
  {
    // primitives
    if (cls.isPrimitive)
    {
      switch (cls.getName)
      {
        case "void":    return multiDim ? "[java]::void"    : "sys::Void"
        case "boolean": return multiDim ? "[java]::boolean" : "sys::Bool"
        case "long":    return multiDim ? "[java]::long"    : "sys::Int"
        case "double":  return multiDim ? "[java]::double"  : "sys::Float"
        case "int":     return "[java]::int"
        case "byte":    return "[java]::byte"
        case "short":   return "[java]::short"
        case "char":    return "[java]::char"
        case "float":   return "[java]::float"
      }
      throw Err(cls.toStr)
    }

    // arrays [java]foo.bar::[Baz
    if (cls.isArray)
    {
      compCls := cls.getComponentType

      // if a primary array
      if (compCls.isPrimitive && !multiDim)
      {
        switch (cls.getName)
        {
          case "[Z": return "[java]fanx.interop::BooleanArray?"
          case "[B": return "[java]fanx.interop::ByteArray?"
          case "[S": return "[java]fanx.interop::ShortArray?"
          case "[C": return "[java]fanx.interop::CharArray?"
          case "[I": return "[java]fanx.interop::IntArray?"
          case "[J": return "[java]fanx.interop::LongArray?"
          case "[F": return "[java]fanx.interop::FloatArray?"
          case "[D": return "[java]fanx.interop::DoubleArray?"
        }
        throw Err(cls.getName)
      }

      // return "[java] foo.bar::[Baz"
      comp := toFanType(compCls, true)
      colon := comp.indexr(":")
      sig := comp[0..colon] + "[" + comp[colon+1..-1]
      if (!sig.endsWith("?")) sig += "?"
      return sig
    }

    // any Java use of Obj/Str is considered potential nullable
    if (cls.getName == "java.lang.Object")
      return multiDim ? "[java]java.lang::Object?" : "sys::Obj?"
    if (cls.getName == "java.lang.String")
      return multiDim ? "[java]java.lang::String?" : "sys::Str?"

    // Java FFI
    return "[java]" + cls.getPackage.getName + "::" + cls.getSimpleName + "?"
  }

  static Int toClassFlags(Int modifiers)
  {
    return FanUtil.classModifiersToFanFlags(modifiers)
  }

  static Int toMemberFlags(Int modifiers)
  {
    return FanUtil.memberModifiersToFanFlags(modifiers)
  }

}
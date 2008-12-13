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

**
** JavaReflect provides Java reflection utilities.
** It encapsulates the FFI calls out to Java.
**
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

    // map superclass
    if (cls.getSuperclass != null)
      self.base = toFanType(self.bridge, cls.getSuperclass)

    // map interfaces to mixins
    mixins := CType[,]
    cls.getInterfaces.each |Class c|
    {
      try
        mixins.add(toFanType(self.bridge, c))
      catch (UnknownTypeErr e)
        errUnknownType(e)
    }
    self.mixins = mixins

    // map Java modifiers to Fan flags
    self.flags = toClassFlags(cls.getModifiers)

    // map Java fields to CSlots (public and protected)
    findFields(cls).each |JField j| { mapField(self, slots, j) }

    // map Java methods to CSlots (public and protected)
    findMethods(cls).each |JMethod j| { mapMethod(self, slots, j) }

    // map Java constructors to CSlots
    cls.getDeclaredConstructors.each |JCtor j| { mapCtor(self, slots, j) }
  }

  **
  ** Reflect the public and protected fields which Java
  ** reflection makes very difficult.
  **
  static JField[] findFields(Class? cls)
  {
    acc := HashMap() // mutable keys

    // first add all the public fields
    cls.getFields.each |JField j| { acc.put(j, j) }

    // do protected fields working back up the hierarchy; don't
    // worry about interfaces b/c they can declare protected members
    while (cls != null)
    {
      cls.getDeclaredFields.each |JField j|
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
    cls.getMethods.each |JMethod j| { acc.put(j, j) }

    // do protected methods working back up the hierarchy; don't
    // worry about interfaces b/c they can declare protected members
    while (cls != null)
    {
      cls.getDeclaredMethods.each |JMethod j|
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
    try
    {
      fan := JavaField()
      fan.parent = self
      fan.name = java.getName
      fan.flags = toMemberFlags(mods)
      fan.fieldType = toFanType(self.bridge, java.getType)
      slots.set(fan.name, fan)
    }
    catch (UnknownTypeErr e) errUnknownType(e)
  }

  static Void mapMethod(JavaType self, Str:CSlot slots, JMethod java)
  {
    mods := java.getModifiers
    if (!JModifier.isPublic(mods) && !JModifier.isProtected(mods)) return
    try
    {
      fan := JavaMethod()
      fan.parent = self
      fan.name = java.getName
      fan.flags = toMemberFlags(mods)
      fan.returnType = toFanType(self.bridge, java.getReturnType)
      fan.setParamTypes(toFanTypes(self.bridge, java.getParameterTypes))
      addSlot(slots, fan.name, fan)
    }
    catch (UnknownTypeErr  e) errUnknownType(e)
  }

  static Void mapCtor(JavaType self, Str:CSlot slots, JCtor java)
  {
    mods := java.getModifiers
    if (!JModifier.isPublic(mods) && !JModifier.isProtected(mods)) return
    try
    {
      fan := JavaMethod()
      fan.parent = self
      fan.name = "<init>"
      fan.flags = toMemberFlags(mods) | FConst.Ctor
      fan.returnType = self
      fan.setParamTypes(toFanTypes(self.bridge, java.getParameterTypes))
      addSlot(slots, fan.name, fan)
    }
    catch (UnknownTypeErr  e) errUnknownType(e)
  }

  static Void addSlot(Str:CSlot slots, Str name, JavaMethod m)
  {
    // put the first one into the slot, and add
    // the overloads as linked list on that
    JavaSlot? x := slots.get(name)
    if (x == null) { slots.add(name, m); return }

    // create linked list of overloads
    m.next = x.next
    x.next = m
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
      s.add(t.name[rank .. -rank])
      s.addChar(';')
    }
    else
    {
      s.add(t.pod.packageName).addChar('.').add(t.name)
    }
    return Class.forName(s.toStr)
  }

  static CType[] toFanTypes(JavaBridge bridge, Class[] cls)
  {
    return cls.map(CType[,]) |Class c->CType| { return toFanType(bridge, c) }
  }

  static CType toFanType(JavaBridge bridge, Class cls, Bool multiDim := false)
  {
    ns := bridge.ns
    primitives := bridge.primitives

    // primitives
    if (cls.isPrimitive)
    {
      switch (cls.getName)
      {
        case "void":    return ns.voidType
        case "boolean": return multiDim ? primitives.booleanType : ns.boolType
        case "long":    return multiDim ? primitives.longType    : ns.intType
        case "double":  return multiDim ? primitives.doubleType  : ns.floatType
        case "int":     return primitives.intType
        case "byte":    return primitives.byteType
        case "short":   return primitives.shortType
        case "char":    return primitives.charType
        case "float":   return primitives.floatType
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
          case "[Z": return ns.resolveType("[java]fanx.interop::BooleanArray?")
          case "[B": return ns.resolveType("[java]fanx.interop::ByteArray?")
          case "[S": return ns.resolveType("[java]fanx.interop::ShortArray?")
          case "[C": return ns.resolveType("[java]fanx.interop::CharArray?")
          case "[I": return ns.resolveType("[java]fanx.interop::IntArray?")
          case "[J": return ns.resolveType("[java]fanx.interop::LongArray?")
          case "[F": return ns.resolveType("[java]fanx.interop::FloatArray?")
          case "[D": return ns.resolveType("[java]fanx.interop::DoubleArray?")
        }
        throw Err(cls.getName)
      }

      // return "[java] foo.bar::[Baz"
      comp := toFanType(bridge, compCls, true).toNonNullable
      if (comp isnot JavaType) throw Err("Not JavaType: $compCls -> $comp")
      return ((JavaType)comp).toArrayOf.toNullable
    }

    // any Java use of Obj/Str is considered potential nullable
    if (cls.getName == "java.lang.Object")
      return multiDim ? ns.resolveType("[java]java.lang::Object?") : ns.objType.toNullable
    if (cls.getName == "java.lang.String")
      return multiDim ? ns.resolveType("[java]java.lang::String?") : ns.strType.toNullable

    // Java FFI
    name := cls.getName[cls.getName.indexr(".")+1..-1]
    sig := "[java]${cls.getPackage.getName}::${name}?"
    return ns.resolveType(sig)
  }

  static Int toClassFlags(Int modifiers)
  {
    return FanUtil.classModifiersToFanFlags(modifiers)
  }

  static Int toMemberFlags(Int modifiers)
  {
    return FanUtil.memberModifiersToFanFlags(modifiers)
  }

  static Void errUnknownType(UnknownTypeErr e)
  {
    // just print a warning and ignore problematic APIs
    echo("WARNING: Cannot map Java type: $e.message")
  }
}
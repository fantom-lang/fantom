//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Nov 08  Brian Frank  Creation
//   13 Dec 08  Brian Frank  Port from Java to Fantom using FFI
//

using compiler
using [java] java.lang
using [java] java.lang.reflect::Constructor as JCtor
using [java] java.lang.reflect::Field as JField
using [java] java.lang.reflect::Method as JMethod
using [java] java.lang.reflect::Modifier as JModifier
using [java] fanx.util

**
** JavaReflect provides Java reflection utilities.
** It encapsulates the FFI calls out to Java.
**
internal class JavaReflect
{
  **
  ** Map class meta-data and Java members to Fantom slots
  ** for the specified JavaType
  **
  static Void loadType(JavaType self, Str:CSlot slots)
  {
    // map to Java class
    cls := toJavaClass(self)

    // map superclass
    if (cls.getSuperclass != null)
      self.base = toFanType(self.bridge, cls.getSuperclass).toNonNullable

    // map interfaces to mixins
    mixins := CType[,]
    cls.getInterfaces.each |Class c|
    {
      try
        mixins.add(toFanType(self.bridge, c).toNonNullable)
      catch (UnknownTypeErr e)
        errUnknownType(e)
    }
    if (cls.isAnnotation) mixins.add(self.ns.facetType)
    self.mixins = mixins

    // map Java modifiers to Fantom flags
    self.flags = toClassFlags(cls.getModifiers)

    // map Annotation element methods as fields so that
    // it looks like a Fantom facet
    if (cls.isAnnotation) mapAnnotationFields(cls, self, slots)

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
    acc := JField:JField[:]

    // first add all the public fields
    cls.getFields.each |JField j| { acc[j] = j }

    // do protected fields working back up the hierarchy; don't
    // worry about interfaces b/c they can declare protected members
    while (cls != null)
    {
      cls.getDeclaredFields.each |JField j|
      {
        if (!JModifier.isProtected(j.getModifiers)) return
        if (acc[j] == null) acc[j] = j
      }
      cls = cls.getSuperclass
    }

    return acc.vals
  }

  **
  ** Reflect the public and protected methods which Java
  ** reflection makes very difficult.
  **
  static JMethod[] findMethods(Class? cls)
  {
    acc := JMethod:JMethod[:]

    // first add all the public methods
    cls.getMethods.each |JMethod j| { acc[j] = j }

    // do protected methods working back up the hierarchy; don't
    // worry about interfaces b/c they can declare protected members
    while (cls != null)
    {
      cls.getDeclaredMethods.each |JMethod j|
      {
        if (!JModifier.isProtected(j.getModifiers)) return
        if (acc[j] == null) acc[j] = j
      }
      cls = cls.getSuperclass
    }

    return acc.vals
  }

//////////////////////////////////////////////////////////////////////////
// Java Member -> Fantom CSlot
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
      if (java.isEnumConstant()) fan.flags = fan.flags.or(FConst.Enum)
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
      fan.flags = toMemberFlags(mods).or(FConst.Ctor)
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

    // check the linked list for methods with the exact same
    // signature (this can happen by inheriting abstract methods
    // from multiple interfaces)
    for (p := x; p != null; p = p.next)
      if (p is JavaMethod && m.sigsEqual(p))
        return

    // create linked list of overloads
    m.next = x.next
    x.next = m
  }

//////////////////////////////////////////////////////////////////////////
// Annotations
//////////////////////////////////////////////////////////////////////////

  static Void mapAnnotationFields(Class cls, JavaType self, Str:CSlot slots)
  {
    // Java annotations declare their "elements" as abstract public
    // methods, but in Fantom facets are declared with const fields;
    // so we here we fake it out so that a Java annotation type looks
    // like a Fantom facet from the compiler's perspective
    ns := self.ns
    cls.getDeclaredMethods.each |JMethod m|
    {
      if (!JModifier.isPublic(m.getModifiers)) return
      if (!JModifier.isAbstract(m.getModifiers)) return
      try
      {
        fan := JavaField()
        fan.parent = self
        fan.name = m.getName
        fan.flags = FConst.Public.or(FConst.Const)
        switch (m.getReturnType.getName)
        {
          case "java.lang.Class":    fan.fieldType = ns.typeType
          case "[Ljava.lang.Class;": fan.fieldType = ns.typeType.toListOf
          case "[Z":                 fan.fieldType = ns.boolType.toListOf
          case "[B":
          case "[S":
          case "[I":
          case "[J":                 fan.fieldType = ns.intType.toListOf
          case "[F":
          case "[D":                 fan.fieldType = ns.floatType.toListOf
          default:                   fan.fieldType = toFanType(self.bridge, m.getReturnType)
        }
        slots.set(fan.name, fan)
      }
      catch (UnknownTypeErr e) errUnknownType(e)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Use reflection to map a JavaType to its Java class.
  **
  static Class toJavaClass(JavaType t)
  {
    return Class.forName(t.toJavaClassName)
  }

  **
  ** Map an array of Java classes to their CType representations.
  **
  static CType[] toFanTypes(JavaBridge bridge, Class[] cls)
  {
    return cls.map |Class c->CType| { toFanType(bridge, c) }
  }

  **
  ** Map a Java classes to its CType representation.
  **
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

    // check for direct mappings of Obj/Str/Decimal (considered nullable)
    if (!multiDim)
    {
      direct := objectClassToDirectFanType(ns, cls.getName)
      if (direct != null) return direct.toNullable
    }

    // anything in fan.sys package is really a sys pod type
    package := cls.getPackage.getName
    name := cls.getName[cls.getName.indexr(".")+1..-1]
    if (package == "fan.sys") return ns.resolveType("sys::$name?")

    // Java FFI
    sig := "[java]${package}::${name}?"
    return ns.resolveType(sig)
  }

  **
  ** If the specified Java classname maps directly to a Fantom type
  ** then return it, otherwise null.  Direct mappings are 'sys::Obj',
  ** 'sys::Str', and 'sys::Decimal' - this method only handles
  ** object classes, not primitives like boolean, long, and double.
  **
  internal static CType? objectClassToDirectFanType(CNamespace ns, Str clsname)
  {
    switch (clsname)
    {
      case "java.lang.Object": return ns.objType
      case "java.lang.String":  return ns.strType
      case "java.math.BigDecimal": return ns.decimalType
      default: return null
    }
  }

  **
  ** Convert Java class modifiers to Fantom flags.
  **
  static Int toClassFlags(Int modifiers)
  {
    return FanUtil.classModifiersToFanFlags(modifiers)
  }

  **
  ** Convert Java member modifiers to Fantom flags.
  **
  static Int toMemberFlags(Int modifiers)
  {
    return FanUtil.memberModifiersToFanFlags(modifiers)
  }

  **
  ** Handle an error during the Java mapping process - if we
  ** can't map a given Java member we just output a warning
  ** rather than have the whole compilation fail.
  **
  static Void errUnknownType(UnknownTypeErr e)
  {
    // just print a warning and ignore problematic APIs
    echo("WARNING: Cannot map Java type: $e.msg")
  }
}
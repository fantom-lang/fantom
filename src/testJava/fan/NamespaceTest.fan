//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Nov 08  Brian Frank  Creation
//

using compiler

**
** NamespaceTest
**
class NamespaceTest : JavaTest
{

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  Void testReflect()
  {
    compiler := Compiler(CompilerInput())
    ns := ReflectNamespace()
    ns->c = compiler
    compiler.ns = ns

    // java.lang
    lang := ns.resolvePod("[java]java.lang", null)
    verifyEq(lang.name, "[java]java.lang")

    // java.lang.System
    sys := lang.resolveType("System", true)
    verifySame(sys.pod, lang)
    verifyEq(sys.name, "System")
    verifyEq(sys.qname, "[java]java.lang::System")

    // java.lang.System.out
    out := sys.field("out")
    verifySame(out.parent, sys)
    verifyEq(out.name, "out")
    verifyEq(out.qname, "[java]java.lang::System.out")
    verifyEq(out.fieldType.qname, "[java]java.io::PrintStream")
    verifyEq(out.isPublic, true)
    verifyEq(out.isStatic, true)

    // java.lang.System.gc
    gc := sys.method("gc")
    verifySame(gc.parent, sys)
    verifyEq(gc.name, "gc")
    verifyEq(gc.qname, "[java]java.lang::System.gc")
    verifySame(gc.returnType, ns.voidType)
    verifyEq(gc.params.size, 0)

    // java.lang.System.mapLibraryName (all Strings are considered nullable)
    mapLib := sys.method("mapLibraryName")
    verifySame(mapLib.parent, sys)
    verifySame(mapLib.returnType, ns.strType.toNullable)
    verifyEq(mapLib.params.size, 1)
    verifyEq(mapLib.params[0].name, "p0")
    verifySame(mapLib.params[0].paramType, ns.strType.toNullable)

    // check that APIs considered nullable
    secMgr := sys.method("getSecurityManager").returnType
    verifyEq(secMgr.isNullable, true)
    verifyEq(secMgr.signature, "[java]java.lang::SecurityManager?")
    verifyEq(secMgr.toNonNullable.signature, "[java]java.lang::SecurityManager")
    verifyEq(sys.method("getSecurityManager").returnType.signature,
      "[java]java.lang::SecurityManager?")
    verifySame(sys.method("identityHashCode").params[0].paramType,
      ns.objType.toNullable)
    verifyEq(sys.method("setProperties").params[0].paramType.signature,
      "[java]java.util::Properties?")

    // primitives/arrays
    t := ns.resolvePod("[java]fanx.test", null).resolveType("InteropTest", true)
    verifyEq(t.method("booleanArray").returnType.isNullable, true)
    verifyEq(t.method("booleanArray").returnType.signature, "[java]fanx.interop::BooleanArray?")
    verifyEq(t.method("booleanArray").returnType.toNonNullable.signature, "[java]fanx.interop::BooleanArray")
    verifyEq(t.field("numb").fieldType.signature, "[java]::byte")

    // protected
    util := ns.resolvePod("[java]java.util", null)
    obs := util.resolveType("Observable", true)
    verifyEq(obs.method("clearChanged").isProtected, true)
    props := util.resolveType("Properties", true)
    verifyEq(props.method("rehash").isProtected, true)  // inherited thru HashMap
  }

//////////////////////////////////////////////////////////////////////////
// Using
//////////////////////////////////////////////////////////////////////////

  Void testUsingErrors()
  {
    verifyErrors(
     "using [java] java.lang  // ok
      using [java] java.foo.bar
      using [java] hello.there::SomeType
      using [java] java.lang::System // ok
      using [java] java.lang::Foo
      using [java] javax.swing::Foo as Bar
      class Foo {}
      ",
       [
          2, 1, "Java package 'java.foo.bar' not found",
          3, 1, "Java package 'hello.there' not found",
          5, 1, "Type not found in pod '[java]java.lang::Foo'",
          6, 1, "Type not found in pod '[java]javax.swing::Foo'",
       ])
  }

  Void testUsing()
  {
    compile(
      "using [java] java.util
       using [java] java.util::HashMap
       using [java] java.util::Date as JDate
       class Foo
       {
         Str a() { return ArrayList().getClass.getName }
         Str b() { return HashMap().getClass.getName }
         Str c() { return JDate().getClass.getName }
       }")

    obj := pod.types.first.make
    verifyEq(obj->a, "java.util.ArrayList")
    verifyEq(obj->b, "java.util.HashMap")
    verifyEq(obj->c, "java.util.Date")
  }

}
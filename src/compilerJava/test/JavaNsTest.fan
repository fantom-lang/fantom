//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Nov 08  Brian Frank  Creation
//

using compiler

**
** JavaNsTest
**
class JavaNsTest : Test
{
  Void test()
  {
    compiler := Compiler(CompilerInput())
    ns := ReflectNamespace(compiler)
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

    // java.lang.System.mapLibraryName
    mapLib := sys.method("mapLibraryName")
    verifySame(mapLib.parent, sys)
    verifySame(mapLib.returnType, ns.strType)
    verifyEq(mapLib.params.size, 1)
    verifyEq(mapLib.params[0].name, "p0")
    verifySame(mapLib.params[0].paramType, ns.strType)
  }
}
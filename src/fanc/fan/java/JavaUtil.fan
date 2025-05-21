//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 2025  Brian Frank  Creation
//

using compiler

**
** Java transpiler utilities
**
internal class JavaUtil
{
  ** Java package diretory for given pod
  static File podDir(File outDir, Str podName)
  {
    outDir + `fan/${podName}/`
  }

  ** Java source file for given type
  static File typeFile(File outDir, TypeDef t)
  {
    podDir(outDir, t.pod.name) + typeName(t).plus(".java").toUri
  }

  ** Fantom type to Java type name
  static Str typeName(CType t)
  {
    t.name
  }

  ** Base class to use for closure that extends function type
  static Str closureBase(TypeDef t)
  {
    funcType := (FuncType)t.base
    size := funcType.params.size
    if (size > 8) throw Err("Closure size unsupported: $t")
    return "fan.sys.Func.Indirect" + size
  }

  ** Fantom varaible to Java name
  static Str varName(Str name)
  {
    checkKeyword(name)
  }

  ** Fantom slot to Java type name
  static Str fieldName(CField x)
  {
    checkKeyword(x.name)
  }

  ** Fantom slot to Java type name
  static Str methodName(CMethod x)
  {
    n := x.name
    if (n.startsWith("instance\$init\$")) return "instance\$init"
    return checkKeyword(n)
  }

  ** If name is Java keyword prefix it
  static Str checkKeyword(Str name)
  {
    if (javaKeywords[name] != null) return "_$name"
    return name
  }

  ** The instance side method for a constructor
  static Str ctorImplName(CMethod x)
  {
    x.name + "\$"
  }

  ** Package directories for fanx
  static File[] fanxDirs(File outDir)
  {
    fanx.map |p->File| { outDir + `$p/` }
  }

  ** Package names for fanx we include for sys as "fanx/serial"
  static Str[] fanx()
  {
    // TODO: we should be able to shrink this down
    ["fanx/emit", "fanx/fcode", "fanx/interop", "fanx/serial", "fanx/tools", "fanx/util"]
  }

  ** Is this a native java type: Obj, Str, Int, Float, Bool, Num
  static Bool isJavaNative(CType t)
  {
    t.isObj || t.isStr || t.isVal || t.isNum
  }

  ** Map of method qname to binary operators
  static once Str:Str javaKeywords()
  {
    Str:Str[:].addList([
      "abstract", "assert", "boolean", "break", "byte", "case", "catch", "char",
      "class", "const", "continue", "default", "do", "double", "else", "enum",
      "extends", "final", "finally", "float", "for", "goto", "if", "implements",
      "import", "instanceof", "int", "interface", "long", "native", "new", "package",
      "private", "protected", "public", "return", "short", "static", "strictfp",
      "super", "switch", "synchronized", "this", "throw", "throws", "transient",
      "try", "void", "volatile", "while"
     ]).toImmutable
  }

  ** Map of method qname to unary operators
  static once Str:Str unaryOperators()
  {
    [
    "sys::Bool.not":        "!",
    "sys::Int.negate":      "-",
    "sys::Float.negate":    "-",
    "sys::Int.increment":   "++",
    "sys::Float.increment": "++",
    "sys::Int.decrement":   "--",
    "sys::Float.decrement": "++",

    ].toImmutable
  }

  ** Map of method qname to binary operators
  static once Str:Str binaryOperators()
  {
    [
    "sys::Str.plus": "+",

    "sys::Int.plus":        "+",
    "sys::Int.minus":       "-",
    "sys::Int.mult":        "*",
    "sys::Int.div":         "/",
    "sys::Int.plusFloat":   "+",
    "sys::Int.minusFloat":  "-",
    "sys::Int.multFloat":   "*",
    "sys::Int.divFloat":    "/",

    "sys::Float.plus":      "+",
    "sys::Float.minus":     "-",
    "sys::Float.mult":      "*",
    "sys::Float.div":       "/",
    "sys::Float.plusInt":   "+",
    "sys::Float.minusInt":  "-",
    "sys::Float.multInt":   "*",
    "sys::Float.divInt":    "/",

    ].toImmutable
  }

}


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
    suffix := size > 8 ? "X" : size.toStr
    return "fan.sys.Func.Indirect" + suffix
  }

  ** Fantom varaible to Java name
  static Str varName(Str name)
  {
    checkKeyword(name)
  }

  ** Fantom slot to Java type name
  static Str fieldName(CField x)
  {
    swizzle := javaSwizzles[x.qname]
    if (swizzle != null) return swizzle

    return checkKeywordOrMethod(x.name)
  }

  ** Fantom slot to Java type name
  static Str methodName(CMethod x)
  {
    n := x.name
    if (n.startsWith("instance\$init\$")) return "instance\$init"

    swizzle := javaSwizzles[x.qname]
    if (swizzle != null) return swizzle

    return checkKeywordOrMethod(n)
  }

  ** If name is Java keyword prefix it
  static Str checkKeyword(Str name)
  {
    if (javaKeywords[name] != null) return "_$name"
    if (name == "fan") return "_fan" // havoc with qnames
    return name
  }

  ** If name is Java keyword prefix it
  static Str checkKeywordOrMethod(Str name)
  {
    if (javaKeywords[name] != null) return "_$name"
    if (javaObjMethods[name] != null) return "_$name"
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

  ** Is x a synthetic wrappers such as acme::Wraper$List
  static Bool isSyntheticWrapper(TypeDef x)
  {
    x.isSynthetic && x.name.startsWith("Wrap\$")
  }

  ** Is x a synthetic under the given parent
  static Bool isSyntheticClosure(TypeDef parent, TypeDef x)
  {
    x.isSynthetic && x.qname.startsWith(parent.qname) && x.qname.getSafe(parent.qname.size) == '$'
  }

  ** Generate inner class for synthetic variable wrapper.
  static Str syntheticWrapperName(TypeDef x)
  {
    x.name
  }

  ** Map synthetic to inner class name
  static Str syntheticClosureName(TypeDef x)
  {
    i := x.qname.index("\$") ?: throw ArgErr(x.qname)
    n := x.qname[i+1..-1]
    return n.capitalize
  }

  ** Inner class for mixin static fields
  static Str mixinFieldsName()
  {
    "Fields"
  }

  ** Field name to store native peer
  static Str peerFieldName() { "peer" }

  ** Type name for native peer
  static Str peerTypeName(TypeDef t) { t.name + "Peer" }

  ** Is this a native java type: Obj, Str, Int, Float, Bool, Num
  static Bool isJavaNative(CType t)
  {
    t.isObj || t.isStr || t.isVal || t.isNum || t.isDecimal
  }

  ** Java Object methods we can't override
  static once Str:Str javaObjMethods()
  {
    Str:Str[:].addList([
      "finalize", "getClass", "hashCode", "notify",
      "notifyAll", "toString", "wait"])
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
    "sys::Float.decrement": "--",

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
    "sys::Int.mod":         "%",
    "sys::Int.plusFloat":   "+",
    "sys::Int.minusFloat":  "-",
    "sys::Int.multFloat":   "*",
    "sys::Int.divFloat":    "/",
    "sys::Int.modFloat":    "%",

    "sys::Float.plus":      "+",
    "sys::Float.minus":     "-",
    "sys::Float.mult":      "*",
    "sys::Float.div":       "/",
    "sys::Float.mod":       "%",
    "sys::Float.plusInt":   "+",
    "sys::Float.minusInt":  "-",
    "sys::Float.multInt":   "*",
    "sys::Float.divInt":    "/",
    "sys::Float.modInt":    "%",

    ].toImmutable
  }

  ** Map of Fantom qnames to Java slot names
  static once Str:Str javaSwizzles()
  {
    // should be in sync with fanx.util.FanUtil
    [
      "sys::List.add":    "_add",
      "sys::List.clear":  "_clear",
      "sys::List.remove": "_remove",
      "sys::List.size":   "_size",
      "sys::Map.clear":   "_clear",
      "sys::Map.size":    "_size",
    ].toImmutable
  }

}


//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Feb 2026  Trevor Adelman  Creation
//

using compiler

**
** Python transpiler utilities
**
class PyUtil
{
  ** Python reserved words that are used as pod names and need directory escaping
  static const Str[] reservedPodNames := ["def", "class", "import", "from", "if", "else",
                                           "for", "while", "try", "except", "finally",
                                           "with", "as", "in", "is", "not", "and", "or",
                                           "True", "False", "None", "lambda", "return",
                                           "yield", "raise", "pass", "break", "continue",
                                           "global", "nonlocal", "async", "await"]

  ** Escape pod name if it conflicts with Python reserved words
  static Str escapePodName(Str podName)
  {
    reservedPodNames.contains(podName) ? "${podName}_" : podName
  }

  ** Python keywords that cannot be used as class names or attribute accesses
  static const Str[] reservedTypeNames := ["None", "True", "False"]

  ** Escape type name if it conflicts with Python keywords
  ** e.g., xeto::None -> None_ (because "class None" and ".None" are syntax errors)
  static Str escapeTypeName(Str typeName)
  {
    reservedTypeNames.contains(typeName) ? "${typeName}_" : typeName
  }

  ** Get output file for a type
  ** Uses fan/{podName}/ namespace to avoid Python built-in conflicts
  static File typeFile(File outDir, TypeDef t)
  {
    escapedPod := escapePodName(t.pod.name)
    escapedType := escapeTypeName(t.name)
    return outDir + `fan/${escapedPod}/${escapedType}.py`
  }

  ** Get output directory for a pod
  ** Uses fan/{podName}/ namespace to avoid Python built-in conflicts
  static File podDir(File outDir, Str podName)
  {
    escapedPod := escapePodName(podName)
    return outDir + `fan/${escapedPod}/`
  }

  ** Convert pod name to Python import path
  ** e.g., "sys" -> "fan.sys", "testSys" -> "fan.testSys", "def" -> "fan.def_"
  static Str podImport(Str podName)
  {
    escapedPod := escapePodName(podName)
    return "fan.${escapedPod}"
  }

  ** Check if a type signature is a Java FFI type
  ** e.g., "[java]java.lang.management::ThreadMXBean"
  static Bool isJavaFfi(Str? name)
  {
    if (name == null) return false
    return name.contains("[java]")
  }

  ** Sanitize Java FFI type references for Python
  ** In JS transpiler, these become parseable but fail at runtime if invoked
  ** For Python, we use a similar pattern: [java]x.y -> java_ffi_fail.x.y
  static Str sanitizeJavaFfi(Str name)
  {
    if (name.contains(".[java].")) return name.replace(".[java].", ".")
    if (name.contains("[java]")) return name.replace("[java]", "java_ffi_fail.")
    return name
  }

  ** Python reserved words that need to be escaped
  static const Str:Str reservedWords
  static
  {
    m := Str:Str[:]
    // Python keywords
    [
      "False", "None", "True", "and", "as", "assert", "async", "await",
      "break", "class", "continue", "def", "del", "elif", "else", "except",
      "finally", "for", "from", "global", "if", "import", "in", "is",
      "lambda", "nonlocal", "not", "or", "pass", "raise", "return", "try",
      "while", "with", "yield", "match", "case",
      // Built-in functions that could conflict
      "type", "hash", "id", "list", "map", "str", "int", "float", "bool",
      "self",
      // Additional builtins that conflict with Fantom method names
      "abs", "all", "any", "min", "max", "pow", "round", "set", "dir",
      "oct", "open", "vars", "print",
      // Module name that conflicts with pod namespace import (from fan import sys)
      "sys"
    ].each |name| { m[name] = "${name}_" }
    reservedWords = m.toImmutable
  }

  ** Convert camelCase to snake_case
  ** Examples:
  **   toStr -> to_str
  **   isEmpty -> is_empty
  **   XMLParser -> xml_parser
  **   getHTTPResponse -> get_http_response
  **   utf16BE -> utf16_be
  **   toBase64Uri -> to_base64_uri
  static Str toSnakeCase(Str name)
  {
    // Fast path: if all lowercase and no uppercase, return as-is
    hasUpper := false
    name.each |ch| { if (ch.isUpper) hasUpper = true }
    if (!hasUpper) return name

    buf := StrBuf()
    prev := 0
    name.each |ch, i|
    {
      if (ch.isUpper)
      {
        // Check if this is start of acronym or end of acronym
        next := (i + 1 < name.size) ? name[i + 1] : 0
        prevIsLower := prev.isLower
        prevIsDigit := prev.isDigit
        nextIsLower := next != 0 && next.isLower

        // Add underscore before uppercase if:
        // 1. Previous char was lowercase (camelCase boundary): toStr -> to_str
        // 2. We're in an acronym and next char is lowercase (end of acronym): XMLParser -> xml_parser
        // 3. Previous char was a digit (number to uppercase): utf16BE -> utf16_be
        if (i > 0 && (prevIsLower || prevIsDigit || (prev.isUpper && nextIsLower)))
        {
          buf.addChar('_')
        }
        buf.addChar(ch.lower)
      }
      else
      {
        buf.addChar(ch)
      }
      prev = ch
    }
    return buf.toStr
  }

  ** Escape Python reserved words and invalid characters
  ** Also converts camelCase to snake_case for Pythonic naming
  static Str escapeName(Str name)
  {
    // First replace $ with _ (Fantom synthetic names use $)
    escaped := name.replace("\$", "_")
    // Convert camelCase to snake_case
    snake := toSnakeCase(escaped)
    // Then check for reserved words
    return reservedWords.get(snake, snake)
  }

  ** Convert Fantom boolean literal to Python
  static Str boolLiteral(Bool val)
  {
    val ? "True" : "False"
  }

  ** Convert Fantom null literal to Python
  static Str nullLiteral()
  {
    "None"
  }

  ** Is this a native Python type (uses static method dispatch)
  static Bool isPyNative(CType t)
  {
    t.isObj || t.isStr || t.isVal
  }

  ** Map of method qname to unary operators
  static once Str:Str unaryOperators()
  {
    [
      "sys::Bool.not":     "not ",
      "sys::Int.negate":   "-",
      "sys::Float.negate": "-",
    ].toImmutable
  }

  ** Map of method qname to binary operators
  static once Str:Str binaryOperators()
  {
    [
      "sys::Str.plus":        "+",

      "sys::Int.plus":        "+",
      "sys::Int.minus":       "-",
      "sys::Int.mult":        "*",
      // Int.div intentionally NOT mapped - Python // has floor division semantics
      // but Fantom uses truncated division (toward zero)
      // Handled by ObjUtil.div() in PyExprPrinter.divOp()
      // Int.mod intentionally NOT mapped - Python % has different semantics
      // for negative numbers (floor division vs truncated division)
      // Handled by ObjUtil.mod() in PyExprPrinter.modOp()
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

  ** The instance side method name for a constructor
  static Str ctorImplName(CMethod x)
  {
    "${x.name}_init_"
  }

  ** Handle special method names
  static Str methodName(CMethod x)
  {
    n := x.name
    if (n.startsWith("instance\$init\$")) return "instance_init_"
    return escapeName(n)
  }
}

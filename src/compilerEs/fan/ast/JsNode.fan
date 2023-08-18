//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   03 May 2023  Matthew Giannini Creation
//

using compiler

**
** JsNode
**
abstract class JsNode
{
  new make(CompileEsPlugin plugin, Node? node := null)
  {
    this.plugin = plugin
    this.nodeRef = node
  }

  CompileEsPlugin plugin { private set }
  Compiler c() { plugin.compiler }
  private Node? nodeRef

  virtual Node? node() { nodeRef }
  virtual Loc? loc() { node?.loc }
  static Loc? toLoc(Obj obj) { obj is Node ? ((Node)obj).loc : null }

  abstract Void write()

  JsWriter js() { plugin.js }

//////////////////////////////////////////////////////////////////////////
// Type Utils
//////////////////////////////////////////////////////////////////////////

  Bool isJsType(TypeDef def)
  {
    // we inline closures directly, so no need to generate anonymous types
    if (def.isClosure) return false

    // TODO:FIXIT: do we still need this?
    if (def.qname.contains("\$Cvars"))
    {
      echo("WARN: Cvar class: ${def.qname}")
      return false
    }

    // check for @Js facet or if forced generation
    return def.hasFacet("sys::Js") || c.input.forceJs
  }

  Bool checkJsSafety(CType ctype, Loc? loc)
  {
    if (ctype is TypeRef) return checkJsSafety(ctype->t, loc)
    else if (ctype is NullableType) return checkJsSafety(ctype->root, loc)
    else if (ctype is ListType) return checkJsSafety(ctype->v, loc)
    else if (ctype is MapType)
    {
      return checkJsSafety(ctype->k, loc) && checkJsSafety(ctype->v, loc)
    }
    else if (ctype is FuncType)
    {
      safe := true
      ft := (FuncType)ctype
      ft.params.each |param| { safe = safe && checkJsSafety(param, loc) }
      safe = safe && checkJsSafety(ft.ret, loc)
      return safe
    }
    else if (!(ctype.pod.name == "sys" || ctype.isSynthetic || ctype.facet("sys::Js") != null || c.input.forceJs))
    {
      warn("Type '${ctype.qname}' not available in JS", loc)
      return false
    }
    return true
  }

  CType resolveType(CType ctype)
  {
    t := ctype is TypeRef ? ctype->t : ctype
    if (t is NullableType) t = t->root
    return t
  }

//////////////////////////////////////////////////////////////////////////
// Method Utils
//////////////////////////////////////////////////////////////////////////

  ** generates '(p1, p2, ...pn)'
  Str methodParams(CParam[] params)
  {
    buf := StrBuf().addChar('(')
    params.each |param, i|
    {
      if (i > 0) buf.addChar(',')
      buf.add(nameToJs(param.name))
    }
    return buf.addChar(')').toStr
  }

//////////////////////////////////////////////////////////////////////////
// Name Utils
//////////////////////////////////////////////////////////////////////////

  ** Get the module-qualified name for this CType. If the type is in the
  ** this pod, it does not need to be qualified
  Str qnameToJs(CType ctype)
  {
    podName := ctype.pod.name
    thisPod := podName == plugin.pod.name
    js := thisPod ? ctype.name : "${plugin.podAlias(podName)}.${ctype.name}"

    // make it so java FFI calls parse in js runtimes
    // code will parse but fail if actually invoked
    if (js.contains(".[java].")) js = js.replace(".[java].", ".")
    else if (js.contains("[java]")) js = js.replace("[java]", "java.fail")

    return js
  }

  ** Get the name that should be used for the generated field in JS code.
  ** A field is always private so we do not need to swizzle its name.
  static Str fieldToJs(Obj name)
  {
    // if (name is Str) return "_${name}\$"
    if (name is Str) return "#${name}"
    if (name is Field) return fieldToJs(((Field)name).name)
    if (name is FieldDef) return fieldToJs(((FieldDef)name).name)
    throw ArgErr("${name} [${name.typeof}]")
  }

  ** Get the name that should be used for the generated method in JS code.
  ** It turns out we don't need to swizzle method names.
  static Str methodToJs(Str name) { return name; }

  ** Return the JS identifier name to use for the given Fantom name.
  ** This should be used to get names for local variable declarations
  ** and method/func parameters.
  **
  ** Note - use fieldJs for generating field names since we have a lot of special
  ** handling for fields
  ** Note - use methodJs for generating method names
  Str nameToJs(Str name) { pickleName(name, plugin.dependOnNames) }

  @NoDoc static Str pickleName(Str name, Obj? depends := null)
  {
    name = reservedWords.get(name, name)
    if (depends != null)
    {
      isDepends := false
      if (depends is Map) isDepends = ((Str:Bool)depends).get(name)
      else if (depends is List) isDepends = ((List)depends).contains(name)
      if (isDepends) name = "\$${name}"
    }
    return name
  }

  private static const Str:Str reservedWords
  static
  {
    m := Str:Str[:]
    ["arguments",
     "as",
     "async",
     "await",
     "break",
     "case",
     "catch",
     "class",
     "const",
     "continue",
     "debugger",
     "default",
     "delete",
     "do",
     "else",
     "enum",
     "export",
     "eval",
     "extends",
     "false",
     "finally",
     "for",
     "from",
     "function",
     "get",
     "if",
     "implements",
     "import",
     "in",
     "instanceof",
     "interface",
     "let",
     "new",
     "null",
     "of",
     "package",
     "private",
     "protected",
     "public",
     "return",
     "self",      // not a reserved word but used heavily by the compiler
     "set",
     "static",
     "super",
     "switch",
     // "this",   // causes problems with code generation. needs deeper investigation, but should be safe since it is also Fantom keyword
     "throw",
     "true",
     "try",
     "typeof",
     "var",
     "void",
     "while",
     "with",
     "yield",
     ].each |name| { m[name] = "${name}\$" }
     reservedWords = m.toImmutable
  }

  ** return a unique id name
  Str uniqName(Str name := "u")
  {
    "\$_${name}${plugin.nextUid}"
  }

//////////////////////////////////////////////////////////////////////////
// Logging
//////////////////////////////////////////////////////////////////////////

  CompilerErr err(Str msg, Loc? loc := null) { plugin.err(msg, loc) }
  CompilerErr warn(Str msg, Loc? loc := null) { plugin.warn(msg, loc) }

//////////////////////////////////////////////////////////////////////////
// General Utils
//////////////////////////////////////////////////////////////////////////

  Bool isPrimitive(CType ctype) { pmap.get(ctype.qname, false) }
  const Str:Bool pmap :=
  [
    "sys::Bool":    true,
    "sys::Decimal": true,
    "sys::Float":   true,
    "sys::Int":     true,
    "sys::Num":     true,
    "sys::Str":     true
  ]

  Void writeBlock(Block? block)
  {
    if (block == null) return
    block.stmts.each |stmt| {
      writeStmt(stmt)
      js.wl(";")
    }
  }

  Void writeStmt(Stmt? stmt)
  {
    if (stmt == null) return
    JsStmt(plugin, stmt).write
  }

  Void writeExpr(Expr? expr)
  {
    if (expr == null) return
    switch (expr.id)
    {
      // case ExprId.call:     JsCallExpr(plugin, expr).write
      // case ExprId.shortcut: JsShortcutExpr(plugin, expr).write
      default:              JsExpr(plugin, expr).write
    }
  }

  TypeDef? curType() { plugin.curType }

}
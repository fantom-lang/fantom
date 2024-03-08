//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Apr 2023  Matthew Giannini Creation
//    2 Jun 2023  Kiera O'Flynn    Implemented
//

using compiler
using compilerEs
using fandoc

**
** Generate TypeScript declaration file for a pod
**
class CompileTsPlugin : CompilerStep
{
  new make(Compiler compiler) : super(compiler)
  {
    this.c = compiler
    docParser = FandocParser()
  }

  private Compiler c
  private OutStream? out
  private FandocParser docParser
  private TsDocWriter? docWriter

//////////////////////////////////////////////////////////////////////////
// Main writing method
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    buf := Buf()
    out = buf.out
    docWriter = TsDocWriter(out)

    // Write dependencies
    deps := pod.depends.map |CDepend dep->Str| { dep.name }
    deps.each |dep|
    {
      out.print("import * as ${dep} from './${dep}.js';\n")
    }
    if (pod.name == "sys") printJsObj
    out.write('\n')

    // Write declaration for each type
    pod.typeDefs.findAll { !it.isSynthetic }.each |type|
    {
      // TODO: for now generate declaration for all types regardless of whether
      // they have the @Js facet or not
      // if (!type.hasFacet(jsFacet)) return
      if (type.isInternal) return

      isList := false
      isMap  := false

      setupDoc(pod.name, type.name)

      // Parameterization of List & Map
      classParams := ""
      if (type.signature == "sys::List")
      {
        classParams = "<V = unknown>"
        isList = true
      }
      if (type.signature == "sys::Map")
      {
        classParams = "<K = unknown, V = unknown>"
        isMap = true
      }

      abstr := type.isMixin ? "abstract " : ""
      extends := ""
      if (type.base != null)
        extends = "extends ${getNamespacedType(type.base.name, type.base.pod.name, pod)} "
      if (!type.mixins.isEmpty)
      {
        implement := type.mixins.map { getNamespacedType(it.name, it.pod.name, this.pod) }.join(", ")
        extends += "implements $implement "
      }
      else if (isList) extends += "implements Iterable<V> "

      // Write class documentation & header
      printDoc(type.doc, 0)
      out.print("export ${abstr}class $type.name$classParams $extends{\n")

      hasItBlockCtor := type.ctors.any |CMethod m->Bool| {
        m.params.any |CParam p->Bool| { p.paramType.isFunc }
      }

      // Write fields
      if (true)
      {
        // write <Class>.type$ field for use in TypeScript
        t := getNamespacedType("Type", "sys", this.pod)
        out.print("  static type\$: ${t}\n")
      }
      fields := type.fields.findAll |field|
      {
        field.isPublic &&
        (field is FieldDef ||
         (type.mixins.any |m| { m.slot(field.name)?.isPublic == true } &&
          type.base?.slot(field.name) == null))
      }
      fields.each |field|
      {
        name := JsNode.methodToJs(field.name)
        staticStr := field.isStatic ? "static " : ""
        typeStr := getJsType(field.fieldType, pod, field.isStatic ? type : null)

        if (field is FieldDef)
          printDoc(field->doc, 2)

        out.print("  $staticStr$name(): $typeStr\n")
        if (!field.isConst)
          out.print("  $staticStr$name(it: $typeStr): void\n")
        else if (hasItBlockCtor)
          out.print("  ${staticStr}__$name(it: $typeStr): void\n")
      }

      // Write methods
      if (isList)
      {
        // make list iterable
        out.print("  /** List Iterator */\n")
        out.print("  [Symbol.iterator](): Iterator<V>\n")
      }
      methods := type.methods.findAll |method|
      {
        method.isPublic &&
        (method is MethodDef ||
         (type.mixins.any |m| { m.slot(method.name)?.isPublic == true } &&
          type.base?.slot(method.name) == null))
      }
      methods.each |method|
      {
        isStatic := method.isStatic || method.isCtor || pmap.containsKey(type.signature)
        staticStr := isStatic ? "static " : ""
        name := JsNode.methodToJs(method.name)
        if (type.signature == "sys::Func") name += "<R>"

        inputList := method.params.map |CParam p->Str| {
          paramName := JsNode.pickleName(p.name, deps)
          if (p.hasDefault)
            paramName += "?"
          paramType := getJsType(p.paramType, pod, isStatic ? type : null)
          return "$paramName: $paramType"
        }
        if (!method.isStatic && !method.isCtor && pmap.containsKey(type.signature))
          inputList.insert(0, "self: ${pmap[type.signature]}")
        if (method.isCtor)
          inputList.add("...args: unknown[]")
        inputs := inputList.join(", ")

        output := method.isCtor ? type.name : getJsType(method.returnType, pod, pmap.containsKey(type.signature) ? type : null)
        if (method.qname == "sys::Obj.toImmutable" ||
            method.qname == "sys::List.ro" ||
            method.qname == "sys::Map.ro")
              output = "Readonly<$output>"

        if (method is MethodDef)
          printDoc(method->doc, 2)
        out.print("  $staticStr$name($inputs): $output\n")
      }

      out.print("}\n")
    }
    if (pod.name == "sys") printObjUtil

    buf.seek(0)
    c.tsDecl = buf.readAllStr
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  ** Gets the name of the given type in JS. For example, a map type
  ** could show up as Map, sys.Map, Map<string, string>, etc.
  **
  ** 'thisPod' is the pod you are writing the type in; if 'type' is
  ** from a different pod, it will have its pod name prepended to it,
  ** e.g. sys.Map rather than just Map.
  **
  ** 'thisType' should only be non-null if instances of sys::This should
  ** be written as that type instead of "this". For example, Int methods
  ** which are non-static in Fantom but static in JS cannot use the "this"
  ** type.
  private Str getJsType(CType type, CPod thisPod, CType? thisType := null)
  {
    // Built-in type
    if (pmap.containsKey(type.signature) && !type.isFunc)
      return pmap[type.signature]

    // Nullable type
    if (type.isNullable)
      return "${getJsType(type.toNonNullable, thisPod, thisType)} | null"

    // This
    if (type.isThis)
      return thisType == null ? "this" : thisType.name

    // Generic parameters
    if (type.isGenericParameter)
      switch (type.name)
      {
        case "L": return "List<V>"
        case "M": return "Map<K,V>"
        case "R": return "R"
        default:  return "unknown"
      }
    
    // List/map types
    if (type.isList || type.isMap)
    {
      if (type is TypeRef) type = type.deref

      res := getNamespacedType(type.name, "sys", thisPod)
      if (!type.isGeneric)
      {
        k := type is MapType ? "${getJsType(type->k, thisPod, thisType)}, " : ""
        v := getJsType(type->v, thisPod, thisType)
        res += "<$k$v>"
      }
      return res
    }

    // Function types
    if (type.isFunc)
    {
      if (type is TypeRef) type = type.deref
      if (!(type is FuncType)) //isGeneric
        return "Function"

      CType[] args := type->params->dup
      inputs := args.map |CType t, Int i->Str| { "arg$i: ${getJsType(t, thisPod, thisType)}" }
                    .join(", ")
      output := getJsType(type->ret, thisPod, thisType)
      return "(($inputs) => $output)"
    }

    // Obj
    if (type.signature == "sys::Obj")
      return getNamespacedType("JsObj", "sys", thisPod)

    // Regular types
    return getNamespacedType(type.name, type.pod.name, thisPod)
  }

  ** Gets the name of the type with, when necessary, the pod name prepended to it.
  ** e.g. could return "TimeZone" or "sys.TimeZone" based on the current pod.
  private Str getNamespacedType(Str typeName, Str typePod, CPod currentPod)
  {
    if (typePod == currentPod.name)
      return typeName
    return "${typePod}.${typeName}"
  }

  private Void setupDoc(Str pod, Str type)
  {
    docWriter.pod = pod
    docWriter.type = type
  }

  private Void printDoc(DocDef? doc, Int indent)
  {
    if (doc == null) return

    docWriter.indent = indent
    docParser.parse("Doc", doc.lines.join("\n").in).write(docWriter)
  }

  private Void printJsObj()
  {
    out.print("export type JsObj = Obj | number | string | boolean | Function\n")
  }

  private Void printObjUtil()
  {
    out.print( """export class ObjUtil {
                    static hash(obj: any): number
                    static equals(a: any, b: JsObj | null): boolean
                    static compare(a: any, b: JsObj | null, op?: boolean): number
                    static compareNE(a: any, b: JsObj | null): boolean
                    static compareLT(a: any, b: JsObj | null): boolean
                    static compareLE(a: any, b: JsObj | null): boolean
                    static compareGE(a: any, b: JsObj | null): boolean
                    static compareGT(a: any, b: JsObj | null): boolean
                    static is(obj: any, type: Type): boolean
                    static as(obj: any, type: Type): any
                    static coerce(obj: any, type: Type): any
                    static typeof(obj: any): Type
                    static trap(obj: any, name: string, args: List<JsObj | null> | null): JsObj | null
                    static doTrap(obj: any, name: string, args: List<JsObj | null> | null, type: Type): JsObj | null
                    static isImmutable(obj: any): boolean
                    static toImmutable(obj: any): JsObj | null
                    static with<T>(self: T, f: ((it: T) => void)): T
                    static toStr(obj: any): string
                    static echo(obj: any): void
                  }
                  """)
  }

  private const Str:Str pmap :=
  [
    "sys::Bool":    "boolean",
    "sys::Decimal": "number",
    "sys::Float":   "number",
    "sys::Int":     "number",
    "sys::Num":     "number",
    "sys::Str":     "string",
    "sys::Void":    "void",
    "sys::Func":    "(...args: any[]) => R"
  ]

}
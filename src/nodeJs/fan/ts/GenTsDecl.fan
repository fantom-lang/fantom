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
class GenTsDecl
{
  ** Generate ts declare file a pod using reflection
  static Void genForPod(Pod pod, OutStream out, [Str:Obj?] opts := [:])
  {
    // hack to make reflect namespace able to resolve native bridge
    ns := ReflectNamespace()
    c  := Compiler(CompilerInput { it.podName = "dummy" })
    c.ns = ns
    ns->c = c

    // make
    make(out, ReflectPod(ns, pod), opts).run
  }

  new make(OutStream out, CPod pod, [Str:Obj?] opts)
  {
    this.out = out
    this.pod = pod
    this.opts = opts
    this.docWriter = TsDocWriter(out)
  }

  private OutStream out
  private CPod pod
  private [Str:Obj?] opts
  private TsDocWriter docWriter
  private Str[]? deps := null

//////////////////////////////////////////////////////////////////////////
// Opts
//////////////////////////////////////////////////////////////////////////

  ** Generate all types even if they don't have the @Js facet
  private Bool allTypes() { opts["allTypes"] == true }

  ** Generate all node types even if they are @NoDoc
  private Bool genNoDoc() { opts["genNoDoc"] == true }

  ** Check if this node should be generated based on its @NoDoc facet
  ** and the 'genNoDoc' option.
  private Bool isNoDoc(CNode node) { node.isNoDoc && !genNoDoc }

//////////////////////////////////////////////////////////////////////////
// Main writing method
//////////////////////////////////////////////////////////////////////////

  Void run()
  {
    genTypes := pod.types.findAll |CType type->Bool|
    {
      if (type.isSynthetic || type.isInternal || isNoDoc(type)) return false

      // if we aren't generating all types, short-circuit if missing @Js facet
      if (!allTypes && !type.hasFacet("sys::Js")) return false

      return true
    }

    // short-circuit if no types to generate
    if (genTypes.isEmpty) return

    // Write dependencies
    this.deps = pod.depends.map |CDepend dep->Str| { dep.name }
    deps.each |dep|
    {
      out.print("import * as ${dep} from './${dep}.js';\n")
    }
    if (pod.name == "sys") printJsObj
    out.writeChar('\n')

    // Write declaration for each type
    genTypes.each |type|
    {
      genType(type)
    }

    if (pod.name == "sys") printObjUtil
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  private Void genType(CType type)
  {
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
      extends = "extends ${getNamespacedType(type.base.name, type.base.pod.name)} "
    if (!type.mixins.isEmpty)
    {
      implement := type.mixins.map { getNamespacedType(it.name, it.pod.name) }.join(", ")
      extends += "implements $implement "
    }
    else if (isList) extends += "implements Iterable<V> "

    // Write class documentation & header
    printDoc(type, 0)
    out.print("export ${abstr}class $type.name$classParams $extends{\n")

    hasItBlockCtor := type.ctors.any |CMethod m->Bool| {
      m.params.any |CParam p->Bool| { p.type.isFunc }
    }

    // keep track of slot names we've written. only mixin slots that have
    // not been overridden by the current type will be included
    Str[] writtenSlots := [,]

    // Write fields
    if (true)
    {
      // write <Class>.type$ field for use in TypeScript
      t := getNamespacedType("Type", "sys")
      out.print("  static type\$: ${t}\n")
    }
    type.fields.each |CField field|
    {
      if (!includeSlot(type, field)) return
      writeField(type, field, hasItBlockCtor)
      writtenSlots.add(field.name)
    }

    // Write methods
    if (isList)
    {
      // make list iterable and write custom make constructor
      out.print(
        """  /** List Iterator */
             [Symbol.iterator](): Iterator<V>;
             /** Constructor for of[] with optional initial values */
             static make(of\$: Type, ...args: unknown[]): List;
           """)
    }
    type.methods.each |method|
    {
      if (!includeSlot(type, method)) return
      writeMethod(type, method)
      writtenSlots.add(method.name)
    }

    // copy mixins
    type.mixins.each |CType ref|
    {
      ref.slots.each |CSlot slot|
      {
        // skip slots already written by the current type (overridden)
        if (writtenSlots.contains(slot.name)) return
        if (!slot.parent.isMixin) return
        if (isNoDoc(slot)) return
        if (slot.isStatic) return

        // write the mixin slot
        if (slot is CField)
        {
          // echo("    ${slot} [slot] parent = ${slot.parent} [${slot.typeof}]")
          writeField(ref, slot, hasItBlockCtor)
        }
        else if (slot is CMethod)
        {
          // echo("    ${slot} [slot] parent = ${slot.parent} [${slot.typeof}]")
          writeMethod(ref, slot)
        }
        writtenSlots.add(slot.name)
      }
    }

    out.print("}\n\n")
  }

  ** Only used for checking slots on the current type; not inherited
  private Bool includeSlot(CType type, CSlot slot)
  {
    // declared only slots, not inherited
    if (slot.parent != type) return false

    // skip @NoDoc
    if (isNoDoc(slot)) return false

    // we write the List.make() method explicitly because the
    // javascript impl doesn't adhere to the type signature for Fantom.
    if (slot.qname == "sys::List.make") return false

    // public only
    return slot.isPublic
  }

//////////////////////////////////////////////////////////////////////////
// Field
//////////////////////////////////////////////////////////////////////////

  private Void writeField(CType parent, CField field, Bool hasItBlockCtor)
  {
    name := JsNode.methodToJs(field.name)
    staticStr := field.isStatic ? "static " : ""
    typeStr := getJsType(field.type, field.isStatic ? parent : null)

    printDoc(field, 2)

    out.print("  ${staticStr}${name}(): ${typeStr};\n")
    if (!field.isConst)
      out.print("  ${staticStr}${name}(it: ${typeStr}): void;\n")
    else if (hasItBlockCtor)
      out.print("  ${staticStr}__$name(it: ${typeStr}): void;\n")
  }

//////////////////////////////////////////////////////////////////////////
// Method
//////////////////////////////////////////////////////////////////////////

  private Void writeMethod(CType parent, CMethod method)
  {
    isStatic := method.isStatic || method.isCtor || pmap.containsKey(parent.signature)
    staticStr := isStatic ? "static " : ""
    name := JsNode.methodToJs(method.name)
    if (parent.signature == "sys::Func") name += "<R>"

    inputList := method.params.map |CParam p->Str| { toMethodParam(parent, method, isStatic, p) }
    if (!method.isStatic && !method.isCtor && pmap.containsKey(parent.signature))
      inputList.insert(0, "self: ${pmap[parent.signature]}")
    if (method.isCtor)
      inputList.add("...args: unknown[]")
    inputs := inputList.join(", ")

    output := toMethodReturn(parent, method)

    printDoc(method, 2)
    out.print("  ${staticStr}${name}(${inputs}): ${output};\n")
  }

  private Str toMethodParam(CType parent, CMethod method, Bool isStatic, CParam p)
  {
    paramName := JsNode.pickleName(p.name, deps)
    if (p.hasDefault)
      paramName += "?"
    paramType := toMethodSigType(method, p.type, isStatic ? parent : null)

    return "${paramName}: ${paramType}"
  }

  private Str toMethodReturn(CType type, CMethod method)
  {
    output := method.isCtor ? type.name : toMethodSigType(method, method.returns, pmap.containsKey(type.signature) ? type : null)
    if (method.qname == "sys::Obj.toImmutable" ||
        method.qname == "sys::List.ro" ||
        method.qname == "sys::Map.ro")
          output = "Readonly<${output}>"
    return output
  }

  private Str toMethodSigType(CMethod method, CType sigType, CType? self)
  {
    // methods with the @Js facet treat Obj parameters as any
    ts := getJsType(sigType, self)
    if (ts == "sys.JsObj" && method.hasFacet("sys::Js")) return "any"
    return ts
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
  private Str getJsType(CType type, CType? thisType := null)
  {
    // Built-in type
    if (pmap.containsKey(type.signature) && !type.isFunc)
      return pmap[type.signature]

    // Nullable type
    if (type.isNullable)
      return getJsType(type.toNonNullable, thisType) + " | null"

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

      res := getNamespacedType(type.name, "sys")
      if (!type.isGeneric)
      {
        k := type is MapType ? (getJsType(type->k, thisType) + ", ") : ""
        v := getJsType(type->v, thisType)
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
      inputs := args.map |CType t, Int i->Str| { ("arg$i: " + getJsType(t, thisType)) }
                    .join(", ")
      output := getJsType(type->ret, thisType)
      return "(($inputs) => $output)"
    }

    // Obj
    if (type.signature == "sys::Obj")
      return getNamespacedType("JsObj", "sys")

    // Regular types
    return getNamespacedType(type.name, type.pod.name)
  }

  ** Gets the name of the type with, when necessary, the pod name prepended to it.
  ** e.g. could return "TimeZone" or "sys.TimeZone" based on the current pod.
  private Str getNamespacedType(Str typeName, Str typePod)
  {
    if (typePod == this.pod.name)
      return typeName
    return "${typePod}.${typeName}"
  }

  private Void setupDoc(Str pod, Str type)
  {
    docWriter.pod = pod
    docWriter.type = type
  }

  private Void printDoc(CNode node, Int indent)
  {
    doc := node.doc
    text := doc?.text?.trimToNull
    if (node.isNoDoc)
    {
      if (!genNoDoc) return
      insert := "NODOC API\n"
      text = text == null ? insert : "${insert}\n${text}"
    }
    if (text == null) return

    parser := FandocParser()
    parser.silent = true
    fandoc := parser.parse(node.toStr, text.in)

    docWriter.indent = indent
    fandoc.write(docWriter)
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


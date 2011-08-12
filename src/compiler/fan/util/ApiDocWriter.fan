//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//

**
** ApiDocWriter is used to write out an AST definition in
** the Fantom API doc formatted used by compilerDoc.
** See 'compilerDoc::ApiDocParser' for formal definition.
**
class ApiDocWriter
{
  new make(OutStream out) { this.out = out }

  Bool close() { out.close }

  This writeType(TypeDef t)
  {
    // header
    writeFacets(t.facets)
    if (t.isMixin)
      writeFlags(t.flags.and(FConst.Mixin.not)).w("mixin ").w(t.name)
    else
      writeFlags(t.flags).w("class ").w(t.name)
    if ((t.base != null && !t.base.isObj) || !t.mixins.isEmpty)
    {
      w(":")
      comma := false
      if (!t.isMixin && t.base != null) { writeTypeRef(t.base); comma = true }
      t.mixins.each |m|
      {
        if (comma) w(",")
        writeTypeRef(m)
        comma = true
      }
    }
    w("\n")
    writeDoc(t)
    w("\n")

    // slots
    t.slotDefs.each |slot|
    {
      if (!slot.isSynthetic) writeSlot(slot)
    }

    return this
  }

  private Void writeSlot(SlotDef s)
  {
    writeFacets(s.facets)
    writeFlags(s.flags)
    if (s is FieldDef) writeFieldSig(s)
    else writeMethodSig(s)
    w("\n")
    writeDoc(s)
    w("\n")
  }

  private Void writeFieldSig(FieldDef f)
  {
    writeTypeRef(f.fieldType).w(" ").w(f.name)
    if (f.init != null)
      w(":=").writeExpr(f.init)
  }

  private Void writeMethodSig(MethodDef m)
  {
    writeTypeRef(m.returnType).w(" ").w(m.name).w("(\n")
    m.paramDefs.each |param, i|
    {
      writeTypeRef(param.paramType).w(" ").w(param.name)
      if (param.def != null) w(":=").writeExpr(param.def)
      w("\n")
    }
    w(")")
  }

  private Void writeFacets(FacetDef[]? facets)
  {
    if (facets == null) return
    facets.each |facet| { writeFacet(facet) }
  }

  private Void writeFacet(FacetDef facet)
  {
    w("@").writeTypeRef(facet.type)
    if (!facet.names.isEmpty)
    {
      w(" {\n")
      facet.names.each |name, i|
      {
        w(name).w("=")
        writeExpr(facet.vals[i])
        w("\n")
      }
      w("}")
    }
    w("\n")
  }

  private This writeTypeRef(CType t)
  {
    w(t.signature)
  }

  private This writeExpr(Expr expr)
  {
    // this string must never have a newline since that
    // is how we determine end of expressions in parser
    w(expr.toDocStr ?: "...")
  }

  private This writeFlags(Int flags)
  {
    if (flags.and(FConst.Abstract)  != 0) w("abstract ")
    if (flags.and(FConst.Const)     != 0) w("const ")
    if (flags.and(FConst.Enum)      != 0) w("enum ")
    if (flags.and(FConst.Facet)     != 0) w("facet ")
    if (flags.and(FConst.Final)     != 0) w("final ")
    if (flags.and(FConst.Internal)  != 0) w("internal ")
    if (flags.and(FConst.Mixin)     != 0) w("mixin ")
    if (flags.and(FConst.Native)    != 0) w("native ")
    if (flags.and(FConst.Override)  != 0) w("override ")
    if (flags.and(FConst.Private)   != 0) w("private ")
    if (flags.and(FConst.Protected) != 0) w("protected ")
    if (flags.and(FConst.Public)    != 0) w("public ")
    if (flags.and(FConst.Static)    != 0) w("static ")
    if (flags.and(FConst.Synthetic) != 0) w("synthetic ")
    if (flags.and(FConst.Virtual)   != 0) w("virtual ")
    if (flags.and(FConst.Ctor)      != 0) w("new ")
    return this
  }

  private Void writeDoc(DefNode node)
  {
    if (node.doc == null) return
    node.doc.each |line|
    {
      if (line.isEmpty) w("\\\n")
      else w(line).w("\n")
    }
  }

  This w(Str x) { out.print(x); return this }

  OutStream out
}
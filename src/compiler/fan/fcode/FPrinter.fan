//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 05  Brian Frank  Creation
//   19 Aug 06  Brian Frank  Ported from Java to Fan
//

**
** FPrinter is used to pretty print fcode
**
class FPrinter : FConst
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(FPod pod, OutStream out := Sys.out)
  {
    this.pod = pod
    this.out = out
  }

//////////////////////////////////////////////////////////////////////////
// Dump
//////////////////////////////////////////////////////////////////////////

  Void all()
  {
    tables
    ftypes
    out.flush
  }

//////////////////////////////////////////////////////////////////////////
// Const Tables
//////////////////////////////////////////////////////////////////////////

  Void tables()
  {
    printLine("##### Tables #####");
    table("--- names ---",      pod.names)
    table("--- typeRefs ---",   pod.typeRefs)
    table("--- fieldRefs ---",  pod.fieldRefs)
    table("--- methodRefs ---", pod.methodRefs)
    table("--- ints ---",       pod.ints)
    table("--- floats ---",     pod.floats)
    table("--- strs ---",       pod.strs)
    table("--- durations ---",  pod.durations)
    table("--- uris ---",       pod.uris)
    out.flush
  }

  Void table(Str title, FTable table)
  {
    printLine(title)
    table.table.each |Obj obj, Int index|
    {
      m := obj.type.method("format", false)
      s := m != null ? m.callList([obj, pod]) : obj.toStr
      printLine("  [$index]  $s")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Types
//////////////////////////////////////////////////////////////////////////

  Void ftypes()
  {
    printLine("##### Types #####")
    pod.ftypes.each |FType t| { ftype(t) }
    out.flush
  }

  Void ftype(FType t)
  {
    printLine("--" + typeRef(t.self) + " : " + typeRef(t.fbase) + "--")
    if (!t.fmixins.isEmpty)
    {
      printLine("  mixin " + t.fmixins.join(", ") |Int m->Str| { return typeRef(m) });
    }
    attrs(t.fattrs)
    printLine
    t.ffields.each |FField f| { field(f) }
    t.fmethods.each |FMethod m| { method(m) }
    out.flush
  }

  Void slot(FSlot s)
  {
    if (s is FField)
      field((FField)s)
    else
      method((FMethod)s)
    out.flush
  }

  Void field(FField f)
  {
    printLine("  " + name(f.nameIndex) + " -> " + typeRef(f.typeRef) + " [" + flags(f.flags) + "]")
    attrs(f.fattrs)
    printLine
  }

  Void method(FMethod m)
  {
    print("  " + name(m.nameIndex) + " (")
    print(m.fparams.join(", ") |FMethodVar p->Str| { return typeRef(p.typeRef) + " " + name(p.nameIndex) })
    print(") -> " + typeRef(m.ret))
    if (m.ret != m.inheritedRet) print(" {" + typeRef(m.inheritedRet) + "}")
    printLine(" [" + flags(m.flags) + "]")
    m.vars.each |FMethodVar v, Int reg|
    {
      role := v.isParam ?  "Param" : "Local"
      if (m.flags & FConst.Static == 0) reg++
      printLine("    [" + role + " " + reg + "] " + pod.n(v.nameIndex) + " -> " + typeRef(v.typeRef))
      if (v.def != null) code(v.def)
    }
    if (m.code != null)
    {
      printLine("    [Code]")
      code(m.code)
    }
    attrs(m.fattrs)
    printLine
  }

  Void code(Buf code)
  {
    if (!showCode) return;
    out.flush
    codePrinter := FCodePrinter.make(pod, out)
    codePrinter.showIndex = showIndex
    codePrinter.code(code)
  }

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  Void attrs(FAttr[]? attrs)
  {
    if (attrs == null) return
    attrs.each |FAttr a| { attr(a) }
  }

  Void attr(FAttr attr)
  {
    name := name(attr.name)
    if (name == LineNumbersAttr && !showLines) return
    printLine("    [$name] size=$attr.data.size")
    if (name == SourceFileAttr)  sourceFileAttr(attr)
    if (name == ErrTableAttr)    errTableAttr(attr)
    if (name == LineNumberAttr)  lineNumberAttr(attr)
    if (name == LineNumbersAttr) lineNumbersAttr(attr)
    if (name == FacetsAttr)      facetsAttr(attr)
  }

  Void sourceFileAttr(FAttr attr)
  {
    printLine("       $attr.utf")
  }

 Void lineNumberAttr(FAttr attr)
  {
    printLine("       $attr.u2")
  }

  Void facetsAttr(FAttr attr)
  {
    buf := attr.data
    buf.seek(0)
    buf.readU2.times |,|
    {
      name := name(buf.readU2)
      val  := buf.readUtf
      printLine("       $name=$val")
    }
  }

  Void errTableAttr(FAttr attr)
  {
    buf := attr.data
    buf.seek(0)
    buf.readU2.times |,|
    {
      start   := buf.readU2
      end     := buf.readU2
      handler := buf.readU2
      tr      := buf.readU2
      printLine("      $start  to $end -> $handler  " + typeRef(tr))
    }
  }

  Void lineNumbersAttr(FAttr attr)
  {
    buf := attr.data
    buf.seek(0)
    buf.readU2.times |,|
    {
      pc   := buf.readU2
      line := buf.readU2
      printLine("       $pc: $line")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Dump Utils
//////////////////////////////////////////////////////////////////////////

  Str typeRef(Int i)
  {
    if (i == 65535) return "null"
    return pod.typeRefStr(i) + index(i)
  }

  Str name(Int i)
  {
    return pod.n(i) + index(i)
  }

  Str flags(Int flags)
  {
    s := StrBuf.make
    if (flags & FConst.Abstract  != 0) s.add("abstract ")
    if (flags & FConst.Const     != 0) s.add("const ")
    if (flags & FConst.Ctor      != 0) s.add("ctor ")
    if (flags & FConst.Enum      != 0) s.add("enum ")
    if (flags & FConst.Final     != 0) s.add("final ")
    if (flags & FConst.Getter    != 0) s.add("getter ")
    if (flags & FConst.Internal  != 0) s.add("internal ")
    if (flags & FConst.Mixin     != 0) s.add("mixin ")
    if (flags & FConst.Native    != 0) s.add("native ")
    if (flags & FConst.Override  != 0) s.add("override ")
    if (flags & FConst.Private   != 0) s.add("private ")
    if (flags & FConst.Protected != 0) s.add("protected ")
    if (flags & FConst.Public    != 0) s.add("public ")
    if (flags & FConst.Setter    != 0) s.add("setter ")
    if (flags & FConst.Static    != 0) s.add("static ")
    if (flags & FConst.Storage   != 0) s.add("storage ")
    if (flags & FConst.Synthetic != 0) s.add("synthetic ")
    if (flags & FConst.Virtual   != 0) s.add("virtual ")
    return s.toStr[0..-2]
  }

  Str index(Int index)
  {
    if (showIndex) return "[" + index + "]"
    return ""
  }

//////////////////////////////////////////////////////////////////////////
// Print
//////////////////////////////////////////////////////////////////////////

  FPrinter print(Obj obj) { out.print(obj); return this }
  FPrinter printLine(Obj obj := "") { out.printLine(obj); return this }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  FPod pod
  OutStream out
  Bool showIndex := false
  Bool showCode  := true
  Bool showLines := false

}
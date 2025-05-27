//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 2025  Brian Frank  Creation
//

using compiler

**
** Special handling for native classes and the sys pod itself.
**
** For native code we perform the following processing:
** - parse the Java file into parts to determine Java version of slots
** - insert the fandoc into the Java code
** - add javadoc for non-slots to indicate nodoc
** - create synthetic SAM interfaces for callback functions
**
** Additional special processing for sys pod:
** - hardcode the Sys.initIsJarDist to true
**
internal class JavaNativeGen
{
  new make(JavaCmd cmd)
  {
    this.outDir  = cmd.outDir
    this.compiler = cmd.compiler
  }

//////////////////////////////////////////////////////////////////////////
// Sys
//////////////////////////////////////////////////////////////////////////

  Void genSys(PodDef pod)
  {
    // start fresh
    outDir.plus(`fan/sys`).delete
    outDir.plus(`fanx/`).delete

    // copy sys Java native files
    copyNativeFiles(pod, compiler.input.baseDir+`java/fan/sys/`, outDir + `fan/sys/`)

    // copy select fanx.* packages
    JavaUtil.fanx.each |p| { copyPackage(p) }
  }

  Void copyPackage(Str packagePath)
  {
    echo("Copy package [$packagePath]")
    srcDir := compiler.input.baseDir
    dstDir := outDir + `$packagePath/`
    srcDir.plus(`java/${packagePath}/`).list.each |f|
    {
      if (f.ext == "java") f.copyInto(dstDir)
    }
  }

  Void copySysJava(File from, File to)
  {
    // hardcode to return true:
    //   private static boolean initIsJarDist()
    //   {
    //     return System.getProperty("fan.jardist", "false").equals("true");
    //   }
    lines := from.readAllLines
    sig := "private static boolean initIsJarDist()"
    i := lines.findIndex { it.trim == sig }
    if (i == null ||
        lines[i+1].trim != "{" ||
        !lines[i+2].trim.startsWith("return System.getProperty"))
       throw Err("$from.name missing: $sig")

    // hard code to return true
    lines[i+2] = "    return true; // hardcoded by fanc"

    str := lines.join("\n")
    to.out.print(str).close
  }

//////////////////////////////////////////////////////////////////////////
// Gen Pod
//////////////////////////////////////////////////////////////////////////

  Void genPod(PodDef pod)
  {
    srcDir := compiler.input.baseDir + `java/`
    if (!srcDir.exists) return

    // copy sys Java native files
    dstDir := JavaUtil.podDir(outDir, pod.name)
    copyNativeFiles(pod, srcDir, dstDir)
   }

//////////////////////////////////////////////////////////////////////////
// Natives
//////////////////////////////////////////////////////////////////////////

  Void copyNativeFiles(PodDef pod, File fromDir, File toDir)
  {
    toDir.create
    fromDir.list.each |from|
    {
      if (from.ext != "java") return

      to := toDir.plus(from.name.toUri)

      if (pod.name == "sys" && from.name == "Sys.java")
      {
        copySysJava(from, to)
        return
      }

      copyNativeFile(pod, from, to)
    }
  }

  Void copyNativeFile(PodDef pod, File from, File to)
  {
    // map file to type def in pod
    typeName := from.basename
    type := pod.typeDefs.get(typeName)

    // if not a type, then just do straight copy
    if (type == null)
    {
      from.copyTo(to)
      return
    }

    // parse parts
    parts := parseNativeParts(type, from)

    // generate parts
    buf := StrBuf()
    printNativeParts(buf, parts)

    // generate SAM version of methods
    genSamMethods(type, buf)

    // add back trailing slash
    buf.add("}\n\n")

    // write to output file
    to.open.print(buf.toStr).close
  }

//////////////////////////////////////////////////////////////////////////
// Parse Native Parts
//////////////////////////////////////////////////////////////////////////

  ** Parse type into slot parts; trailing slash is removed
  static JavaNativePart[] parseNativeParts(TypeDef type, File f)
  {
    // this code relies on convention of slot indentation of two spaces
    lines := f.readAllLines
    parts := JavaNativePart[,]
    start := 0
    for (i := 0; i<lines.size; ++i)
    {
      line := lines[i]

      // everthing up to opening brace
      if (line.startsWith("{"))
      {
        part := JavaNativePart(lines[start..i])
        parts.add(part)
        start = i+1
        continue
      }

      // skip lines if still in prelude
      if (parts.isEmpty) continue

      // check if slot declaration
      name := isNativeSlot(line)
      if (name == null) continue

      // add previous lines
      if (start < i)
      {
        part := JavaNativePart(lines[start..<i])
        parts.add(part)
        start = i
      }

      // find all the lines until ending {}
      next := lines[i+1]
      if (next.startsWith("  {"))
      {
        while (lines[i] != "  }")
        {
          ++i
          if (i >= lines.size) throw Err("Unexpected end of native code: $f.osPath")
        }
      }

      // slot part
      slot  := type.slotDef(name)
      arity := parseArity(line)
      part  := JavaNativePart(lines[start..i], name, slot, arity)
      checkSlot(f, line, slot)
      parts.add(part)
      start = i+1
    }

    // remove trailing "}" and then any empty lines
    last := lines[start..-1]
    while (last[-1].trim != "}") last.size = last.size -1
    last.size = last.size - 1
    while (!last.isEmpty && last[-1].trim.isEmpty) last.size = last.size -1

    // add last part
    parts.add(JavaNativePart(last))

    return parts
  }

  ** Return if a line of code maps to a slot name:
  **   "public final boolean bytesEqual(Buf that)" => "bytesEqual"
  static Str? isNativeSlot(Str line)
  {
    // only care about lines that start "sp sp non-sp"
    if (line.size < 5) return null
    if (line[0] != ' ' || line[1] != ' ' || line[2] == ' ') return null
    line = line.trim

    // skip privates, arrays
    if (line.startsWith("private ")) return null
    if (line.contains("[]")) return null

    // check for fields
    eq := line.index("=")
    if (eq != null)
    {
      sp := line.indexr(" ", eq-2)  ?: throw Err(line)
      name := line[sp+1..<eq].trim
      return name
    }

    // find start of params
    paren := line.index("(")
    if (paren != null)
    {
      sp := line.indexr(" ", paren)
      if (sp == null) return null
      name := line[sp+1..<paren]
      return name
    }

    return null
  }

  ** Given java method signature, parse the parameter arity
  static Int parseArity(Str line)
  {
    s := line.index("(")
    e := line.index(")")
    if (s == null) return 0
    params := line[s+1..<e]
    if  (params.trim.isEmpty) return 0
    toks := params.split(',')
    return toks.size
  }

  ** Check slot that if Fantom is parameterized then Java is too
  static Void checkSlot(File f, Str line, SlotDef? slot)
  {
    if (slot == null) return

    if (line.contains("make()")) return
    if (line.contains("(int ")) return

    hasGenerics := false
    if (slot is FieldDef)
    {
      field := (FieldDef)slot
      hasGenerics = isParameterizedListOrMap(field.type)
    }
    else
    {
      method := (MethodDef)slot
      hasGenerics = isParameterizedListOrMap(method.returns)
      method.params.each |p| { hasGenerics = hasGenerics || isParameterizedListOrMap(p.type) }
    }

    if (hasGenerics)
    {
      isJavaGeneric := line.contains("<") || line.contains("V ") || line.contains("K ")
      if (!isJavaGeneric) echo("WARN: '$f.name' generic fix: $line")
    }
  }

  ** Return if t is parameterized List or Map
  static Bool isParameterizedListOrMap(CType t)
  {
    if (!t.isParameterized) return false
    if (t.isFunc) return false
    t = t.deref.toNonNullable
    v := t.isList ? ((ListType)t).v : ((MapType)t).v
    if (v.isObj || v.toNonNullable.isObj) return false
    return true
  }

//////////////////////////////////////////////////////////////////////////
// Print Native Parts
//////////////////////////////////////////////////////////////////////////

  ** Print the parts and insert javadoc for slots
  static Void printNativeParts(StrBuf s, JavaNativePart[] parts)
  {
    JavaNativePart? last := null
    parts.each |part, i|
    {
      printNativePart(s, part, last != null && last.lastIsBlank)
      last = part
    }
  }

  ** Print the part and insert javadoc
  static Void printNativePart(StrBuf s, JavaNativePart part, Bool lastWasBlank)
  {
    if (part.name != null)
    {
      if (!lastWasBlank) s.add("\n")

      if (part.isNoDoc)
        s.add("  /** NoDoc */\n")
      else if (part.isConvenience)
        s.add("  /** Convenience for $part.slot.name */\n")
      else
        printJavaDoc(s, part.slot, 2)
    }

    part.lines.each |line| { s.add(line).add("\n") }
  }

  ** Print javadoc for given node
  static Void printJavaDoc(StrBuf s, DefNode n, Int indent)
  {
    indentStr := Str.spaces(indent)
    s.add(indentStr).add("/**\n")
    doc := n.docDef
    empty := doc == null || doc.lines.isEmpty || doc.lines.first.trim.isEmpty
    if (empty) s.add(indentStr).add(" * ").add(n).add("\n")
    else
    {
      doc.lines.each |line|
      {
        line = line.replace("/*", "/ *")
                   .replace("*/", "* /")
                   .replace("\\uxxxx", "\\u1234")
        s.add(indentStr).add(" * ").add(line).add("\n")
      }
    }
    s.add(indentStr).add(" */\n")
  }

//////////////////////////////////////////////////////////////////////////
// SAM
//////////////////////////////////////////////////////////////////////////

  ** For all fantom methods that declare a function parameter, generate
  ** a version of the method that takes a SAM (single abstract method) that
  ** be used with a Java closure for ergonomatics
  Void genSamMethods(TypeDef t, StrBuf s)
  {
    t.methodDefs.each |m|
    {
      if (m.isPrivate || m.isInternal) return
      if (m.params.isEmpty) return

      // check if last param is parameterized function
      p := m.params.last
      needSam := p.type.isFunc && p.type.isParameterized
      if (!needSam) return

      // generate SAM version(s)
      // TODO
      // genSamMethod(m, s)
    }
  }

  ** Generate SAM (single abstract method) for the given method
  Void genSamMethod(MethodDef m, StrBuf s)
  {
    funcType := (FuncType)m.params.last.type.toNonNullable

    if (funcType.params.isEmpty)
    {
      echo("WARN: Func with no params? $m")
      return
    }

    for (i := 0; i<funcType.params.size; ++i)
    {
      funcParams := funcType.params[0..i]
      JavaPrinter(s.out).indent.nl.samMethod(m, funcType, funcParams)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  File outDir
  Compiler compiler
}

**************************************************************************
** JavaNativePart
**************************************************************************

internal class JavaNativePart
{
  new make(Str[] lines, Str? name := null, SlotDef? slot := null, Int arity := 0)
  {
    this.lines = lines
    this.name  = name
    this.slot  = slot
    this.arity = arity
  }

  const Str? name    // slot name or null for non-slot section
  SlotDef? slot      // reflect slot
  Int arity          // method arity
  Str[] lines        // lines in this part

  Bool isNoDoc()
  {
    slot == null || slot.isNoDoc
  }

  Bool isConvenience()
  {
    slot is MethodDef && ((MethodDef)slot).params.size != arity
  }

  Bool lastIsBlank() { lines.last.trim.isEmpty }
}


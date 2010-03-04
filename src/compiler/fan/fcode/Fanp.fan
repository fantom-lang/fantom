//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jan 06  Brian Frank  Creation
//

**
** Fantom Disassembler
**
class Fanp
{

//////////////////////////////////////////////////////////////////////////
// Execute
//////////////////////////////////////////////////////////////////////////

  Void execute(Str target)
  {
    colon := target.index(":")
    dot   := target.index(".")
    if (colon  == null) printPod(Pod.find(target))
    else if (dot < 0) printType(Type.find(target))
    else printSlot(Slot.find(target))
  }

  Void executeFile(Str? target)
  {
    scriptFile := File.os(file)
    input := CompilerInput()
    {
      podName        = "script"
      summary        = "script"
      version        = Version("0")
      log.level      = LogLevel.warn
      includeDoc     = true
      isScript       = true
      srcStr         = scriptFile.readAllStr
      srcStrLoc      = Loc.makeFile(scriptFile)
      mode           = CompilerInputMode.str
      output         = CompilerOutputMode.transientPod
    }
    compiler = Compiler(input)
    compiler.compile

    pod := compiler.output.transientPod

    if (target == null)
    {
      printPod(pod)
      return
    }

    dot := target.index(".")
    if (dot < 0)
    {
      printType(pod.type(target))
    }
    else
    {
      typeName := target[0..<dot]
      slotName := target[dot+1..-1]
      printSlot(pod.type(typeName).slot(slotName))
    }
  }

  Void printPod(Pod pod)
  {
    p := printer(pod)
    if (showTables) { p.tables; return }
    p.ftypes
  }

  Void printType(Type t)
  {
    p := printer(t.pod)
    if (showTables) { p.tables; return }
    ftype := ftype(p.pod, t.name)
    p.ftype(ftype)
  }

  Void printSlot(Slot slot)
  {
    p := printer(slot.parent.pod)
    if (showTables) { p.tables; return }
    fslot := fslot(ftype(p.pod, slot.parent.name), slot.name)
    p.slot(fslot)
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  FPrinter printer(Pod pod)
  {
    printer := FPrinter(fpod(pod.name))
    printer.showCode  = showCode
    printer.showLines = showLines
    printer.showIndex = showIndex
    return printer
  }

  FPod fpod(Str podName)
  {
    if (file == null)
    {
      c := Compiler(CompilerInput()) // dummy compiler
      ns := FPodNamespace(c, null)
      FPod fpod := ns.resolvePod(podName, null)
      fpod.readFully
      return fpod
    }
    else
    {
      return compiler.fpod
    }
  }

  FType ftype(FPod pod, Str typeName)
  {
    ftype := pod.ftypes.find |FType ft->Bool|
    {
      r := pod.typeRef(ft.self)
      return typeName == pod.n(r.typeName)
    }
    if (ftype == null) throw UnknownTypeErr(pod.name + "::" + typeName)
    return ftype
  }

  FSlot fslot(FType ftype, Str slotName)
  {
    FSlot? slot := null

    slot = ftype.ffields.find |FSlot s->Bool|
    {
      return slotName == ftype.fpod.n(s.nameIndex)
    }
    if (slot != null) return slot

    slot = ftype.fmethods.find |FSlot s->Bool|
    {
      return slotName == ftype.fpod.n(s.nameIndex)
    }
    if (slot != null) return slot

    throw UnknownSlotErr(slotName)
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  Void run(Str[] args)
  {
    if (args.isEmpty) { help; return }

    Str? target := null

    // process args
    for (i:=0; i<args.size; ++i)
    {
      a := args[i]
      if (a.isEmpty) return
      if (a == "-help" || a == "-h" || a == "-?")
      {
        help
        return
      }
      else if (a == "-t") { showTables  = true }
      else if (a == "-c") { showCode    = true }
      else if (a == "-l") { showLines   = true }
      else if (a == "-i") { showIndex   = true }
      else if (a == "-f")
      {
        i += 1
        file = args[i]
      }
      else if (a[0] == '-')
      {
        echo("WARNING: Unknown option $a")
      }
      else
      {
        target = a
      }
    }

    if (target == null && file == null) { help; return }
    if (file == null) execute(target)
    else executeFile(target)
  }

  Void help()
  {
    echo("Fantom Disassembler");
    echo("Usage:");
    echo("  fanp [options] <pod>");
    echo("  fanp [options] <pod>::<type>");
    echo("  fanp [options] <pod>::<type>.<method>");
    echo("Options:");
    echo("  -help, -h, -?  print usage help");
    echo("  -t             print constant pool tables");
    echo("  -c             print code buffers");
    echo("  -l             print line number table");
    echo("  -i             print table indexes in code");
    echo("  -f <file>      disassemble from script file");
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  static Void main()
  {
    make.run(Env.cur.args)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Compiler? compiler
  Bool showTables := false
  Bool showCode   := false
  Bool showLines  := false
  Bool showIndex  := false
  Str? file

}
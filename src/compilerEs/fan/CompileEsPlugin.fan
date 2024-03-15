//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Apr 2023  Matthew Giannini Creation
//

using compiler

**
** Fantom source to JavaScript source compiler - this class is
** plugged into the compiler pipeline by the compiler::CompileJs step.
**
class CompileEsPlugin : CompilerStep
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Compiler c) : super(c)
  {
    this.sourcemap = SourceMap(this)
    this.js = JsWriter(buf.out, sourcemap)
    this.closureSupport = JsClosure(this)
    pod.depends.each |depend| { dependOnNames[depend.name] = true }
    readJsProps
  }

  private StrBuf buf := StrBuf()
  SourceMap sourcemap { private set }
  JsWriter js { private set }
  private [Str:Str] usingAs := [:]

//////////////////////////////////////////////////////////////////////////
// Emit State
//////////////////////////////////////////////////////////////////////////

  ** The variable name that refers to "this" in the current method context
  Str thisName := "this"

  ** next unique id
  private Int uid := 0
  Int nextUid() { uid++; }

  [Str:Bool] dependOnNames := [:] { def = false }

  JsClosure closureSupport { private set }

//////////////////////////////////////////////////////////////////////////
// js.props
//////////////////////////////////////////////////////////////////////////

  private Void readJsProps()
  {
    if (compiler.input.baseDir == null) return
    f := compiler.input.baseDir.plus(`js.props`)
    if (!f.exists) return
    f.readProps.each |val, key|
    {
      if (key.startsWith("using."))
        this.usingAs[key["using.".size..-1]] = val
    }
  }

  ** Get the alias for this pod if one was defined in js.props, otherwise
  ** return the pod name.
  Str podAlias(Str podName) { usingAs.get(podName, podName) }

//////////////////////////////////////////////////////////////////////////
// Pipeline
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    if (pod.name.contains("fwt")) return

    // generate CommonJs and ESM module
    JsPod(this).write
    compiler.cjs = buf.toStr
// echo(buf.toStr)
    compiler.esm = toEsm(compiler.cjs)

    // write out the sourcemap (note: the same sourcemap works
    // with CommonJs and ESM because toEsm preserves the line numbering)
    buf.clear
    sourcemap.write(js.line, buf.out)
    compiler.cjsSourceMap = buf.toStr
  }

//////////////////////////////////////////////////////////////////////////
// ESM
//////////////////////////////////////////////////////////////////////////

  ** Converts CommonJs emitted code to ESM
  private Str toEsm(Str cjs)
  {
    buf       := StrBuf()
    lines     := cjs.splitLines
    inRequire := false
    inExport  := false
    i := 0
    while (true)
    {
      line := lines[i++]
      buf.add("${line}\n")
      if (line.startsWith("// cjs require begin")) i = requireToImport(buf, lines, i)
      else if (line.startsWith("// cjs exports begin"))
      {
        // we assume this is the very last thing in the file and stop once
        // we convert to ESM export statement
        toExports(buf, lines, i)
        break
      }
    }
    return buf.toStr
  }

  private Int requireToImport(StrBuf buf, Str[] lines, Int i)
  {
    // this regex matches statements that require a pod in the cjs
    // and creates a group for the pod name/alias (1) and the file name (2).
    regex := Regex<|^const ([^_].*)? =.*__require\('(.*)?.js'\);|>

    while (true)
    {
      line := lines[i++]
      m := regex.matcher(line)
      if (m.matches)
      {
        pod := m.group(1)
        if (pod == "fantom") { buf.addChar('\n'); continue; }
        file := m.group(2)
        // buf.add("const ${pod} = await (async function () { try { return await import('./${file}.js'); } catch(err) { /* ignore */ } })();\n")
        buf.add("import * as ${pod} from './${file}.js'\n")
      }
      else if (line.startsWith("// cjs require end")) { buf.add("${line}\n"); break }
      else buf.addChar('\n')
    }
    return i
  }

  private Int toExports(StrBuf buf, Str[] lines, Int i)
  {
    // skip: const <pod> = {
    line := lines[i++]

    buf.add("export {\n")
    while(true)
    {
      line = lines[i++]
      buf.add("${line}\n")
      if (line == "};") break
    }
    while (!(line = lines[i++]).startsWith("// cjs exports end")) continue;

    return i
  }
}